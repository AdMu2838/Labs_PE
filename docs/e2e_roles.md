# Pruebas end-to-end: cuentas persistentes LAB04

Se comprobaron tres sesiones reales e independientes de Flutter Web contra el proyecto Supabase `spduupvhofygzkcmqmiz`. Se ejecutaron **45 comprobaciones positivas**, sin errores de ejecución ni desbordes registrados en las pantallas.

## Cuentas disponibles

| Correo | Rol | Estado |
|---|---|---|
| estudiante.lab04@example.com | student | Activa, correo confirmado, CUI 99004001 |
| docente.lab04@example.com | teacher | Activa, correo confirmado |
| admin.lab04@example.com | admin | Activa, correo confirmado |

Las contraseñas no se guardan en documentación pública ni en el repositorio. La copia local está en `.dart_tool/test_accounts.json`, excluida por `.gitignore`.

## Oferta preparada

- Periodo `LAB04 - PRUEBAS`, matrícula abierta hasta el 10/01/2027 y cambios/retiros hasta el 20/01/2027, hora local de Arequipa.
- Dos ambientes de prueba, cinco grupos y nueve sesiones.
- Cursos: Introducción al Desarrollo de Software, Introducción al Desarrollo Web y Base de Datos.
- Habilitaciones e historial académico de prueba importados desde la interfaz.
- El estudiante conserva tres matrículas activas, con horarios compatibles.
- Los grupos SOFT-A y SOFT-B se probaron con una vacante y luego se restauraron a 30 plazas.
- El actor adicional usado para probar la cola fue eliminado. Las tres cuentas anteriores permanecen.

## Flujos verificados

1. Creación de cada cuenta, confirmación, perfil y rol.
2. Login y carga del dashboard en los tres roles.
3. Creación de periodo, laboratorio, grupo y horario desde administración.
4. Previsualización e importación CSV de habilitaciones e historial.
5. Matrícula desde catálogo y rechazo de duplicados.
6. Cambio de grupo y actualización del horario.
7. Rechazo de cruces de horario y conservación de matrícula.
8. Ruta administrativa protegida para estudiantes.
9. Operaciones administrativas bloqueadas para docentes.
10. Destino lleno no seleccionable; cambio fallido no elimina el origen.
11. Retiro, liberación de vacante y registro en espera.
12. Promoción automática al retirarse el ocupante temporal.
13. Envío de solicitud, respuesta administrativa y notificaciones.
14. Consulta de grupos y estudiantes por el docente.
15. Publicación de aviso docente y lectura desde el estudiante.
16. Matrícula de otros dos cursos, sin cruces y con requisitos válidos.
17. Edición de datos personales del estudiante.
18. PDF de constancia descargado, válido y con tres matrículas.
19. CSV descargado por docente y administrador con nombre y CUI autorizados.
20. Restricción final de perfiles mediante RLS y existencia de auditoría.

Se conservan capturas web en `docs/e2e_assets/`.

## Corrección realizada

Se ajustó `Panel` con `Semantics(container: true, explicitChildNodes: true)` y `Card(semanticContainer: false)` para que títulos e instrucciones no se mezclen con los controles. Se añadió una prueba de accesibilidad y se verificó en el navegador que el selector de importación queda independiente.

## Verificación local

- `flutter test --no-pub`: **12 pruebas aprobadas**.
- `flutter analyze`: sin incidencias.
- `flutter build web --release --no-pub --no-wasm-dry-run --dart-define-from-file=config.json`: compilación correcta.

Durante una compilación Windows bloqueó `impellerc.exe`; el intento posterior finalizó correctamente. No se modificó la configuración de seguridad del equipo desde los scripts.

## Alcance externo pendiente

Google está configurado y se comprobó su redirección y callback; el consentimiento personal completo sigue siendo una prueba manual. El envío de confirmaciones y recuperación por correo requiere SMTP personalizado para destinatarios ajenos al equipo de Supabase. Las cuentas de prueba están confirmadas y pueden ingresar por contraseña sin depender de correo SMTP.
