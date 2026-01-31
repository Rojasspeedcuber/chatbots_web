# ============================================
# SCRIPT DE INICIALIZACAO - Bible AI Chat
# PowerShell para Windows
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Bible AI Chat - Inicializando..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Verificar Docker
try {
    docker --version | Out-Null
    Write-Host "[OK] Docker encontrado" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Docker nao encontrado. Instale o Docker Desktop." -ForegroundColor Red
    exit 1
}

# Verificar Docker Compose
try {
    docker compose version | Out-Null
    Write-Host "[OK] Docker Compose encontrado" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Docker Compose V2 nao encontrado." -ForegroundColor Red
    exit 1
}

# Verificar arquivo .env
if (-not (Test-Path ".env")) {
    Write-Host "[AVISO] Arquivo .env nao encontrado. Criando a partir do exemplo..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "[IMPORTANTE] Configure as variaveis em .env antes de continuar!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Variaveis obrigatorias:"
    Write-Host "  - OPENAI_API_KEY"
    Write-Host "  - MP_ACCESS_TOKEN"
    Write-Host "  - POSTGRES_PASSWORD (altere o padrao)"
    Write-Host ""
    Read-Host "Pressione ENTER apos configurar o .env"
}

# Criar diretorios necessarios
Write-Host "[INFO] Criando diretorios..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "n8n\workflows" | Out-Null
New-Item -ItemType Directory -Force -Path "nginx\ssl" | Out-Null
New-Item -ItemType Directory -Force -Path "postgres" | Out-Null

# Copiar workflows n8n se existirem
$workflows = Get-ChildItem -Path "." -Filter "n8n_*.json" -ErrorAction SilentlyContinue
if ($workflows) {
    Write-Host "[INFO] Copiando workflows n8n..." -ForegroundColor Green
    Copy-Item "n8n_*.json" "n8n\workflows\" -Force
}

# Build das imagens
Write-Host "[INFO] Construindo imagens Docker..." -ForegroundColor Green
docker compose build --no-cache

# Iniciar servicos
Write-Host "[INFO] Iniciando servicos..." -ForegroundColor Green
docker compose up -d

# Aguardar servicos
Write-Host "[INFO] Aguardando servicos ficarem prontos..." -ForegroundColor Green
Start-Sleep -Seconds 15

# Verificar status
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Status dos Servicos" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
docker compose ps

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  URLs de Acesso" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Frontend:  http://localhost" -ForegroundColor White
Write-Host "  n8n Admin: http://localhost:5678" -ForegroundColor White
Write-Host "  n8n API:   http://localhost/webhook/" -ForegroundColor White
Write-Host ""
Write-Host "[OK] Bible AI Chat iniciado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Comandos uteis:" -ForegroundColor Yellow
Write-Host "  docker compose logs -f        # Ver logs"
Write-Host "  docker compose ps             # Ver status"
Write-Host "  docker compose down           # Parar servicos"
Write-Host "  docker compose restart        # Reiniciar servicos"
