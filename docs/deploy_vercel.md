# Publicar en Vercel desde GitHub

La integración nativa de Vercel importa el repositorio y publica cada push. **No necesitas VERCEL_TOKEN, VERCEL_ORG_ID ni VERCEL_PROJECT_ID.**

`vercel.json` configura la compilación de Flutter, la salida estática y las rutas de la aplicación. `.github/workflows/flutter-ci.yml` ejecuta análisis y pruebas en GitHub de forma independiente; no publica ni necesita secrets.

## 1. Importar el repositorio en Vercel

1. Entra en https://vercel.com y selecciona **Add New → Project**.
2. Conecta tu cuenta GitHub y selecciona **AdMu2838/Labs_PE**.
3. Usa **Root Directory: `./`** y **Framework Preset: Other**.
4. Vercel leerá estas opciones de `vercel.json`:
   - Build Command: `bash tool/build_vercel.sh`
   - Output Directory: `build/web`
   - Install Command vacío: el script instala las dependencias de Flutter.
5. Agrega las variables del siguiente apartado y pulsa **Deploy**.

No necesitas instalar Flutter en tu cuenta Vercel. El script obtiene el SDK oficial **3.44.6**, habilita web, resuelve el lockfile, analiza y prueba la aplicación y genera el build release.

La primera compilación puede tardar varios minutos mientras se descarga el SDK. En los logs encontrarás la versión y cada etapa del build.

## 2. Variables de entorno en Vercel

En **Project → Settings → Environment Variables**, agrega:

| Variable | Valor |
|---|---|
| `SUPABASE_URL` | La URL de tu Supabase, igual que en tu `config.json` local. |
| `SUPABASE_PUBLISHABLE_KEY` | La publishable key o la clave anon antigua de Supabase. |

Actívalas para **Production** y **Preview** si quieres probar ambas clases de despliegue. Después de cambiar una variable, ejecuta un nuevo despliegue.

Estas dos variables públicas se incorporan a Flutter durante la compilación. `config.json` local no se necesita en GitHub. El script rechaza claves secretas y JWT `service_role`.

El Client Secret de Google permanece en Supabase. No se agrega a Vercel ni al código Flutter.

## 3. Despliegues automáticos

- Los pushes a la rama de producción `main` publican el dominio de producción del proyecto.
- Vercel genera previews para las ramas y pull requests según los ajustes de la integración Git.
- El workflow **Flutter CI** comprueba análisis y pruebas en GitHub, sin tokens de Vercel.
- Vercel también ejecuta análisis y pruebas en su propio script y no completa el build si alguna etapa falla.

La integración nativa publica desde el código del repositorio; no espera un artefacto generado por GitHub Actions.

## 4. Configurar autenticación para el dominio

Después del primer despliegue, usa el dominio estable de producción, por ejemplo `https://unsa-lab.vercel.app`:

1. En **Supabase → Authentication → URL Configuration**, configura **Site URL** con el dominio publicado.
2. Agrega `https://TU-DOMINIO/**` a **Redirect URLs**, conservando las direcciones locales si todavía las usas.
3. La recuperación vuelve a `https://TU-DOMINIO/password`.
4. Agrega `https://TU-DOMINIO` a **Authorized JavaScript origins** del cliente OAuth en Google Cloud.
5. El callback de Google sigue siendo el de Supabase:
   `https://spduupvhofygzkcmqmiz.supabase.co/auth/v1/callback`.

Para OAuth en previews también debes permitir sus URLs de retorno en Supabase. Para la prueba principal de acceso utiliza un dominio estable.

## Rutas y caché

La configuración sirve primero los archivos estáticos existentes. Si no existe un archivo para la URL, entrega `/index.html`, de modo que GoRouter resuelva `/login`, `/catalog`, `/admin`, `/password` y las demás rutas.

Los archivos de arranque y el HTML se revalidan para cargar la versión nueva. Solo `build/web` se publica: documentos, cuentas locales y migraciones no forman parte del sitio estático. El build no cambia la base de datos.

## Problemas habituales

- **Falta SUPABASE_URL o la clave:** agrega las variables en el entorno correspondiente y vuelve a desplegar.
- **Aparece una versión anterior:** realiza un redeploy; las variables quedan fijadas al compilar.
- **Google vuelve a localhost:** revisa Site URL y Redirect URLs de Supabase.
- **La ruta /admin devuelve 404:** conserva el `vercel.json` incluido y Root Directory en `./`.

## Referencias

- https://vercel.com/docs/git/vercel-for-github
- https://vercel.com/docs/builds/configure-a-build
- https://vercel.com/docs/project-configuration/vercel-json
- https://docs.flutter.dev/deployment/web
