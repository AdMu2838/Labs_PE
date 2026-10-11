// Diagnóstico sin revelar claves ni modificar datos.
import { readFile } from 'node:fs/promises';

const config = JSON.parse(await readFile(new URL('../config.json', import.meta.url), 'utf8'));
const base = config.SUPABASE_URL?.replace(/\/$/, '');
const key = config.SUPABASE_PUBLISHABLE_KEY;
if (!base || !key) throw new Error('Falta la URL o la clave pública en config.json.');
const headers = { apikey: key, 'Content-Type': 'application/json' };
const settingsResponse = await fetch(`${base}/auth/v1/settings`, { headers });
const settings = await settingsResponse.json();
console.log('Proyecto:', new URL(base).hostname);
console.log('Conexión Auth:', settingsResponse.status);
if (!settingsResponse.ok) {
  console.log('La URL o la clave no permiten acceder a Auth.');
  process.exitCode = 1;
} else {
  console.log('Email habilitado:', settings.external?.email ?? 'No informado');
  console.log('Google habilitado:', settings.external?.google ?? false);
  console.log('Confirmación de correo requerida:', settings.mailer_autoconfirm === false);
  console.log('Registro público habilitado:', settings.disable_signup === false);
  let missing = false;
  for (const table of ['profiles', 'plans', 'courses', 'groups', 'enrollments']) {
    const response = await fetch(`${base}/rest/v1/${table}?select=id&limit=0`, { headers });
    const data = await response.json();
    const absent = response.status === 404 && ['PGRST205', '42P01'].includes(data.code);
    const protectedTable = [401, 403].includes(response.status) && data.code === '42501';
    console.log(`${table}:`, absent ? 'Falta la tabla/migración' : protectedTable ? 'Existe; acceso anónimo bloqueado' : `HTTP ${response.status} (${data.code ?? 'respuesta disponible'})`);
    missing ||= absent;
  }
  if (missing) process.exitCode = 2;
}
