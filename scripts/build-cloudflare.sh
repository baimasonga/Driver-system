#!/usr/bin/env bash
set -euo pipefail

# Cloudflare Pages does not include Flutter in its standard build image.
# Install the stable SDK locally so the dashboard's existing `npm run build`
# setting can build this Flutter project without requiring dashboard changes.
FLUTTER_DIR="${PWD}/.flutter-sdk"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  git clone --depth 1 --branch stable \
    https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter config --no-analytics
flutter pub get
flutter build web --release
