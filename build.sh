#!/usr/bin/env bash
# Render free-tier static sites do not ship with Flutter, so this build
# script downloads the pinned stable Linux SDK, then compiles the web app.
set -euo pipefail

FLUTTER_VERSION="3.44.6"
FLUTTER_ROOT_DIR="$HOME/flutter"
FLUTTER_PATH="$FLUTTER_ROOT_DIR/flutter"
FLUTTER_TARBALL="/tmp/flutter_${FLUTTER_VERSION}.tar.xz"

if [ ! -d "$FLUTTER_PATH/bin" ]; then
  echo "==> Downloading Flutter $FLUTTER_VERSION (first build only) ..."
  mkdir -p "$FLUTTER_ROOT_DIR"
  curl -fsSL -o "$FLUTTER_TARBALL" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar xf "$FLUTTER_TARBALL" -C "$FLUTTER_ROOT_DIR"
  rm -f "$FLUTTER_TARBALL"
fi

export PATH="$FLUTTER_PATH/bin:$PATH"

flutter config --no-analytics
flutter pub get

DART_DEFINES=()
if [ -n "${SUPABASE_URL:-}" ]; then
  DART_DEFINES+=("--dart-define=SUPABASE_URL=${SUPABASE_URL}")
fi
if [ -n "${SUPABASE_KEY:-}" ]; then
  DART_DEFINES+=("--dart-define=SUPABASE_KEY=${SUPABASE_KEY}")
fi

echo "==> Building Flutter web (release) ..."
flutter build web --release "${DART_DEFINES[@]}"
