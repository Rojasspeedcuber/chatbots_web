#!/bin/bash
# ============================================
# SCRIPT DE INICIALIZACAO - Bible AI Chat
# ============================================

set -e

echo "============================================"
echo "  Bible AI Chat - Inicializando..."
echo "============================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[ERRO] Docker nao encontrado. Instale o Docker primeiro.${NC}"
    exit 1
fi

# Verificar Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}[ERRO] Docker Compose V2 nao encontrado.${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Docker e Docker Compose encontrados${NC}"

# Verificar arquivo .env
if [ ! -f .env ]; then
    echo -e "${YELLOW}[AVISO] Arquivo .env nao encontrado. Criando a partir do exemplo...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}[IMPORTANTE] Configure as variaveis em .env antes de continuar!${NC}"
    echo ""
    echo "Variaveis obrigatorias:"
    echo "  - OPENAI_API_KEY"
    echo "  - MP_ACCESS_TOKEN"
    echo "  - POSTGRES_PASSWORD (altere o padrao)"
    echo ""
    read -p "Pressione ENTER apos configurar o .env..."
fi

# Criar diretorios necessarios
echo -e "${GREEN}[INFO] Criando diretorios...${NC}"
mkdir -p n8n/workflows
mkdir -p nginx/ssl
mkdir -p postgres

# Copiar workflows n8n se existirem
if ls n8n_*.json 1> /dev/null 2>&1; then
    echo -e "${GREEN}[INFO] Copiando workflows n8n...${NC}"
    cp n8n_*.json n8n/workflows/ 2>/dev/null || true
fi

# Build das imagens
echo -e "${GREEN}[INFO] Construindo imagens Docker...${NC}"
docker compose build --no-cache

# Iniciar servicos
echo -e "${GREEN}[INFO] Iniciando servicos...${NC}"
docker compose up -d

# Aguardar servicos ficarem prontos
echo -e "${GREEN}[INFO] Aguardando servicos ficarem prontos...${NC}"
sleep 10

# Verificar status
echo ""
echo "============================================"
echo "  Status dos Servicos"
echo "============================================"
docker compose ps

# Verificar saude dos containers
echo ""
echo "============================================"
echo "  Health Check"
echo "============================================"

check_health() {
    local service=$1
    local status=$(docker inspect --format='{{.State.Health.Status}}' "bible-chat-$service" 2>/dev/null || echo "unknown")
    if [ "$status" == "healthy" ]; then
        echo -e "  $service: ${GREEN}$status${NC}"
    elif [ "$status" == "starting" ]; then
        echo -e "  $service: ${YELLOW}$status${NC}"
    else
        echo -e "  $service: ${RED}$status${NC}"
    fi
}

check_health "postgres"
check_health "redis"
check_health "n8n"
check_health "frontend"

echo ""
echo "============================================"
echo "  URLs de Acesso"
echo "============================================"
echo "  Frontend:  http://localhost:${FRONTEND_PORT:-80}"
echo "  n8n Admin: http://localhost:${N8N_PORT:-5678}"
echo "  n8n API:   http://localhost:${FRONTEND_PORT:-80}/webhook/"
echo ""
echo -e "${GREEN}[OK] Bible AI Chat iniciado com sucesso!${NC}"
echo ""
echo "Comandos uteis:"
echo "  docker compose logs -f        # Ver logs"
echo "  docker compose ps             # Ver status"
echo "  docker compose down           # Parar servicos"
echo "  docker compose restart        # Reiniciar servicos"
