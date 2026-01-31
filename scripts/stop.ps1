# ============================================
# SCRIPT DE PARADA - Bible AI Chat
# PowerShell para Windows
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Bible AI Chat - Parando servicos..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Parar containers
docker compose down

Write-Host ""
Write-Host "[OK] Servicos parados com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Para remover volumes (CUIDADO: apaga dados):" -ForegroundColor Yellow
Write-Host "  docker compose down -v"
