// E2E sobre Flutter Web real con tres contextos de navegador y Supabase real.
// Requiere cuentas explícitamente aprovisionadas; no almacena sus contraseñas.
async (page) => {
  const state = page.__roleTests;
  if (!state) throw new Error('Primero aprovisiona las cuentas persistentes');
  const browser = page.context().browser();
  state.apps = {};
  state.contexts = [];
  state.uiErrors = [];
  const check = (condition, label) => {
    if (!condition) throw new Error(`FALLÓ: ${label}`);
    state.checks.push(label);
  };
  state.check = check;
  state.waitRecord = async (role, table, predicate) => {
    for (let attempt = 0; attempt < 40; attempt++) {
      const result = await state.api(role, table);
      if (result.ok && predicate(result.data)) return result;
      await new Promise(resolve => setTimeout(resolve, 250));
    }
    throw new Error(`No se confirmó la persistencia en ${table}`);
  };
  const semantics = async app => {
    await app.locator('flt-semantics-placeholder').waitFor({ state: 'attached', timeout: 30000 });
    await app.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  };
  const go = async (app, path, expected) => {
    await app.goto(`http://127.0.0.1:8080${path}`);
    await semantics(app);
    await app.getByText(expected, { exact: false }).first().waitFor({ timeout: 30000 });
  };
  state.go = go;
  const input = async (app, label, value) => {
    const locator = app.getByRole('textbox', { name: label, exact: true });
    await locator.click();
    await locator.press('ControlOrMeta+A');
    await locator.press('Backspace');
    await locator.pressSequentially(value, { delay: 12 });
    await locator.press('Tab');
  };
  state.input = input;
  const select = async (app, label, option) => {
    await app.getByRole('button', { name: new RegExp(label) }).last().click();
    for (let step = 0; step < 20; step++) {
      const item = app.getByRole('menuitem', { name: option, exact: true });
      if (await item.count()) { await item.scrollIntoViewIfNeeded(); await item.click(); return; }
      await app.getByRole('menu').hover();
      await app.mouse.wheel(0, 500);
      await app.waitForTimeout(150);
    }
    throw new Error(`No se encontró la opción ${option}`);
  };
  state.select = select;
  for (const role of ['admin', 'student', 'teacher']) {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'es-PE', timezoneId: 'America/Lima', acceptDownloads: true });
    state.contexts.push(context);
    const app = await context.newPage();
    app.on('pageerror', error => state.uiErrors.push(`${role}: ${error.message}`));
    app.on('console', message => { if (/RenderFlex overflowed|RenderBox was not laid out/.test(message.text())) state.uiErrors.push(`${role}: ${message.text()}`); });
    state.apps[role] = app;
    await go(app, '/login', 'Ingresar a la plataforma');
    await input(app, 'Correo electrónico', state.users[role].email);
    await input(app, 'Contraseña', state.users[role].password);
    await app.getByRole('button', { name: 'Ingresar a la plataforma', exact: true }).click();
    await app.getByText('Hola,', { exact: false }).waitFor({ timeout: 30000 });
    check(app.url().endsWith('/'), `UI ${role}: login por contraseña y dashboard`);
  }
  const admin = state.apps.admin;
  await go(admin, '/admin', 'Configura la oferta académica');
  await admin.getByRole('button', { name: 'Crear registro', exact: true }).click();
  await input(admin, 'Periodo (ej. 2026-B)', 'LAB04 - PRUEBAS');
  await select(admin, 'Estado', 'open');
  await input(admin, 'Inicio de matrícula', '2026-10-10 08:00');
  await input(admin, 'Fin de matrícula', '2027-01-10 23:59');
  await input(admin, 'Fin de cambios y retiros', '2027-01-20 23:59');
  await admin.getByRole('button', { name: 'Guardar', exact: true }).click();
  await admin.getByRole('button', { name: 'Guardar', exact: true }).waitFor({ state: 'hidden', timeout: 30000 });
  const periods = await state.waitRecord('admin', `periods?name=eq.${encodeURIComponent('LAB04 - PRUEBAS')}&select=id,name,status`, rows => rows.length === 1);
  check(periods.ok && periods.data.length === 1 && periods.data[0].status === 'open', 'UI administrador: crear periodo y persistirlo en Supabase');
  state.fixtures.period = periods.data[0].id;
  return { passed: state.checks.length, checks: state.checks, uiErrors: state.uiErrors, periodCreatedViaUI: true };
}
