// Comprueba variables de compilación y prioridad de archivos/rutas SPA.
import assert from 'node:assert/strict';
import { readFile, mkdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';

const config = JSON.parse(await readFile('vercel.json', 'utf8'));
assert.equal(config.framework, null);
assert.equal(config.buildCommand, 'bash tool/build_vercel.sh');
assert.equal(config.outputDirectory, 'build/web');
assert.notEqual(config.git?.deploymentEnabled, false);
assert.equal(config.routes[1].handle, 'filesystem');
assert.equal(config.routes.at(-1).dest, '/index.html');

const launch = new RegExp(`^${config.routes[0].src}`);
for (const path of ['/', '/index.html', '/main.dart.js', '/flutter_bootstrap.js']) assert(launch.test(path));
assert(!launch.test('/assets/fonts/MaterialIcons-Regular.otf'));
for (const path of ['/login', '/admin', '/catalog', '/password']) assert(new RegExp(config.routes.at(-1).src).test(path));

const directory = resolve('.dart_tool/vercel_validation');
await mkdir(directory, { recursive: true });
const output = resolve(directory, 'config.json');
const sampleURL = 'https://test-project.supabase.co';
const sampleKey = 'sb_publishable_example_for_validation';
const run = (url, key) => spawnSync(process.execPath, ['tool/write_build_config.mjs', output], {
  env: { ...process.env, SUPABASE_URL: url, SUPABASE_PUBLISHABLE_KEY: key }, encoding: 'utf8',
});
const valid = run(sampleURL, sampleKey);
assert.equal(valid.status, 0);
assert(!valid.stdout.includes(sampleKey));
assert.deepEqual(JSON.parse(await readFile(output, 'utf8')), { SUPABASE_URL: sampleURL, SUPABASE_PUBLISHABLE_KEY: sampleKey });
assert.notEqual(run('', sampleKey).status, 0);
assert.notEqual(run(sampleURL, '').status, 0);
assert.notEqual(run('http://test-project.supabase.co', sampleKey).status, 0);
assert.notEqual(run(sampleURL, 'sb_secret_do_not_embed').status, 0);
const jwt = role => `${Buffer.from('{}').toString('base64url')}.${Buffer.from(JSON.stringify({ role })).toString('base64url')}.signature`;
assert.notEqual(run(sampleURL, jwt('service_role')).status, 0);
assert.equal(run(sampleURL, jwt('anon')).status, 0);

console.log('OK: configuración nativa Vercel, fallback SPA, variables públicas y rechazo de claves privilegiadas.');
