# Bible AI Chat

Sistema completo de chatbot com IA para consultas bíblicas, integrado com sistema de assinaturas via Mercado Pago.

## Visão Geral

Este projeto implementa uma aplicação web que permite aos usuários fazer perguntas sobre a Bíblia e receber respostas contextualizadas geradas por IA. O sistema inclui:

- **Chat com IA** - Respostas baseadas em contexto bíblico usando OpenAI GPT
- **Sistema de Assinaturas** - Pagamentos recorrentes via Mercado Pago
- **Controle de Acesso** - Verificação de assinatura ativa antes de permitir uso
- **Backend n8n** - Automações e webhooks gerenciados pelo n8n
- **Frontend Responsivo** - Interface moderna com tema escuro

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND                                 │
│                    (nginx + HTML/CSS/JS)                        │
│         http://localhost / http://localhost/webhook/*           │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                           N8N                                    │
│                   (Backend de Automação)                        │
│                   http://localhost:5678                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ Chat Bible  │  │ Subscription│  │  Mercado Pago Webhook   │ │
│  │   /chat/    │  │  /create    │  │      /webhook/mp        │ │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘ │
└─────────┼────────────────┼─────────────────────┼────────────────┘
          │                │                     │
          ▼                ▼                     ▼
┌──────────────┐  ┌────────────────┐   ┌────────────────────┐
│   OpenAI     │  │  Mercado Pago  │   │    PostgreSQL      │
│   GPT API    │  │      API       │   │   (Persistência)   │
└──────────────┘  └────────────────┘   └────────────────────┘
```

## Stack Tecnológica

| Componente | Tecnologia | Versão |
|------------|------------|--------|
| Frontend | HTML5 + CSS3 + JavaScript | - |
| Web Server | Nginx | 1.27.3 |
| Backend/Automação | n8n | 1.73.1 |
| Banco de Dados | PostgreSQL | 16.6 |
| Cache | Redis | 7.4.2 |
| IA | OpenAI GPT-4o-mini | - |
| Pagamentos | Mercado Pago API | v1 |
| Container | Docker + Compose | V2 |

## Estrutura do Projeto

```
chatbots_web/
│
├── docker-compose.yml              # Orquestração dos containers
├── docker-compose.prod.yml         # Override para produção
├── Dockerfile.frontend             # Build do frontend nginx
├── Dockerfile.frontend.minified    # Build com minificação
│
├── .env.example                    # Template de variáveis de ambiente
├── .dockerignore                   # Arquivos excluídos do build
├── package.json                    # Scripts npm e dependências
│
├── nginx/
│   ├── nginx.conf                  # Configuração principal do nginx
│   └── default.conf                # Virtual host e proxy reverso
│
├── postgres/
│   └── init.sql                    # Schema inicial do banco
│
├── n8n/
│   └── workflows/                  # Workflows exportados
│
├── scripts/
│   ├── start.sh                    # Inicialização (Linux/Mac)
│   ├── start.ps1                   # Inicialização (Windows)
│   ├── stop.sh                     # Parada
│   ├── stop.ps1                    # Parada (Windows)
│   └── backup.sh                   # Backup do banco
│
├── frontend_complete.html          # Interface principal
├── test_frontend.html              # Interface de teste simples
│
├── n8n_bible_chatbot_flow.json                 # Fluxo: Chat básico
├── n8n_bible_chatbot_flow_with_subscription.json  # Fluxo: Chat + assinatura
├── n8n_subscription_create_flow.json           # Fluxo: Criar assinatura
├── n8n_subscription_status_flow.json           # Fluxo: Verificar status
├── n8n_mercadopago_webhook_flow.json           # Fluxo: Webhook MP
│
├── SETUP_INSTRUCTIONS.md           # Guia de configuração básica
├── SETUP_MERCADOPAGO.md            # Guia do Mercado Pago
├── DOCKER_DEPLOY.md                # Guia de deploy Docker
└── README.md                       # Este arquivo
```

## Pré-requisitos

- Docker 24.0+ e Docker Compose V2
- Conta OpenAI com API Key
- Conta Mercado Pago Developers com Access Token
- 2GB RAM mínimo (4GB recomendado)
- 10GB de espaço em disco

## Instalação Rápida

### 1. Clonar o Repositório

```bash
git clone <url-do-repositorio>
cd chatbots_web
```

### 2. Configurar Variáveis de Ambiente

```bash
cp .env.example .env
```

Edite o arquivo `.env` e configure:

```env
# Obrigatórias
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxx
MP_ACCESS_TOKEN=APP_USR-xxxxxxxxxxxx
POSTGRES_PASSWORD=sua_senha_segura

# Opcionais (ajuste conforme necessário)
TIMEZONE=America/Sao_Paulo
N8N_LOG_LEVEL=info
```

### 3. Iniciar os Serviços

**Windows (PowerShell):**
```powershell
.\scripts\start.ps1
```

**Linux/Mac:**
```bash
chmod +x scripts/*.sh
./scripts/start.sh
```

**Ou manualmente:**
```bash
docker compose up -d --build
```

### 4. Verificar Status

```bash
docker compose ps
docker compose logs -f
```

### 5. Acessar a Aplicação

| Serviço | URL |
|---------|-----|
| Frontend | http://localhost |
| n8n Admin | http://localhost:5678 |
| API Webhooks | http://localhost/webhook/* |

## Configuração do n8n

### Importar Workflows

1. Acesse http://localhost:5678
2. Crie uma conta de administrador (primeiro acesso)
3. Vá em **Settings** → **Import from file**
4. Importe os arquivos na ordem:
   - `n8n_subscription_create_flow.json`
   - `n8n_subscription_status_flow.json`
   - `n8n_mercadopago_webhook_flow.json`
   - `n8n_bible_chatbot_flow_with_subscription.json`

### Configurar Credenciais

**OpenAI:**
1. Settings → Credentials → Add Credential
2. Tipo: HTTP Header Auth
3. Name: `OpenAI API Key`
4. Header Name: `Authorization`
5. Header Value: `Bearer sk-proj-xxxx`

**Mercado Pago:**
1. Settings → Credentials → Add Credential
2. Tipo: HTTP Header Auth
3. Name: `Mercado Pago Access Token`
4. Header Name: `Authorization`
5. Header Value: `Bearer APP_USR-xxxx`

### Ativar Workflows

Ative todos os workflows importados (toggle verde no canto superior direito).

## Endpoints da API

### Chat com IA

```http
POST /webhook/chat/bible
Content-Type: application/json

{
  "message": "O que a Bíblia diz sobre amor?",
  "userId": "user-123",
  "sessionId": "session-opcional"
}
```

**Resposta (200 - Sucesso):**
```json
{
  "response": "O amor é um tema central nas Escrituras...",
  "status": "success",
  "metadata": {
    "requestId": "req_xxx",
    "tokensUsed": { "total": 450 },
    "subscription": { "status": "active" }
  }
}
```

**Resposta (402 - Assinatura Necessária):**
```json
{
  "status": "subscription_required",
  "error": {
    "type": "SUBSCRIPTION_REQUIRED",
    "message": "Para usar o chat, você precisa de uma assinatura ativa."
  },
  "subscription": {
    "subscriptionLink": "https://...",
    "plans": [...]
  }
}
```

### Criar Assinatura

```http
POST /webhook/subscription/create
Content-Type: application/json

{
  "userId": "user-123",
  "email": "usuario@email.com",
  "planId": "monthly"
}
```

**Resposta:**
```json
{
  "success": true,
  "data": {
    "subscriptionId": "2c938084xxx",
    "status": "pending",
    "paymentLink": "https://www.mercadopago.com.br/..."
  }
}
```

### Verificar Status da Assinatura

```http
GET /webhook/subscription/status/{userId}
```

**Resposta:**
```json
{
  "success": true,
  "data": {
    "hasSubscription": true,
    "isActive": true,
    "status": "active",
    "daysUntilPayment": 15
  }
}
```

### Webhook Mercado Pago

```http
POST /webhook/webhook/mercadopago
```

Recebe notificações automáticas do Mercado Pago sobre mudanças de status.

## Planos de Assinatura

| Plano | Preço | Frequência |
|-------|-------|------------|
| Mensal | R$ 19,90 | 1 mês |
| Trimestral | R$ 49,90 | 3 meses |
| Anual | R$ 149,90 | 12 meses |

## Deploy em Produção

### Usando Docker Compose

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Configurações de Produção

1. **Altere TODAS as senhas** no `.env`
2. Configure `WEBHOOK_URL` com seu domínio real
3. Configure SSL/HTTPS (Traefik, Caddy ou nginx externo)
4. Ative `N8N_PROTOCOL=https`
5. Configure firewall (apenas porta 80/443 pública)

### Backup

```bash
./scripts/backup.sh
```

Arquivos salvos em `./backups/`:
- `backup_YYYYMMDD_postgres.sql.gz` - Dump do banco
- `backup_YYYYMMDD_n8n.tar.gz` - Dados do n8n

## Comandos Úteis

```bash
# Ver logs em tempo real
docker compose logs -f

# Logs de serviço específico
docker compose logs -f n8n

# Reiniciar serviços
docker compose restart

# Parar tudo
docker compose down

# Parar e remover volumes (CUIDADO: apaga dados)
docker compose down -v

# Reconstruir imagens
docker compose build --no-cache

# Atualizar imagens
docker compose pull
docker compose up -d
```

## Estrutura do Banco de Dados

### Tabela: subscriptions
```sql
- id (UUID)
- user_id (VARCHAR) - Identificador único do usuário
- email (VARCHAR)
- mp_subscription_id (VARCHAR) - ID no Mercado Pago
- plan_id (VARCHAR) - monthly/quarterly/yearly
- status (VARCHAR) - pending/active/paused/cancelled
- amount (DECIMAL)
- next_payment_date (TIMESTAMP)
- created_at, updated_at (TIMESTAMP)
```

### Tabela: chat_logs
```sql
- id (UUID)
- user_id, session_id (VARCHAR)
- user_message, ai_response (TEXT)
- tokens_total (INTEGER)
- subscription_status (VARCHAR)
- created_at (TIMESTAMP)
```

### Tabela: webhook_logs
```sql
- id (UUID)
- event_type, topic (VARCHAR)
- resource_id, user_id (VARCHAR)
- raw_data (JSONB)
- created_at (TIMESTAMP)
```

## Troubleshooting

### Container não inicia

```bash
# Ver logs detalhados
docker compose logs n8n

# Verificar recursos
docker stats

# Reiniciar Docker
docker compose down && docker compose up -d
```

### Erro de conexão com banco

```bash
# Verificar se PostgreSQL está rodando
docker compose ps postgres

# Testar conexão
docker compose exec postgres psql -U n8n -d n8n -c "SELECT 1"
```

### Webhook não funciona

1. Verifique se o n8n está healthy: `docker compose ps`
2. Teste direto: `curl http://localhost:5678/healthz`
3. Verifique se o workflow está ativo no n8n
4. Confira os logs: `docker compose logs n8n`

### Erro 402 mesmo com assinatura

1. Verifique se `userId` está correto
2. Confirme status no painel do Mercado Pago
3. Force reprocessamento via webhook de teste

## Segurança

### Checklist de Produção

- [ ] Senhas fortes e únicas em `.env`
- [ ] SSL/HTTPS configurado
- [ ] Firewall ativo (apenas 80/443 públicas)
- [ ] Backups automáticos configurados
- [ ] Monitoramento de logs ativo
- [ ] Rate limiting no nginx
- [ ] Variáveis sensíveis não expostas

### Portas

| Porta | Serviço | Exposição |
|-------|---------|-----------|
| 80 | Frontend | Pública |
| 5678 | n8n | Interna/Admin |
| 5432 | PostgreSQL | Interna |
| 6379 | Redis | Interna |

## Contribuição

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit: `git commit -m 'Adiciona nova funcionalidade'`
4. Push: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## Suporte

- **Documentação n8n:** https://docs.n8n.io
- **API OpenAI:** https://platform.openai.com/docs
- **Mercado Pago Developers:** https://www.mercadopago.com.br/developers
- **Docker:** https://docs.docker.com

---

Desenvolvido com n8n, OpenAI e Mercado Pago.
