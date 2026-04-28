@echo off
SETLOCAL EnableDelayedExpansion

echo ====================================================
echo           KlutchMaker Backend Service
echo ====================================================
echo.

cd /d "%~dp0backend"

REM Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH.
    pause
    exit /b
)

echo [INFO] Ensuring core dependencies are installed...
python -m pip install --user fastapi uvicorn pydantic -q

REM Optional: Try to install from requirements.txt if it exists
if exist "requirements.txt" (
    echo [INFO] Installing additional requirements...
    python -m pip install --user -r requirements.txt -q
)

echo.
echo [SUCCESS] Backend is starting!
echo ----------------------------------------------------
echo URL:       http://localhost:8000
echo ----------------------------------------------------
echo.

REM Running with python -m uvicorn ensures it uses the one we just installed
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

pause
