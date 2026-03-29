#!/usr/bin/env bash
set -euo pipefail

# Создаёт tar.gz из Flutter Linux release bundle.
# Требование: предварительно выполнить `flutter build linux --release` на Linux.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_NAME="atx_wallet"

BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
PUBSPEC="$ROOT_DIR/pubspec.yaml"
DIST_DIR="$ROOT_DIR/dist"

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "Не найдена папка $BUNDLE_DIR"
  echo "Сначала выполните: flutter build linux --release"
  exit 1
fi

VERSION="1.0.0"
if [[ -f "$PUBSPEC" ]]; then
  # Берём только build-name (до '+')
  VERSION_LINE="$(grep -E '^version:' "$PUBSPEC" | head -n1 | awk '{print $2}')" || true
  if [[ -n "${VERSION_LINE:-}" ]]; then
    VERSION="${VERSION_LINE%%+*}"
  fi
fi

mkdir -p "$DIST_DIR"
OUT_FILE="$DIST_DIR/${APP_NAME}-linux-x86_64-${VERSION}.tar.gz"

# Упаковываем содержимое bundle так, чтобы в корне архива лежали файлы приложения.
# (удобнее для распаковки)
tar -C "$BUNDLE_DIR" -czf "$OUT_FILE" .

echo "OK: $OUT_FILE"
