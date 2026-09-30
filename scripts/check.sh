#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "Resolving Flutter dependencies from pubspec.lock..."
flutter pub get --enforce-lockfile

echo "Checking Dart formatting..."
dart format --output=none --set-exit-if-changed \
  lib/screens/messages_screen.dart \
  test

echo "Analyzing Flutter application..."
flutter analyze --no-pub --no-fatal-infos

echo "Running Flutter tests..."
flutter test --no-pub
