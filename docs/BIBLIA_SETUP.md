# Configuracao da Base da Biblia

Este guia explica como configurar a base de dados da Biblia para o chatbot.

## Arquitetura

O chatbot agora usa uma base SQL com todos os versiculos da Biblia:

```
Pergunta do Usuario
        |
        v
  [Extrair Termos]
        |
   /----+----\
   |         |
   v         v
[Busca    [Busca por
 Texto]    Referencia]
   |         |
   \----+----/
        |
        v
[Combinar Resultados]
        |
        v
[Prompt + Contexto Biblico]
        |
        v
    [OpenAI]
        |
        v
    Resposta
```

## Pre-requisitos

1. Docker e Docker Compose instalados
2. Python 3.8+ (para importacao dos dados)
3. Biblioteca psycopg2:
   ```bash
   pip install psycopg2-binary
   ```

## Passo 1: Iniciar os Containers

```bash
cd chatbots_web
docker compose up -d
```

Aguarde o PostgreSQL iniciar completamente (cerca de 30 segundos).

## Passo 2: Importar os Dados da Biblia

O schema das tabelas e criado automaticamente. Agora importe os versiculos:

```bash
# Defina as variaveis de ambiente (opcional se usar defaults)
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DB=n8n
export POSTGRES_USER=n8n
export POSTGRES_PASSWORD=n8n_secure_password_2025

# Execute o script de importacao
python scripts/import_biblia.py
```

O script ira:
- Ler o arquivo `biblia_base_sql/biblia.sql`
- Extrair todos os versiculos (aproximadamente 31.000)
- Inserir no PostgreSQL
- Testar a funcao de busca

## Passo 3: Configurar Credenciais no n8n

1. Acesse o n8n: http://localhost:5678

2. Crie uma credencial **PostgreSQL**:
   - Name: `PostgreSQL Bible DB`
   - Host: `postgres` (nome do container)
   - Port: `5432`
   - Database: `n8n`
   - User: `n8n`
   - Password: `n8n_secure_password_2025`

3. Crie uma credencial **HTTP Header Auth** para OpenAI:
   - Name: `OpenAI API Key`
   - Header Name: `Authorization`
   - Header Value: `Bearer sk-sua-chave-aqui`

4. Importe o workflow:
   - Va em "Workflows" > "Import from File"
   - Selecione: `n8n/workflows/n8n_bible_chatbot_flow.json`

5. Atualize as credenciais nos nodes:
   - `Buscar na Biblia (PostgreSQL)` -> selecione `PostgreSQL Bible DB`
   - `Buscar por Referencia` -> selecione `PostgreSQL Bible DB`
   - `Chamar OpenAI API` -> selecione `OpenAI API Key`

6. Ative o workflow

## Testando

### Via cURL

```bash
curl -X POST http://localhost:5678/webhook/chat/bible \
  -H "Content-Type: application/json" \
  -d '{
    "message": "O que diz Joao 3:16?",
    "userId": "test-user"
  }'
```

### Via Frontend

Abra `frontend_complete.html` no navegador e configure a URL da API.

## Funcionalidades de Busca

### 1. Busca por Referencia
O chatbot detecta referencias biblicas como:
- `Joao 3:16`
- `Genesis 1:1-10`
- `Salmos 23`
- `1 Corintios 13`

### 2. Busca por Texto (Full-Text Search)
Busca palavras-chave nos versiculos:
- "amor" -> versiculos sobre amor
- "fe esperanca" -> versiculos com essas palavras
- "perdao" -> versiculos sobre perdao

### 3. Busca Combinada
O sistema combina ambas as buscas para dar o melhor contexto a IA.

## Queries Uteis

### Testar busca por texto
```sql
SELECT * FROM buscar_versiculos('amor', 10);
```

### Testar busca por referencia
```sql
SELECT * FROM buscar_por_referencia('Joao', 3, 16);
```

### Ver estatisticas
```sql
SELECT * FROM biblia_estatisticas;
```

### Contar versiculos
```sql
SELECT COUNT(*) FROM versiculos;
-- Esperado: ~31.102 versiculos
```

## Estrutura do Banco

### Tabela: testamentos
| Campo    | Tipo        | Descricao        |
|----------|-------------|------------------|
| tes_id   | SMALLINT PK | ID do testamento |
| tes_nome | VARCHAR(30) | Nome             |

### Tabela: livros
| Campo       | Tipo        | Descricao            |
|-------------|-------------|----------------------|
| liv_id      | SMALLINT PK | ID do livro          |
| liv_tes_id  | SMALLINT FK | ID do testamento     |
| liv_posicao | SMALLINT    | Ordem no testamento  |
| liv_nome    | VARCHAR(30) | Nome do livro        |

### Tabela: versiculos
| Campo         | Tipo        | Descricao           |
|---------------|-------------|---------------------|
| ver_id        | SERIAL PK   | ID do versiculo     |
| ver_liv_id    | SMALLINT FK | ID do livro         |
| ver_capitulo  | SMALLINT    | Numero do capitulo  |
| ver_versiculo | SMALLINT    | Numero do versiculo |
| ver_texto     | TEXT        | Texto do versiculo  |

## Troubleshooting

### Erro: "relation versiculos does not exist"
O schema nao foi criado. Recrie o container do PostgreSQL:
```bash
docker compose down
docker volume rm bible-chat-postgres-data
docker compose up -d
```

### Erro: "connection refused"
O PostgreSQL ainda nao esta pronto. Aguarde alguns segundos e tente novamente.

### Importacao lenta
O arquivo SQL tem ~31.000 versiculos. A importacao pode levar de 1 a 5 minutos dependendo do hardware.

### Credencial PostgreSQL nao conecta
- Use `postgres` como host (nao `localhost`)
- Verifique se o container esta rodando: `docker compose ps`
