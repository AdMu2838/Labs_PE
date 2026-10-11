$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$supabase = Join-Path $root 'supabase'
if (-not (Test-Path -LiteralPath $supabase)) { throw 'No se encuentra supabase/' }
$name = 'unsa-lab-tests-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
try {
    & docker run --rm -d --name $name -e POSTGRES_PASSWORD=local-test-only --mount "type=bind,source=$supabase,target=/workspace,readonly" postgres:17 -c wal_level=logical
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo iniciar PostgreSQL. Verifica Docker.' }
    $ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        & docker exec $name pg_isready -U postgres
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw 'PostgreSQL no inició a tiempo' }
    & docker exec $name psql -U postgres -v ON_ERROR_STOP=1 -f /workspace/tests/bootstrap.sql -f /workspace/migrations/001_schema.sql -f /workspace/migrations/002_operations.sql -f /workspace/migrations/003_curriculum_2025.sql -f /workspace/migrations/004_google_onboarding.sql -f /workspace/tests/fixtures.sql -f /workspace/tests/operations.sql
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas SQL' }
    & node (Join-Path $supabase 'tests\concurrency.mjs') $name
    if ($LASTEXITCODE -ne 0) { throw 'Falló la prueba de concurrencia' }
    'OK: migraciones, RLS, requisitos, cruces, cambios, cola y concurrencia.'
} finally {
    & docker stop $name
}
