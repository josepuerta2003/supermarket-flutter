#!/usr/bin/env bash
# Compilador automatico de SuperMarket (Linux / macOS)
# Uso: ./build_apk.sh
set -euo pipefail

APP_NAME="SuperMarket"
ORG="com.supermarket"
cd "$(dirname "$0")"

step() { printf '\n\033[36m[%s/6] %s\033[0m\n' "$1" "$2"; }
ok()   { printf '      \033[32mOK\033[0m  %s\n' "$1"; }
fail() { printf '\n\033[31m[ERROR] %s\033[0m\n' "$1"; exit 1; }

echo "=== COMPILADOR AUTOMATICO DE $APP_NAME ==="

step 1 "Verificando Flutter..."
command -v flutter >/dev/null 2>&1 || fail "Flutter no esta instalado: https://docs.flutter.dev/get-started/install"
ok "$(flutter --version | head -n1)"

step 2 "Preparando proyecto Android..."
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ ! -f "$MANIFEST" ]; then
  flutter create --org "$ORG" --project-name super_app --platforms android .
  ok "Carpeta android creada"
else
  ok "Carpeta android ya existe"
fi

step 3 "Asignando el nombre '$APP_NAME'..."
sed -i.bak -E "s/android:label=\"[^\"]*\"/android:label=\"$APP_NAME\"/" "$MANIFEST" && rm -f "$MANIFEST.bak"
ok "Nombre bajo el icono: $APP_NAME"

step 4 "Descargando dependencias..."
flutter pub get
ok "Dependencias listas"

# Android 5.0+ y clave de firma propia (la crea la primera vez en firma/)
dart run tool/preparar_android.dart "$APP_NAME"

step 5 "Compilando APK..."
flutter build apk --release
ok "Compilacion terminada"

step 6 "Guardando el APK..."
SRC="build/app/outputs/flutter-apk/app-release.apk"
[ -f "$SRC" ] || fail "No se encontro el APK en $SRC"
mkdir -p APK
VERSION=$(grep -E '^version:' pubspec.yaml | sed -E 's/version:[[:space:]]*([0-9.]+).*/\1/')
cp "$SRC" "APK/$APP_NAME.apk"
cp "$SRC" "APK/$APP_NAME-v$VERSION-$(date +%Y%m%d-%H%M).apk"

echo
echo "=== LISTO: APK/$APP_NAME.apk ($(du -h "APK/$APP_NAME.apk" | cut -f1)) ==="
