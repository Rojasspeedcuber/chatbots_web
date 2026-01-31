# Sistema de Pagamentos Mercado Pago - Guia Completo

## Visao Geral da Arquitetura

```
+------------------+     +---------------------+     +------------------+
|    Frontend      |     |        n8n          |     |   Mercado Pago   |
|                  |     |                     |     |                  |
| - Login/Register +---->+ /chat/bible         |     |                  |
| - Chat Interface |     |   (verifica assin.) |     |                  |
| - Subscription   +---->+ /subscription/create+---->+ Preapproval API  |
| - Payment Status |     |                     |     |                  |
|                  |<----+ /subscription/status|     |                  |
|                  |     |                     |<----+ Webhooks         |
+------------------+     +---------------------+     +------------------+
```

## Fluxos n8n Criados

| Arquivo | Descricao | Endpoint |
|---------|-----------|----------|
| `n8n_subscription_create_flow.json` | Criar assinatura | POST /subscription/create |
| `n8n_mercadopago_webhook_flow.json` | Receber webhooks MP | POST /webhook/mercadopago |
| `n8n_subscription_status_flow.json` | Verificar status | GET /subscription/status/:userId |
| `n8n_bible_chatbot_flow_with_subscription.json` | Chat com verificacao | POST /chat/bible |

---

## Passo 1: Configurar Mercado Pago

### 1.1 Obter Credenciais

1. Acesse [Mercado Pago Developers](https://www.mercadopago.com.br/developers)
2. Crie uma aplicacao ou use existente
3. Copie as credenciais:
   - **Access Token** (producao): `APP_USR-xxx`
   - **Access Token** (sandbox): `TEST-xxx`

### 1.2 Configurar Webhooks no MP

1. Va em: Sua conta > Configuracoes > Notificacoes > Webhooks
2. Adicione URL: `https://seu-n8n.easypanel.host/webhook/webhook/mercadopago`
3. Selecione eventos:
   - [x] Preapproval (assinaturas)
   - [x] Payment (opcional)

---

## Passo 2: Configurar n8n

### 2.1 Criar Credencial Mercado Pago

1. Va em **Settings** > **Credentials**
2. Clique **Add Credential** > **HTTP Header Auth**
3. Configure:
   - **Name**: `Mercado Pago Access Token`
   - **Header Name**: `Authorization`
   - **Header Value**: `Bearer APP_USR-xxx` (seu Access Token)
4. Salve

### 2.2 Importar Fluxos

Importe na ordem:

1. `n8n_subscription_create_flow.json`
2. `n8n_mercadopago_webhook_flow.json`
3. `n8n_subscription_status_flow.json`
4. `n8n_bible_chatbot_flow_with_subscription.json`

### 2.3 Vincular Credenciais

Em cada fluxo, vincule a credencial aos nodes HTTP Request:

- **Criar Assinatura**: node "Criar Preapproval MP"
- **Webhook MP**: node "Buscar Detalhes Assinatura"
- **Chat Bible**: node "Chamar OpenAI API" (credencial OpenAI)

### 2.4 Ativar Fluxos

Ative todos os fluxos (toggle verde no canto superior direito).

---

## Passo 3: Variaveis de Ambiente (EasyPanel)

Adicione ao servico n8n:

```env
# Mercado Pago
MP_ACCESS_TOKEN=APP_USR-xxxxxxxxxxxx

# OpenAI
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxx

# n8n
N8N_WEBHOOK_URL=https://seu-n8n.easypanel.host

# Opcional
N8N_LOG_LEVEL=info
```

---

## Endpoints da API

### 1. Criar Assinatura

```http
POST /webhook/subscription/create
Content-Type: application/json

{
  "userId": "user-123",
  "email": "usuario@email.com",
  "planId": "monthly"
}
```

**Resposta (201):**
```json
{
  "success": true,
  "message": "Assinatura criada com sucesso",
  "data": {
    "subscriptionId": "2c938084xxxx",
    "status": "pending",
    "paymentLink": "https://www.mercadopago.com.br/subscriptions/checkout?preapproval_id=xxx"
  }
}
```

### 2. Verificar Status

```http
GET /webhook/subscription/status/user-123
```

**Resposta (200):**
```json
{
  "success": true,
  "data": {
    "userId": "user-123",
    "hasSubscription": true,
    "isActive": true,
    "status": "active",
    "daysUntilPayment": 15,
    "plan": {
      "id": "monthly",
      "name": "Plano Mensal",
      "amount": 19.90
    }
  }
}
```

### 3. Chat com Assinatura

```http
POST /webhook/chat/bible
Content-Type: application/json

{
  "message": "O que a Biblia diz sobre fe?",
  "userId": "user-123",
  "sessionId": "session-opcional"
}
```

**Resposta com assinatura (200):**
```json
{
  "response": "A fe e um tema central nas Escrituras...",
  "status": "success",
  "metadata": {
    "subscription": {
      "status": "active",
      "accessReason": "active_subscription"
    }
  }
}
```

**Resposta sem assinatura (402):**
```json
{
  "status": "subscription_required",
  "error": {
    "type": "SUBSCRIPTION_REQUIRED",
    "message": "Para usar o Bible AI Chat, voce precisa de uma assinatura ativa.",
    "code": 402
  },
  "subscription": {
    "required": true,
    "subscriptionLink": "https://seu-site.com/assinar",
    "plans": [
      { "id": "monthly", "name": "Mensal", "price": "R$ 19,90/mes" }
    ]
  }
}
```

### 4. Webhook Mercado Pago

```http
POST /webhook/webhook/mercadopago
```

Recebe notificacoes automaticas do Mercado Pago.

---

## Planos Disponiveis

| ID | Nome | Preco | Frequencia |
|----|------|-------|------------|
| monthly | Plano Mensal | R$ 19,90 | 1 mes |
| quarterly | Plano Trimestral | R$ 49,90 | 3 meses |
| yearly | Plano Anual | R$ 149,90 | 12 meses |

---

## Fluxo de Assinatura

```
1. Usuario acessa frontend
2. Escolhe plano e clica "Assinar"
3. Frontend chama POST /subscription/create
4. n8n cria preapproval no Mercado Pago
5. Retorna link de pagamento
6. Usuario e redirecionado para pagamento
7. Apos pagamento, MP envia webhook
8. n8n atualiza status do usuario
9. Usuario pode usar o chat
```

---

## Status de Assinatura

| Status MP | Status Interno | Acesso |
|-----------|----------------|--------|
| pending | pending | Negado |
| authorized | active | Permitido |
| paused | paused | Negado |
| cancelled | cancelled | Negado |
| finished | finished | Negado |

---

## Free Tier (Opcional)

O fluxo de chat suporta um tier gratuito limitado.

Para habilitar, edite o node "Verificar Assinatura":

```javascript
const FREE_TIER_ENABLED = true;  // Altere para true
const FREE_TIER_DAILY_LIMIT = 3; // Mensagens gratuitas por dia
```

---

## Persistencia de Dados

### Modo Atual: Static Data

Os fluxos usam `$getWorkflowStaticData('global')` para persistencia.

**Limitacoes:**
- Dados em memoria
- Perdidos ao reiniciar n8n
- Bom para MVP/testes

### Para Producao

Substitua os nodes de persistencia por banco de dados:

**PostgreSQL:**
```sql
CREATE TABLE subscriptions (
  user_id VARCHAR(255) PRIMARY KEY,
  subscription_id VARCHAR(255),
  email VARCHAR(255),
  status VARCHAR(50),
  plan_id VARCHAR(50),
  amount DECIMAL(10,2),
  next_payment_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Supabase/Firebase:**
Adicione nodes nativos do n8n para essas plataformas.

---

## Seguranca

### Validacao de Webhook

O Mercado Pago envia um header `x-signature` para validar a origem.

Para implementar verificacao (opcional mas recomendado):

```javascript
const crypto = require('crypto');
const signature = headers['x-signature'];
const secret = process.env.MP_WEBHOOK_SECRET;

// Validar assinatura HMAC
const expectedSignature = crypto
  .createHmac('sha256', secret)
  .update(JSON.stringify(body))
  .digest('hex');

if (signature !== expectedSignature) {
  throw new Error('Invalid webhook signature');
}
```

### Boas Praticas

1. Use HTTPS em todos os endpoints
2. Nao exponha Access Token no frontend
3. Valide userId no backend
4. Implemente rate limiting
5. Monitore webhooks duplicados (idempotencia)

---

## Troubleshooting

### Webhook nao recebe notificacoes

1. Verifique URL no painel do Mercado Pago
2. Confirme que o fluxo esta ativo
3. Teste com ngrok localmente

### Erro 401 no Mercado Pago

1. Verifique Access Token
2. Confirme ambiente (sandbox vs producao)
3. Verifique permissoes da aplicacao

### Assinatura nao atualiza

1. Verifique logs do webhook
2. Confirme external_reference = userId
3. Verifique staticData no n8n

### Chat retorna 402 mesmo com assinatura

1. Verifique se userId esta correto
2. Confirme status da assinatura no MP
3. Force webhook de teste no painel MP

---

## Teste em Sandbox

1. Use Access Token de teste (`TEST-xxx`)
2. Use cartoes de teste do Mercado Pago:
   - **Aprovado**: 5031 4332 1540 6351 (CVV: 123)
   - **Recusado**: 4000 0000 0000 0002
3. Configure `sandbox_init_point` no frontend

---

## Links Uteis

- [Documentacao Preapproval MP](https://www.mercadopago.com.br/developers/pt/docs/subscriptions)
- [Webhooks MP](https://www.mercadopago.com.br/developers/pt/docs/your-integrations/notifications/webhooks)
- [Cartoes de Teste](https://www.mercadopago.com.br/developers/pt/docs/checkout-api/additional-content/your-integrations/test/cards)
- [Documentacao n8n](https://docs.n8n.io)
