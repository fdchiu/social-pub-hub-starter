#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[gate] Flutter analyze + test"
cd "$ROOT_DIR/app"
flutter pub get
flutter analyze --no-fatal-infos
flutter test

echo "[gate] Backend pytest"
cd "$ROOT_DIR/backend"
if [[ ! -d ".venv" ]]; then
  python3 -m venv .venv
fi
./.venv/bin/python -m pip install -r requirements.txt
./.venv/bin/python -m pytest -q

echo "[gate] OK"
