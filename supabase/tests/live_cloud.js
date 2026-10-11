// Ejecutar desde el navegador autenticado, nunca desde Flutter.
// Las credenciales administrativas y contraseñas quedan solo en memoria de la sesión de prueba.
async (page) => {
  const base = 'https://spduupvhofygzkcmqmiz.supabase.co';
  if (!page.__labServiceKey || !page.__labAdminHeaders || !page.__labPublicKey) throw new Error('Falta una sesión de prueba autorizada');
  const previous = page.__labTest;
  if (previous?.checks.length) throw new Error('Limpia la ejecución anterior antes de repetir las pruebas');
  const prefix = previous?.prefix ?? `labcheck-${Date.now()}`;
  const password = previous?.password ?? await page.evaluate(() => `${crypto.randomUUID()}Aa9!`);
  const state = page.__labTest = previous ?? { prefix, password, users: {}, checks: [], ids: {} };
  const assert = (condition, label) => {
    if (!condition) throw new Error(`FALLÓ: ${label}`);
    state.checks.push(label);
  };
  const adminHeaders = { apikey: page.__labServiceKey, authorization: `Bearer ${page.__labServiceKey}`, 'content-type': 'application/json' };
  const sql = async query => {
    const response = await page.request.post(page.__labQueryEndpoint, {
      headers: page.__labAdminHeaders, data: { query },
    });
    const data = await response.json();
    if (!response.ok()) throw new Error(`SQL ${response.status()}: ${JSON.stringify(data)}`);
    return data;
  };
  const q = v => `'${String(v).replaceAll("'", "''")}'`;
  const api = async (user, path, method = 'GET', body) => {
    const response = await page.request.fetch(`${base}/rest/v1/${path}`, {
      method,
      headers: { apikey: page.__labPublicKey, authorization: `Bearer ${user.token}`, 'content-type': 'application/json', Prefer: 'return=representation' },
      ...(body !== undefined ? { data: body } : {}),
    });
    const text = await response.text();
    return { ok: response.ok(), status: response.status(), data: text ? JSON.parse(text) : null };
  };
  state.api = api;
  state.sql = sql;
  state.q = q;
  for (const kind of ['admin', 'one', 'two', 'teacher']) {
    if (state.users[kind]) continue;
    const email = `${prefix}-${kind}@example.com`;
    const metadata = { full_name: `PRUEBA TEMPORAL ${kind}`, cui: ({ admin: '99000001', one: '99000002', two: '99000003', teacher: '99000004' })[kind], role: 'admin' };
    const response = await page.request.post(`${base}/auth/v1/admin/users`, {
      headers: adminHeaders, data: { email, password, email_confirm: true, user_metadata: metadata },
    });
    const user = await response.json();
    if (!response.ok()) throw new Error(`Crear usuario ${kind}: ${user.msg ?? user.message}`);
    state.users[kind] = { id: user.id, email };
  }
  const u = state.users;
  const profiles = await sql(`select id,role,plan_id from public.profiles where id in (${Object.values(u).map(v => q(v.id)).join(',')});`);
  assert(profiles.length === 4 && profiles.every(p => p.role === 'student' && p.plan_id), 'Registro crea perfil estudiantil y no acepta roles del cliente');
  await sql(`update public.profiles set role='admin' where id=${q(u.admin.id)}; update public.profiles set role='teacher' where id=${q(u.teacher.id)};`);
  for (const [kind, user] of Object.entries(u)) {
    const login = await page.request.post(`${base}/auth/v1/token?grant_type=password`, {
      headers: { apikey: page.__labPublicKey, 'content-type': 'application/json' }, data: { email: user.email, password },
    });
    const session = await login.json();
    assert(login.ok() && !!session.access_token, `Login real: ${kind}`);
    user.token = session.access_token;
    user.refreshToken = session.refresh_token;
    user.authUser = session.user;
  }
  const initial = await api(u.one, 'courses?select=id,code,credits');
  assert(initial.ok && initial.data.length === 87, 'Catálogo oficial accesible: 87 asignaturas');
  const ids = state.ids;
  ids.course = initial.data.find(c => c.code === '2501103').id;
  ids.webCourse = initial.data.find(c => c.code === '2501210').id;
  const own = await api(u.one, 'profiles?select=id,role');
  assert(own.ok && own.data.length === 1 && own.data[0].id === u.one.id, 'RLS de perfiles: estudiante solo consulta su perfil');
  const escalation = await api(u.one, 'rpc/set_user_role', 'POST', { p_user: u.one.id, p_role: 'admin' });
  assert(!escalation.ok, 'Escalamiento a administrador bloqueado');
  const create = async (table, body) => {
    const result = await api(u.admin, table, 'POST', body);
    if (!result.ok) throw new Error(`Crear ${table}: ${JSON.stringify(result.data)}`);
    return result.data[0].id;
  };
  ids.period = await create('periods', { name: prefix, status: 'open', require_eligibility: true,
    enrollment_start: new Date(Date.now() - 86400000).toISOString(), enrollment_end: new Date(Date.now() + 86400000).toISOString(), withdrawal_end: new Date(Date.now() + 172800000).toISOString() });
  ids.roomA = await create('rooms', { name: `${prefix}-A`, location: 'PRUEBA TEMPORAL', capacity: 3 });
  ids.roomB = await create('rooms', { name: `${prefix}-B`, location: 'PRUEBA TEMPORAL', capacity: 3 });
  ids.groupA = await create('groups', { name: 'PRUEBA A', course_id: ids.course, period_id: ids.period, room_id: ids.roomA, teacher_id: u.teacher.id, capacity: 1 });
  ids.groupB = await create('groups', { name: 'PRUEBA B', course_id: ids.course, period_id: ids.period, room_id: ids.roomB, teacher_id: u.teacher.id, capacity: 1 });
  ids.groupCross = await create('groups', { name: 'PRUEBA CRUCE', course_id: ids.webCourse, period_id: ids.period, room_id: ids.roomB, capacity: 2 });
  await create('sessions', { group_id: ids.groupA, day: 1, start_time: '08:00', end_time: '10:00' });
  await create('sessions', { group_id: ids.groupB, day: 2, start_time: '08:00', end_time: '10:00' });
  await create('sessions', { group_id: ids.groupCross, day: 1, start_time: '09:00', end_time: '11:00' });
  assert(true, 'CRUD administrativo: periodos, ambientes, grupos y sesiones');
  const collision = await api(u.admin, 'sessions', 'POST', { group_id: ids.groupB, day: 1, start_time: '08:30', end_time: '09:30' });
  assert(!collision.ok && collision.data.message.includes('cruce'), 'Cruces de docente/ambiente bloqueados');
  const rpc = (user, name, body) => api(user, `rpc/${name}`, 'POST', body);
  state.rpc = rpc;
  const disabled = await rpc(u.one, 'enroll_lab', { p_group: ids.groupA });
  assert(!disabled.ok && disabled.data.message.includes('habilitado'), 'Matrícula exige habilitación académica');
  const imported = await rpc(u.admin, 'import_academic', { p_kind: 'eligibilities', p_rows: ['one', 'two'].map(k => ({ cui: ({ one: '99000002', two: '99000003' })[k], course_code: '2501103', period_name: prefix })) });
  assert(imported.ok, 'Importación de habilitaciones por API');
  const direct = await api(u.one, 'enrollments', 'POST', { student_id: u.one.id, group_id: ids.groupA, course_id: ids.course, period_id: ids.period });
  assert(!direct.ok, 'Escritura directa de matrícula bloqueada');
  const contenders = await Promise.all(['one', 'two'].map(k => rpc(u[k], 'enroll_lab', { p_group: ids.groupA })));
  assert(contenders.filter(r => r.ok).length === 1 && contenders.filter(r => !r.ok).length === 1, 'Concurrencia real: una sola matrícula para la última vacante');
  state.winner = contenders[0].ok ? 'one' : 'two';
  state.other = state.winner === 'one' ? 'two' : 'one';
  const winner = u[state.winner], other = u[state.other];
  let winnerRows = await api(winner, 'enrollments?select=id,status,group_id');
  ids.origin = winnerRows.data.find(e => e.status === 'active').id;
  const duplicate = await rpc(winner, 'enroll_lab', { p_group: ids.groupA });
  assert(!duplicate.ok && duplicate.data.message.includes('Ya tienes'), 'Matrícula duplicada bloqueada');
  const waiting = await rpc(other, 'enroll_lab', { p_group: ids.groupA, p_waitlist: true });
  assert(waiting.ok && waiting.data === 'waiting', 'Registro real en lista de espera');
  const unprivileged = await rpc(other, 'withdraw_lab', { p_enrollment: ids.origin });
  assert(!unprivileged.ok, 'No se permite retirar la matrícula de otro estudiante');
  const otherB = await rpc(other, 'enroll_lab', { p_group: ids.groupB });
  assert(otherB.ok, 'Matrícula en grupo alternativo');
  const cancelledQueue = await api(other, 'waitlist?select=status');
  assert(cancelledQueue.ok && cancelledQueue.data.every(w => w.status !== 'waiting'), 'Confirmar otro grupo cancela la espera del mismo curso');
  const failedChange = await rpc(winner, 'enroll_lab', { p_group: ids.groupB, p_replacing: ids.origin });
  winnerRows = await api(winner, 'enrollments?select=id,status');
  assert(!failedChange.ok && winnerRows.data.some(e => e.id === ids.origin && e.status === 'active'), 'Cambio fallido conserva matrícula original');
  const otherRows = await api(other, 'enrollments?select=id,status');
  await rpc(other, 'withdraw_lab', { p_enrollment: otherRows.data.find(e => e.status === 'active').id });
  const queuedAgain = await rpc(other, 'enroll_lab', { p_group: ids.groupA, p_waitlist: true });
  assert(queuedAgain.ok && queuedAgain.data === 'waiting', 'Reingreso en lista de espera después del retiro');
  const changed = await rpc(winner, 'enroll_lab', { p_group: ids.groupB, p_replacing: ids.origin });
  assert(changed.ok && changed.data === 'enrolled', 'Cambio atómico de grupo exitoso');
  const promoted = await api(other, 'enrollments?select=id,status,group_id');
  assert(promoted.data.some(e => e.group_id === ids.groupA && e.status === 'active'), 'Promoción automática de la lista de espera');
  await rpc(u.admin, 'import_academic', { p_kind: 'eligibilities', p_rows: [{ cui: state.other === 'one' ? '99000002' : '99000003', course_code: '2501210', period_name: prefix }] });
  const unmet = await rpc(other, 'enroll_lab', { p_group: ids.groupCross });
  assert(!unmet.ok && unmet.data.message.includes('prerrequisitos'), 'Prerrequisitos académicos verificados');
  const history = await rpc(u.admin, 'import_academic', { p_kind: 'academic_records', p_rows: [{ cui: state.other === 'one' ? '99000002' : '99000003', course_code: '2501103', grade: '16' }] });
  assert(history.ok, 'Importación real de historial académico');
  const conflict = await rpc(other, 'enroll_lab', { p_group: ids.groupCross });
  assert(!conflict.ok && conflict.data.message.includes('se cruza'), 'Cruce de horario del estudiante bloqueado');
  const requestId = (await api(other, 'requests', 'POST', { type: 'other', subject: 'PRUEBA TEMPORAL', body: 'Validación de atención de solicitudes' })).data[0].id;
  ids.request = requestId;
  const resolution = await rpc(u.admin, 'resolve_request', { p_id: requestId, p_status: 'resolved', p_response: 'Prueba atendida correctamente' });
  assert(resolution.ok, 'Solicitud y respuesta administrativa');
  const teacherGroups = await api(u.teacher, 'enrollments?select=id,student_id');
  assert(teacherGroups.ok && teacherGroups.data.filter(e => e.student_id === u.one.id || e.student_id === u.two.id).length >= 2, 'Docente consulta matrículas de grupos asignados');
  const notice = await api(u.teacher, 'announcements', 'POST', { group_id: ids.groupA, title: 'PRUEBA TEMPORAL', body: 'Aviso de docente' });
  assert(notice.ok, 'Docente publica aviso a su grupo');
  ids.notice = notice.data[0].id;
  const messages = await api(other, 'notifications?select=id,title,is_read');
  assert(messages.ok && messages.data.length > 0, 'Notificaciones de matrícula, cola y solicitudes');
  const marked = await api(other, `notifications?id=eq.${messages.data[0].id}`, 'PATCH', { is_read: true });
  assert(marked.ok && marked.data[0].is_read, 'Marcar notificación como leída');
  const audit = await api(u.admin, 'audit_logs?select=id&limit=1');
  assert(audit.ok && audit.data.length === 1, 'Auditoría accesible para administración');
  const blockedAudit = await api(other, 'audit_logs?select=id&limit=1');
  assert(blockedAudit.ok && blockedAudit.data.length === 0, 'Auditoría oculta para estudiantes');
  const badLogin = await page.request.post(`${base}/auth/v1/token?grant_type=password`, {
    headers: { apikey: page.__labPublicKey, 'content-type': 'application/json' }, data: { email: other.email, password: 'incorrecta' },
  });
  assert(!badLogin.ok(), 'Contraseña incorrecta rechazada');
  return { project: 'spduupvhofygzkcmqmiz', prefix, passed: state.checks.length, checks: state.checks, temporaryUsers: Object.values(u).map(v => v.id) };
}
