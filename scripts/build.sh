#!/usr/bin/env bash
set -euo pipefail

echo "=== Evolve Staff: Starting Flutter Web Build ==="

FLUTTER_VERSION="3.35.7"

# Avoid dubious ownership warnings in container/CI environments
git config --global --add safe.directory '*' || true

# Check if Flutter is already present in PATH
if command -v flutter >/dev/null 2>&1; then
  echo "Flutter is already installed in PATH: $(command -v flutter)"
else
  FLUTTER_DIR="${VERCEL_CACHE_DIR:-$HOME}/flutter"
  if [ ! -d "$FLUTTER_DIR/bin" ]; then
    echo "Cloning Flutter SDK (tag $FLUTTER_VERSION) into $FLUTTER_DIR..."
    mkdir -p "$(dirname "$FLUTTER_DIR")"
    git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" --depth 1 "$FLUTTER_DIR" || {
      echo "Standard clone failed, falling back to tag checkout..."
      git clone --depth 1 https://github.com/flutter/flutter.git "$FLUTTER_DIR"
      (cd "$FLUTTER_DIR" && git fetch --depth 1 origin tags/"$FLUTTER_VERSION":tags/"$FLUTTER_VERSION" && git checkout "$FLUTTER_VERSION")
    }
  else
    echo "Using cached Flutter SDK from $FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

echo "=== Configuring Flutter ==="
flutter config --no-analytics
flutter --version

echo "=== Getting Flutter dependencies ==="
flutter pub get

echo "=== Building Flutter Web for Release ==="
flutter build web --release

echo "=== Flutter Web Build Complete ==="
