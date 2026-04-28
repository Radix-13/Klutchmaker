#!/bin/bash

echo "===================================================="
echo "          KlutchMaker Backend Service (Bash)        "
echo "===================================================="
echo ""

# Navigate to backend directory
cd "$(dirname "$0")/backend"

# Check for Python
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo "[ERROR] Python is not installed or not in PATH."
    exit 1
fi

# Determine python command
PYTHON_CMD="python3"
if ! command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
fi

echo "[INFO] Ensuring core dependencies are installed..."
$PYTHON_CMD -m pip install --user fastapi uvicorn pydantic -q

if [ -f "requirements.txt" ]; then
    echo "[INFO] Installing additional requirements..."
    $PYTHON_CMD -m pip install --user -r requirements.txt -q
fi

echo ""
echo "[SUCCESS] Backend is starting!"
echo "----------------------------------------------------"
echo "URL:       http://localhost:8000"
echo "----------------------------------------------------"
echo ""

$PYTHON_CMD -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
