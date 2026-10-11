# UNSA · LAB

Sistema de matrícula de laboratorios para Ingeniería de Sistemas de la Universidad Nacional de San Agustín de Arequipa. Flutter Web + Supabase, interfaz en español, adaptable a móvil, tablet y escritorio.

Estado de las migraciones y pruebas del proyecto configurado: [`docs/verification_supabase.md`](docs/verification_supabase.md).

## Informe de laboratorio 4

Documento editable con la plantilla institucional, capturas web de escritorio, explicación de widgets, comentarios de cambios y código completo:
[`Informe_Laboratorio_4_UNSA_LAB.docx`](docs/Informe_Laboratorio_4_UNSA_LAB.docx).

Integrantes: Mamani Uscamayta Agustin David y Cusilayme Garcia Jose Luis. Semestre: X.

Repositorio configurado como `origin`: https://github.com/AdMu2838/Labs_PE.git.

## Inicio rápido: demostración

Requiere Flutter estable con Dart 3.12 o posterior. Verificado con Flutter 3.44.6.

```powershell
flutter pub get
flutter run -d chrome --web-port 8080
```

Sin credenciales se muestra un **modo de demostración identificado**, con acceso como estudiante, administrador o docente. Los datos ficticios viven en memoria y se reinician al recargar. La demo contiene una selección de cursos; Supabase recibe el catálogo oficial completo.

## Conectar tu proyecto Supabase

### 1. Crear la base de datos

En un proyecto nuevo de Supabase, abre **SQL Editor** y ejecuta, una sola vez y en este orden:

1. `supabase/migrations/001_schema.sql`
2. `supabase/migrations/002_operations.sql`
3. `supabase/migrations/003_curriculum_2025.sql`
4. `supabase/migrations/004_google_onboarding.sql`

La carga incluye **87 asignaturas, 72 relaciones de prerrequisito**, créditos y horas de teoría, práctica y laboratorio del plan oficial 2025. No incluye ambientes, docentes ni horarios inventados en la base real.

No ejecutes `supabase/tests/bootstrap.sql` ni los fixtures en tu proyecto real: son exclusivamente para pruebas en PostgreSQL efímero.

### 2. Colocar tus credenciales

Crea `config.json` tomando como modelo `config.example.json`:

```json
{
  "SUPABASE_URL": "https://tu-proyecto.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

La clave pública se obtiene en la configuración de API de Supabase; la antigua clave `anon` también es compatible. **No uses `service_role` ni una clave `sb_secret_` en Flutter.** El archivo local `config.json` está excluido de Git.

```powershell
flutter run -d chrome --web-port 8080 --dart-define-from-file=config.json
```

Cambiar las variables requiere reiniciar la ejecución o volver a compilar. Con credenciales configuradas, el login usa exclusivamente Supabase Auth; desaparece la selección de roles de demostración.

### 3. Configurar Auth

En **Authentication → URL Configuration**:

- Site URL: `http://localhost:8080` durante el desarrollo.
- Redirect URLs: `http://localhost:8080/**` y posteriormente `https://tu-dominio/**`.
- Habilita registro por email y contraseña y la confirmación de correo.
- Configura SMTP para el envío de confirmaciones y recuperación de contraseña en tu despliegue.

La recuperación regresa a `/password`. La aplicación usa URLs sin `#`; el servidor debe reenviar rutas de la aplicación a `index.html`.

### 4. Crear el primer administrador

Regístrate desde el login y confirma tu correo. Luego ejecuta en SQL Editor, sustituyendo el correo:

```sql
update public.profiles
set role = 'admin'
where email = 'tu-correo@unsa.edu.pe';
```

Cierra sesión e ingresa nuevamente. Las siguientes asignaciones de rol se realizan desde **Administración → Usuarios**. El formulario público de registro siempre crea estudiantes, aunque se manipulen los metadatos del cliente.

### Login con Google

El login incluye **Continuar con Google** y usa Supabase OAuth con retorno al origen de la aplicación. El Client Secret se configura exclusivamente en Supabase; no se coloca en Flutter ni en `config.json`.

Para activarlo:

1. En [Google Auth Platform](https://console.cloud.google.com/auth/overview), selecciona o crea un proyecto y configura Branding/Audience de la aplicación. Si está en modo Testing, agrega tus cuentas de prueba como Test users.
2. En **Clients → Create client**, selecciona **Web application**.
3. Agrega los orígenes JavaScript: `http://localhost:8080` y `http://127.0.0.1:8080` para desarrollo, y posteriormente el dominio HTTPS publicado.
4. Agrega exactamente esta URI de redirección para el proyecto Supabase actualmente configurado:
   `https://spduupvhofygzkcmqmiz.supabase.co/auth/v1/callback`
   Si cambias de proyecto, usa `https://TU-REFERENCIA.supabase.co/auth/v1/callback`.
5. En Supabase, **Authentication → Sign In / Providers → Google**, habilita Google, pega el Client ID y Client Secret y guarda.
6. En **Authentication → URL Configuration**, permite los orígenes de desarrollo y producción con su ruta de retorno. La pantalla de Google regresa primero al callback de Supabase y después a Flutter.

Los usuarios nuevos de Google reciben el rol estudiante. Si no tienen CUI, son dirigidos a **Mi perfil** para registrar los 8 dígitos una sola vez. La base de datos bloquea la matrícula mientras falte el CUI. Los cambios posteriores de CUI requieren coordinación.

Sin proveedor habilitado, el botón muestra un mensaje de configuración pendiente y no abandona el login. La prueba completa de consentimiento de Google requiere las credenciales del cliente OAuth y una cuenta autorizada; la creación de perfiles, asignación única del CUI y permisos se pueden verificar independientemente.

### 5. Publicar la oferta

1. Registra a los docentes y asígnales el rol docente.
2. Crea los ambientes con su capacidad física.
3. Crea un periodo: fechas de matrícula, fecha final de cambios/retiros y estado.
4. Crea los grupos de asignaturas con horas de laboratorio.
5. Crea sus sesiones: día `1 = lunes` hasta `7 = domingo`, horas `HH:MM`.
6. Importa historial académico y cursos habilitados, o regístralos desde administración.
7. Abre el periodo cuando la oferta esté validada.

Los horarios son horas locales de Arequipa; las ventanas de matrícula se almacenan como `timestamptz`. El editor convierte las fechas locales a UTC.

**Exigir habilitación y prerrequisitos** está activado por defecto. Desactivarlo permite probar un periodo sin importar historial; sigue validándose el plan del estudiante, las vacantes, los duplicados y los cruces.

## Funcionalidades

### Estudiantes
- Login por contraseña o Google, registro con CUI, confirmación de correo, recuperación y cierre de sesión.
- Catálogo por curso, código, docente, semestre, periodo y disponibilidad.
- Matrícula, retiro y cambio atómico de grupo.
- Horario por día, historial de matrículas y constancia de consulta PDF.
- Lista de espera, notificaciones, solicitudes y perfil.
- Consulta del plan de estudios e historial académico importado.

### Administración y coordinación
- Gestión de periodos, ambientes, grupos, sesiones, planes, asignaturas y prerrequisitos.
- Habilitaciones e historial académico; importación CSV con previsualización.
- Gestión de perfiles y situaciones académicas. Solo admin asigna roles.
- Respuestas a solicitudes, avisos, reportes CSV y auditoría.
- Recuentos de vacantes actualizados mediante Realtime y consulta agregada protegida.

### Docentes
- Consulta de matrículas de sus grupos y exportación de listas.
- Publicación de avisos a grupos asignados.

El catálogo y sus cifras de ocupación son visibles para usuarios activos. Los datos individuales de matrícula se limitan mediante RLS al estudiante, al docente asignado o a coordinación/administración.

## Reglas de matrícula

Las funciones PostgreSQL son la autoridad del proceso. Las tablas de matrícula y espera no admiten escrituras directas desde el cliente.

- Una matrícula activa por estudiante/curso/periodo.
- Validación de cuenta, plan, grupo publicado, horario y fechas.
- Habilitación teórica, prerrequisitos aprobados y créditos mínimos cuando el periodo los exige.
- Detección de cruces entre **todas** las sesiones, en el mismo periodo.
- Bloqueo transaccional por periodo para impedir sobrecupos concurrentes.
- Cambio de grupo con rollback: una operación fallida conserva la matrícula anterior.
- Cola por fecha y UUID como desempate; promoción al retirar o aumentar capacidad mientras esté abierta la matrícula.
- Candidatos de cola que ya no cumplen requisitos se marcan como omitidos y reciben una notificación.
- Sin cambios de horario, ambiente o estructura de un grupo con matrículas activas.
- Sin cruces de ambiente o docente; capacidad del grupo limitada por la del ambiente.

Las solicitudes aprobadas no evitan estas validaciones: coordinación debe registrar la habilitación correspondiente. Las notificaciones son internas; el email se utiliza para las operaciones de Auth. No existe integración automática con el sistema académico UNSA: las habilitaciones e historial provienen de la importación administrativa.

## CSV de importación

UTF-8, separado por comas, hasta 500 registros por archivo. Los estudiantes deben tener cuenta y plan asignado. El lote completo se revierte si alguna fila es inválida.

Habilitaciones:

```csv
cui,course_code,period_name
20250001,2501103,2026-B
```

Historial:

```csv
cui,course_code,grade
20250001,2501103,16
```

La nota de aprobación se configura actualmente en 11/20. Los créditos aprobados se recalculan a partir del historial. El importador valida códigos contra el plan del estudiante.

## Arquitectura

```text
lib/
  app/                 Aplicación, router, shell y tema
  core/
    config/            Variables de compilación
    domain/            Contratos de repositorio y especificaciones puras
    data/              Implementaciones Supabase/demo e inyección Riverpod
  shared/
    responsive/        Contenedor de página con scroll independiente
    widgets/           Componentes, formularios y estados asíncronos
  features/
    auth/              Domain / data / presentation
    enrollment/        Entidades y pantallas de matrícula
    administration/    Especificación de mantenimientos, usuarios e importación
    dashboard/         Resumen y avisos
    curriculum/        Catálogo académico
    schedules/         Horario
    profiles/          Perfil e historial
    requests/          Atención de solicitudes
    notifications/    Notificaciones
    reports/           Exportación CSV/PDF y reportes
```

Organización por funcionalidades con contratos independientes de Flutter, repositorios, Riverpod y GoRouter. Las pantallas no contienen consultas de Supabase. Los CRUD administrativos comparten un formulario declarativo; las transacciones críticas residen en PostgreSQL.

### Identidad visual y responsive

Tema centralizado en `lib/app/theme/app_theme.dart`:

- Granate `#7B1835` y granate oscuro `#4C1026`.
- Dorado `#C5A15B`.
- Fondo claro `#F7F5F2`.

Es una paleta **inspirada en la identidad de la UNSA**, no una declaración de códigos oficiales de un manual de marca. El ícono de la aplicación es propio, no el escudo oficial.

Formularios de pantalla completa en móvil, filtros adaptativos, tarjetas con ancho calculado, menú lateral en escritorio y drawer en pantallas pequeñas. Las páginas tienen scroll independiente y los textos no dependen de alturas fijas.

## Verificación

```powershell
flutter analyze
flutter test
flutter build web --release
```

Pruebas de login, protección de rutas, matrícula, horario y navegación administrativa a 360, 768 y 1440 px. Las pruebas de PostgreSQL validan migraciones, RLS, escalamiento de roles, duplicados, prerrequisitos, cruces, cambios atómicos, promoción e importación; una prueba concurrente solicita la última vacante desde dos conexiones.

Para ejecutar las pruebas SQL aisladas, requiere Docker y Node:

```powershell
powershell -ExecutionPolicy Bypass -File tool/test_database.ps1
```

El script crea y elimina su propio contenedor PostgreSQL, sin conectarse a tu Supabase.

## Compilar y desplegar

```powershell
flutter build web --release --dart-define-from-file=config.json
```

Publica `build/web` en un hosting estático con fallback SPA. Se incluyen `firebase.json` para Firebase Hosting y `web/_redirects` para Netlify. Configura también las URLs de Auth del dominio definitivo.

Para revisar una compilación local con soporte para rutas directas:

```powershell
python tool/serve_web.py --port 8080
```

La constancia PDF es de consulta de laboratorios y no reemplaza una constancia oficial del sistema académico.

## Fuentes del catálogo

- [Página oficial del plan 2025](https://fips.unsa.edu.pe/ingenieriadesistemas/plan-de-estudios-2025/).
- [PDF oficial EPIS](https://fips.unsa.edu.pe/ingenieriadesistemas/wp-content/uploads/sites/2/2026/08/epis-plan-de-estudios-2025.pdf), exportación del SAA del 08/07/2026.

La estructura admite otros planes; el plan 2017 y sus equivalencias no están cargados. Las equivalencias requieren validación académica antes de habilitar cruces entre planes.
