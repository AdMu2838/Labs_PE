// Variables públicas para el build; se toman del entorno de Vercel.
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

const url = (process.env.SUPABASE_URL ?? '').trim().replace(/\/$/, '');
const key = (process.env.SUPABASE_PUBLISHABLE_KEY ?? '').trim();
let parsed;
try {
  parsed = new URL(url);
} catch {
  throw new Error('Configura SUPABASE_URL en las variables del proyecto Vercel.');
}
if (parsed.protocol !== 'https:' || parsed.username || parsed.password) {
  throw new Error('SUPABASE_URL debe ser una URL HTTPS válida.');
}
if (!key) throw new Error('Configura SUPABASE_PUBLISHABLE_KEY en Vercel.');
if (key.startsWith('sb_secret_')) throw new Error('Flutter requiere la clave pública de Supabase, no una secret key.');
if (key.split('.').length === 3) {
  let claims;
  try {
    claims = JSON.parse(Buffer.from(key.split('.')[1], 'base64url').toString('utf8'));
  } catch {
    throw new Error('La clave JWT de Supabase no es válida.');
  }
  if (claims.role !== 'anon') throw new Error('Utiliza la clave anon pública, nunca service_role.');
} else if (!key.startsWith('sb_publishable_')) {
  throw new Error('Utiliza una publishable key o la clave anon antigua de Supabase.');
}
const output = resolve(process.argv[2] ?? '.dart_tool/vercel_build_config.json');
await mkdir(dirname(output), { recursive: true });
await writeFile(output, JSON.stringify({ SUPABASE_URL: url, SUPABASE_PUBLISHABLE_KEY: key }), 'utf8');
console.log('Configuración pública de Flutter preparada; valores omitidos del log.');
