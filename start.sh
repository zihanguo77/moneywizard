#!/usr/bin/env bash
# MoneyWizard — AI Spending Agent Launch Script
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=========================================================="
echo "  🧙‍♂️ MoneyWizard — Autonomous AI Spending Agent"
echo "  Briefcase × Stripe London Hackathon MVP"
echo "=========================================================="

# Check Python environment
if [ -d "$DIR/venv" ]; then
  PYTHON_BIN="$DIR/venv/bin/python3"
else
  PYTHON_BIN="python3"
fi

echo ">> Starting FastAPI Backend on http://127.0.0.1:8000..."
"$PYTHON_BIN" "$DIR/backend/run.py" &
BACKEND_PID=$!

echo ">> Starting Vite Frontend on http://127.0.0.1:5173..."
cd "$DIR/frontend"
npm run dev &
FRONTEND_PID=$!

# Trap Ctrl+C to cleanly kill both processes
cleanup() {
  echo ""
  echo ">> Shutting down MoneyWizard services..."
  kill $BACKEND_PID 2>/dev/null || true
  kill $FRONTEND_PID 2>/dev/null || true
  echo ">> Shutdown complete. Goodbye!"
  exit 0
}

trap cleanup INT TERM

echo ""
echo ">> MoneyWizard is RUNNING!"
echo "   - Web Dashboard: http://localhost:5173"
echo "   - Backend API:   http://127.0.0.1:8000"
echo "   - API Docs:      http://127.0.0.1:8000/docs"
echo ""
echo "Press Ctrl+C at any time to stop both servers."

wait
