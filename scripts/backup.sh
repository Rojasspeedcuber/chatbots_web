#!/bin/bash
# ============================================
# SCRIPT DE BACKUP - Bible AI Chat
# ============================================

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP"

echo "============================================"
echo "  Bible AI Chat - Backup"
echo "============================================"

# Criar diretorio de backup
mkdir -p "$BACKUP_DIR"

# Backup do PostgreSQL
echo "[INFO] Fazendo backup do PostgreSQL..."
docker compose exec -T postgres pg_dump -U "${POSTGRES_USER:-n8n}" "${POSTGRES_DB:-n8n}" > "${BACKUP_FILE}_postgres.sql"
gzip "${BACKUP_FILE}_postgres.sql"
echo "[OK] PostgreSQL: ${BACKUP_FILE}_postgres.sql.gz"

# Backup dos volumes n8n
echo "[INFO] Fazendo backup dos dados n8n..."
docker run --rm \
    -v bible-chat-n8n-data:/data:ro \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine tar czf "/backup/backup_${TIMESTAMP}_n8n.tar.gz" -C /data .
echo "[OK] n8n: ${BACKUP_FILE}_n8n.tar.gz"

# Backup dos workflows
echo "[INFO] Fazendo backup dos workflows..."
if [ -d "n8n/workflows" ]; then
    tar czf "${BACKUP_FILE}_workflows.tar.gz" n8n/workflows/
    echo "[OK] Workflows: ${BACKUP_FILE}_workflows.tar.gz"
fi

echo ""
echo "============================================"
echo "  Backup concluido!"
echo "============================================"
echo "Arquivos salvos em: $BACKUP_DIR/"
ls -lh "$BACKUP_DIR"/backup_${TIMESTAMP}*

# Limpar backups antigos (manter ultimos 7 dias)
echo ""
echo "[INFO] Limpando backups com mais de 7 dias..."
find "$BACKUP_DIR" -name "backup_*.gz" -mtime +7 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "backup_*.sql" -mtime +7 -delete 2>/dev/null || true
echo "[OK] Limpeza concluida"
