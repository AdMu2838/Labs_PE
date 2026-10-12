// Aprovisionamiento explícito de cuentas persistentes de prueba.
// Las contraseñas se generan en memoria; no se incluyen en el repositorio.
async (page) => {
  if (!page.__labServiceKey || !page.__labAdminHeaders) throw new Error('Requiere sesión administrativa autorizada');
  if (page.__roleTests) throw new Error('Las cuentas ya fueron aprovisionadas en esta sesión');
  const base = 'https://spduupvhofygzkcmqmiz.supabase.co';
  const state = page.__roleTests = { base, users: {}, checks: [], fixtures: {} };
  const q = value => `'${String(value).replaceAll("'", "''")}'`;
  state.sql = async query => {
    const response = await page.request.post(page.__labQueryEndpoint, { headers: page.__labAdminHeaders, data: { query } });
    const result = await response.json();
    if (!response.ok()) throw new Error(`SQL: ${JSON.stringify(result)}`);
    return result;
  };
  state.api = async (role, table, method = 'GET', body) => {
    const user = state.users[role];
    const send = () => page.request.fetch(`${base}/rest/v1/${table}`, {
      method,
      headers: { apikey: page.__labPublicKey, authorization: `Bearer ${user.token}`, 'content-type': 'application/json', Prefer: 'return=representation' },
      ...(body !== undefined ? { data: body } : {}),
    });
    let response = await send();
    if (response.status() === 401) {
      const login = await page.request.post(`${base}/auth/v1/token?grant_type=password`, {
        headers: { apikey: page.__labPublicKey, 'content-type': 'application/json' }, data: { email: user.email, password: user.password },
      });
      if (!login.ok()) throw new Error(`No se pudo renovar la sesión de ${role}`);
      user.token = (await login.json()).access_token;
      response = await send();
    }
    const text = await response.text();
    return { ok: response.ok(), status: response.status(), data: text ? JSON.parse(text) : null };
  };
  const headers = { apikey: page.__labServiceKey, authorization: `Bearer ${page.__labServiceKey}`, 'content-type': 'application/json' };
  const specs = [
    { role: 'student', email: 'estudiante.lab04@example.com', name: 'Estudiante de prueba LAB04', cui: '99004001' },
    { role: 'teacher', email: 'docente.lab04@example.com', name: 'Docente de prueba LAB04' },
    { role: 'admin', email: 'admin.lab04@example.com', name: 'Administrador de prueba LAB04' },
  ];
  for (const spec of specs) {
    const password = await page.evaluate(() => `Lab04-${crypto.randomUUID().replaceAll('-', '').slice(0, 12)}-Aa9!`);
    const response = await page.request.post(`${base}/auth/v1/admin/users`, {
      headers,
      data: { email: spec.email, password, email_confirm: true, user_metadata: { full_name: spec.name, ...(spec.cui ? { cui: spec.cui } : {}) } },
    });
    const result = await response.json();
    if (!response.ok()) throw new Error(`Crear ${spec.role}: ${result.msg ?? result.message}`);
    state.users[spec.role] = { ...spec, id: result.id, password };
    await state.sql(`update public.profiles set role=${q(spec.role)} where id=${q(result.id)};`);
    const login = await page.request.post(`${base}/auth/v1/token?grant_type=password`, {
      headers: { apikey: page.__labPublicKey, 'content-type': 'application/json' }, data: { email: spec.email, password },
    });
    const session = await login.json();
    if (!login.ok()) throw new Error(`No se pudo iniciar sesión como ${spec.role}`);
    state.users[spec.role].token = session.access_token;
    const profile = await state.api(spec.role, `profiles?id=eq.${result.id}&select=id,role,active,cui`);
    if (!profile.ok || profile.data[0]?.role !== spec.role || !profile.data[0].active) throw new Error(`Perfil incorrecto para ${spec.role}`);
    state.checks.push(`Cuenta persistente ${spec.role}: correo confirmado, perfil y login verificados`);
  }
  return { created: Object.values(state.users).map(({ email, role, cui }) => ({ email, role, cui })), persistent: true, confirmed: true };
}
