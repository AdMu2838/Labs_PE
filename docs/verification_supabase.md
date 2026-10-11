# Verificación del proyecto Supabase

Fecha: 11 de octubre de 2026.

Proyecto: **MatriculasLab**, referencia `spduupvhofygzkcmqmiz`.

## Migraciones aplicadas

Aplicadas en la base remota y registradas en `supabase_migrations.schema_migrations`:

| Versión | Archivo | Resultado |
|---|---|---|
| 001 | `001_schema.sql` | Tablas, permisos, triggers y RLS creados |
| 002 | `002_operations.sql` | Funciones de matrícula y Realtime creados |
| 003 | `003_curriculum_2025.sql` | Plan oficial 2025 cargado |
| 004 | `004_google_onboarding.sql` | Alta sin CUI y asignación única del CUI |

Verificación de carga: **87 asignaturas, 72 relaciones de prerrequisito, 302 créditos codificados y 16 tablas de la aplicación con RLS**.

## Pruebas contra Supabase real

Se completaron **44 comprobaciones positivas** usando cuentas y datos temporales, incluyendo:

- Login por contraseña de administrador, docente y dos estudiantes.
- Alta automática del perfil con rol estudiante, ignorando roles enviados en metadatos del cliente.
- Acceso al catálogo oficial y restricciones RLS de perfiles y matrículas.
- Bloqueo de escalamiento de rol, escritura directa de matrícula y retiro de matrículas ajenas.
- CRUD de periodos, ambientes, grupos y sesiones.
- Validación de cruces de docente, ambiente y estudiante.
- Habilitación académica, prerrequisitos y carga del historial.
- Dos solicitudes concurrentes a la última vacante: solo una obtuvo la matrícula.
- Duplicados, lista de espera, cancelación al obtener otro grupo y promoción automática.
- Cambio exitoso de grupo y conservación del origen ante un cambio fallido.
- Solicitudes, respuestas, avisos docentes, notificaciones y auditoría.
- Cuenta sin CUI: bloqueo de matrícula, asignación inicial y rechazo de cambios posteriores no autorizados.
- Flutter Web conectado: login, dashboard, administración y catálogo con datos remotos.
- Descarga real de CSV (486 bytes) y constancia PDF válida (4563 bytes) con registros de prueba.
- Google habilitado: redirección HTTP 302 a `accounts.google.com` con el callback del proyecto correcto.

Los cinco usuarios temporales y sus registros vinculados se eliminaron al finalizar. Los datos académicos oficiales y el historial de migraciones permanecen.

## Google OAuth

- Client ID y Client Secret configurados en Supabase; no se guardaron en Flutter ni en archivos del proyecto.
- Proveedor Google habilitado.
- Se abrió desde el botón de Flutter la pantalla oficial de acceso de Google, sin error de callback.
- Callback: `https://spduupvhofygzkcmqmiz.supabase.co/auth/v1/callback`.
- Retornos permitidos: `http://localhost:8080/**` y `http://127.0.0.1:8080/**`.
- Site URL de desarrollo: `http://localhost:8080`.

**Pendiente de prueba manual:** completar el inicio de sesión y el consentimiento con una cuenta Google. El usuario decidió realizar este paso posteriormente. No se afirma que ese consentimiento completo haya sido probado.

## Correo

La confirmación de correo sigue activada. No hay SMTP personalizado configurado.

Supabase rechazó las direcciones temporales de `example.com` usadas para probar registro público y recuperación. No se verificó la entrega de correos. El servicio SMTP predeterminado de Supabase limita los destinatarios a miembros autorizados de la organización; para cuentas de estudiantes debe configurarse SMTP personalizado en Authentication.

El login por contraseña de usuarios confirmados sí se comprobó. Google OAuth no necesita un correo de confirmación enviado por el SMTP de Supabase.

## Verificación local

- `flutter analyze`: sin incidencias.
- `flutter test`: **11 pruebas aprobadas**, incluyendo botón Google, rutas protegidas, CUI y responsive.
- `flutter build web --release --dart-define-from-file=config.json`: compilación correcta.

La compilación de `build/web` usa la URL y la clave pública del nuevo proyecto. Puede revisarse con `python tool/serve_web.py --port 8080`.

## Primer administrador

Todavía se debe crear la cuenta real de quien administrará la plataforma. Después de ingresar por Google o registrar una cuenta confirmada, asigna el rol desde SQL Editor:

```sql
update public.profiles
set role = 'admin'
where email = 'TU-CORREO';
```

Cierra sesión y vuelve a ingresar para actualizar el rol. La cuenta del Dashboard de Supabase no se convierte automáticamente en una cuenta de la aplicación.
