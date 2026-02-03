@echo off
REM ============================================
REM Script para importar a Biblia via Docker
REM Executa a importacao dentro do container
REM ============================================

echo.
echo ========================================
echo IMPORTADOR DE BIBLIA VIA DOCKER
echo ========================================
echo.

REM Verifica se o container PostgreSQL esta rodando
docker ps | findstr bible-chat-postgres >nul
if errorlevel 1 (
    echo ERRO: Container bible-chat-postgres nao esta rodando!
    echo Execute: docker compose up -d
    pause
    exit /b 1
)

echo Copiando arquivos para o container...

REM Copia o script de importacao e a base SQL para o container
docker cp "%~dp0import_biblia.py" bible-chat-postgres:/tmp/import_biblia.py
docker cp "%~dp0..\biblia_base_sql\biblia.sql" bible-chat-postgres:/tmp/biblia.sql

echo.
echo Instalando psycopg2 e executando importacao...
echo.

REM Executa a importacao dentro do container PostgreSQL
docker exec -it bible-chat-postgres sh -c "apk add --no-cache python3 py3-pip && pip3 install psycopg2-binary --break-system-packages 2>/dev/null || pip3 install psycopg2-binary && cd /tmp && POSTGRES_HOST=localhost POSTGRES_USER=n8n POSTGRES_PASSWORD=n8n_secure_password_2025 POSTGRES_DB=n8n python3 import_biblia.py"

echo.
echo Limpando arquivos temporarios...
docker exec bible-chat-postgres rm -f /tmp/import_biblia.py /tmp/biblia.sql

echo.
echo Concluido!
pause
