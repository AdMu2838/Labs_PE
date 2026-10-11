// Ejecutar tras fixtures.sql en un contenedor PostgreSQL de pruebas.
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
import assert from 'node:assert/strict';
const exec = promisify(execFile);
const container = process.argv[2] ?? 'unsa-lab-db-test';
async function query(sql) {
  return exec('docker', ['exec', container, 'psql', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-At', '-c', sql]);
}
const calls = ['2', '3'].map(suffix => query(`begin; set local role authenticated; select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-${suffix.padStart(12, '0')}',true); select public.enroll_lab('40000000-0000-4000-8000-000000000001'); select pg_sleep(0.5); commit;`));
const outcomes = await Promise.allSettled(calls);
assert.equal(outcomes.filter(r => r.status === 'fulfilled').length, 1, 'Exactamente un estudiante obtiene la última vacante');
const count = await query("select count(*) from public.enrollments where status='active' and group_id='40000000-0000-4000-8000-000000000001'");
assert.equal(count.stdout.trim(), '1');
console.log('OK: matrícula concurrente sin sobrecupo.');
