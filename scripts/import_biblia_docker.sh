#!/bin/bash
# ============================================
# Script para importar a Biblia via Docker
# Uso: ./scripts/import_biblia_docker.sh
# ============================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  IMPORTADOR DA BIBLIA - Via Docker${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# Verificar se o Docker esta rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Erro: Docker nao esta rodando${NC}"
    exit 1
fi

# Verificar se o container postgres existe e esta rodando
if ! docker ps | grep -q bible-chat-postgres; then
    echo -e "${RED}Erro: Container bible-chat-postgres nao esta rodando${NC}"
    echo -e "${YELLOW}Execute primeiro: docker compose up -d${NC}"
    exit 1
fi

# Diretorio do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SQL_FILE="$PROJECT_DIR/biblia_base_sql/biblia.sql"

# Verificar se o arquivo SQL existe
if [ ! -f "$SQL_FILE" ]; then
    echo -e "${RED}Erro: Arquivo nao encontrado: $SQL_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Arquivo SQL: $SQL_FILE${NC}"
echo -e "${YELLOW}Tamanho: $(du -h "$SQL_FILE" | cut -f1)${NC}"
echo ""

# Verificar se as tabelas existem
echo -e "${YELLOW}Verificando tabelas...${NC}"
TABLES=$(docker exec bible-chat-postgres psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('testamentos', 'livros', 'versiculos');")
TABLES=$(echo $TABLES | tr -d ' ')

if [ "$TABLES" != "3" ]; then
    echo -e "${RED}Erro: Tabelas da Biblia nao encontradas${NC}"
    echo -e "${YELLOW}Recrie os containers: docker compose down && docker compose up -d${NC}"
    exit 1
fi

echo -e "${GREEN}Tabelas encontradas!${NC}"
echo ""

# Verificar se ja existem dados
COUNT=$(docker exec bible-chat-postgres psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM versiculos;")
COUNT=$(echo $COUNT | tr -d ' ')

if [ "$COUNT" -gt "0" ]; then
    echo -e "${YELLOW}A tabela versiculos ja contem $COUNT registros.${NC}"
    read -p "Deseja limpar e reimportar? (s/N): " RESPONSE
    if [ "$RESPONSE" != "s" ] && [ "$RESPONSE" != "S" ]; then
        echo "Importacao cancelada."
        exit 0
    fi

    echo -e "${YELLOW}Limpando tabela versiculos...${NC}"
    docker exec bible-chat-postgres psql -U n8n -d n8n -c "TRUNCATE TABLE versiculos RESTART IDENTITY CASCADE;"
fi

echo ""
echo -e "${YELLOW}Convertendo e importando versiculos...${NC}"
echo -e "${YELLOW}Isso pode demorar alguns minutos...${NC}"
echo ""

# Criar script Python temporario para conversao
PYTHON_SCRIPT=$(cat << 'PYTHON_EOF'
import re
import sys

# Le o arquivo SQL
with open('/data/biblia.sql', 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Regex para extrair valores
pattern = r"\((\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*'((?:[^'\\]|\\.|'')*)'\)"
matches = re.findall(pattern, content)

print(f"-- Encontrados {len(matches)} versiculos", file=sys.stderr)
print("BEGIN;")

count = 0
for match in matches:
    ver_id, ver_vrs_id, ver_liv_id, ver_capitulo, ver_versiculo, ver_texto = match

    # Limpa o texto
    ver_texto = ver_texto.replace("\\'", "'")
    ver_texto = ver_texto.replace("''", "''")  # Escapa para PostgreSQL
    ver_texto = ver_texto.replace("'", "''")   # Escapa aspas simples
    ver_texto = ver_texto.replace("\\n", " ")
    ver_texto = ver_texto.replace("\\r", "")

    print(f"INSERT INTO versiculos (ver_liv_id, ver_capitulo, ver_versiculo, ver_texto) VALUES ({ver_liv_id}, {ver_capitulo}, {ver_versiculo}, E'{ver_texto}');")
    count += 1

    if count % 5000 == 0:
        print(f"-- Processados {count} versiculos", file=sys.stderr)

print("COMMIT;")
print(f"-- Total: {count} versiculos", file=sys.stderr)
PYTHON_EOF
)

# Executar Python dentro de um container temporario
docker run --rm \
    -v "$PROJECT_DIR/biblia_base_sql:/data:ro" \
    python:3.11-slim \
    python -c "$PYTHON_SCRIPT" 2>&1 | \
    docker exec -i bible-chat-postgres psql -U n8n -d n8n

echo ""
echo -e "${GREEN}Verificando importacao...${NC}"

# Verificar contagem final
FINAL_COUNT=$(docker exec bible-chat-postgres psql -U n8n -d n8n -t -c "SELECT COUNT(*) FROM versiculos;")
FINAL_COUNT=$(echo $FINAL_COUNT | tr -d ' ')

echo -e "${GREEN}Total de versiculos importados: $FINAL_COUNT${NC}"
echo ""

# Mostrar estatisticas
echo -e "${GREEN}Estatisticas:${NC}"
docker exec bible-chat-postgres psql -U n8n -d n8n -c "
SELECT
    t.tes_nome as testamento,
    COUNT(DISTINCT l.liv_id) as livros,
    COUNT(v.ver_id) as versiculos
FROM testamentos t
JOIN livros l ON t.tes_id = l.liv_tes_id
JOIN versiculos v ON l.liv_id = v.ver_liv_id
GROUP BY t.tes_nome
ORDER BY t.tes_id;
"

echo ""
echo -e "${GREEN}Testando busca...${NC}"
echo ""
echo "Busca por 'amor':"
docker exec bible-chat-postgres psql -U n8n -d n8n -c "SELECT * FROM buscar_versiculos('amor', 3);"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  IMPORTACAO CONCLUIDA COM SUCESSO!${NC}"
echo -e "${GREEN}============================================${NC}"
