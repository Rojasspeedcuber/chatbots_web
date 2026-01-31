#!/bin/bash
# ============================================
# SCRIPT DE PARADA - Bible AI Chat
# ============================================

echo "============================================"
echo "  Bible AI Chat - Parando servicos..."
echo "============================================"

# Parar containers
docker compose down

echo ""
echo "[OK] Servicos parados com sucesso!"
echo ""
echo "Para remover volumes (CUIDADO: apaga dados):"
echo "  docker compose down -v"
