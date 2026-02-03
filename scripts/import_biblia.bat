@echo off
REM ============================================
REM Script para importar a Biblia no Windows
REM ============================================

echo.
echo ========================================
echo IMPORTADOR DE BIBLIA - Bible AI Chat
echo ========================================
echo.

REM Configuracoes de conexao local (fora do Docker)
set POSTGRES_HOST=localhost
set POSTGRES_PORT=5432
set POSTGRES_DB=n8n
set POSTGRES_USER=n8n
set POSTGRES_PASSWORD=n8n_secure_password_2025

echo Conectando em: %POSTGRES_HOST%:%POSTGRES_PORT%/%POSTGRES_DB%
echo Usuario: %POSTGRES_USER%
echo.

REM Executa o script Python
python "%~dp0import_biblia.py"

echo.
pause
