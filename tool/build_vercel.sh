#!/usr/bin/env bash
# Despliegue nativo: Vercel ejecuta este build al recibir cambios desde GitHub.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.6}"
if [[ ! "$FLUTTER_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf '%s\n' 'FLUTTER_VERSION debe ser una versión exacta, por ejemplo 3.44.6.' >&2
  exit 1
fi

# Falla temprano si faltan las variables, antes de descargar el SDK.
node tool/write_build_config.mjs

SDK_DIR="$PWD/.flutter-sdk/$FLUTTER_VERSION"
if [[ ! -x "$SDK_DIR/bin/flutter" ]]; then
  mkdir -p "$(dirname "$SDK_DIR")"
  printf 'Instalando Flutter %s desde el repositorio oficial...\n' "$FLUTTER_VERSION"
  git clone --quiet --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$SDK_DIR"
fi

export PATH="$SDK_DIR/bin:$PATH"
export PUB_CACHE="$PWD/.pub-cache"

flutter --version
flutter config --enable-web --no-analytics
flutter precache --web
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub --no-wasm-dry-run \
  --dart-define-from-file=.dart_tool/vercel_build_config.json

test -f build/web/index.html
test -f build/web/main.dart.js
printf '%s\n' 'UNSA · LAB: build/web listo para publicar en Vercel.'
