@echo off
rem Starts the backend with the correct venv interpreter (works from cmd or double-click).
cd /d "%~dp0"
if not exist .env (
    echo [!] backend\.env missing — copy .env.example to .env and fill in the keys first.
    exit /b 1
)
C:\Users\asus\.venvs\ioe-backend\Scripts\uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
