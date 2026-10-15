#!/usr/bin/env bash
# =====================================================================
#  MoneyWizard - one command to run the whole application.
#
#      ./run.sh
#
#  Serves the API *and* the dashboard on http://127.0.0.1:8000
#  Override the port with:   PORT=8001 ./run.sh
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")"

PORT="${PORT:-8000}"

# --- 1. Find a usable Python (3.9+) -----------------------------------
find_python() {
  for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)' 2>/dev/null; then
        command -v "$candidate"
        return 0
      fi
    fi
  done
  return 1
}

# --- 2. Create or repair the virtual environment ----------------------
venv_is_good() {
  [ -x ".venv/bin/python" ] &&
  .venv/bin/python -c 'import fastapi, uvicorn, stripe, yaml, dotenv' 2>/dev/null
}

if ! venv_is_good; then
  PYTHON="$(find_python || true)"
  if [ -z "$PYTHON" ]; then
    echo "ERROR: no Python 3.9+ found on your PATH."
    echo "Install Python from https://www.python.org/downloads/ and run this again."
    exit 1
  fi
  echo "Setting up the Python environment (first run only, takes ~30s)..."
  "$PYTHON" -m venv --clear .venv
  .venv/bin/python -m pip install --quiet --upgrade pip
  .venv/bin/python -m pip install --quiet -r backend/requirements.txt
  echo "Environment ready."
fi

# --- 3. Check the dashboard bundle ------------------------------------
if [ ! -f "frontend/dist/index.html" ]; then
  if command -v npm >/dev/null 2>&1 && [ -d "frontend/node_modules" ]; then
    echo "Building the dashboard..."
    (cd frontend && npm run build)
  else
    echo "WARNING: frontend/dist is missing and Node.js is unavailable."
    echo "         The API will run, but the dashboard will not be served."
    echo "         Ask for the prebuilt dist/ folder, or install Node.js."
  fi
fi

# --- 4. Warn (loudly) if Stripe is not configured ---------------------
if [ ! -f "backend/.env" ]; then
  echo
  echo "  ------------------------------------------------------------"
  echo "   Stripe is NOT configured, so payments cannot run."
  echo "   MoneyWizard will say so honestly instead of faking a payment."
  echo
  echo "   To enable payments:"
  echo "     cp backend/.env.example backend/.env"
  echo "     # edit backend/.env and set STRIPE_SECRET_KEY=sk_test_..."
  echo "  ------------------------------------------------------------"
  echo
fi

echo "MoneyWizard is starting on http://127.0.0.1:${PORT}"
echo "Press Ctrl+C to stop."
echo
exec .venv/bin/python -m uvicorn app.main:app \
  --app-dir backend --host 127.0.0.1 --port "${PORT}"
