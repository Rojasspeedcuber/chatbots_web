# Bible AI Chatbot - Guia de Configuracao n8n no EasyPanel

## Visao Geral

Este fluxo n8n implementa uma API REST para um chatbot biblico com IA, adaptado do projeto ChatbotwppBibleIA para web.

## Arquivos Gerados

- `n8n_bible_chatbot_flow.json` - Fluxo principal do n8n (importar diretamente)

---

## Passo 1: Importar o Fluxo no n8n

1. Acesse seu n8n no EasyPanel
2. Va em **Workflows** > **Add Workflow**
3. Clique nos 3 pontos (...) > **Import from File**
4. Selecione `n8n_bible_chatbot_flow.json`
5. Clique em **Save**

---

## Passo 2: Configurar Credenciais OpenAI

### Criar Credencial HTTP Header Auth

1. Va em **Settings** > **Credentials**
2. Clique em **Add Credential**
3. Selecione **HTTP Header Auth**
4. Configure:
   - **Name**: `OpenAI API Key`
   - **Header Name**: `Authorization`
   - **Header Value**: `Bearer sk-YOUR-OPENAI-API-KEY`
5. Clique em **Save**

### Vincular ao Node

1. Abra o fluxo importado
2. Clique no node **Chamar OpenAI API**
3. Em **Credentials**, selecione a credencial criada
4. Salve o fluxo

---

## Passo 3: Variaveis de Ambiente no EasyPanel

No painel do EasyPanel, adicione estas variaveis ao servico n8n:

```env
# Chave da API OpenAI (obrigatorio)
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxx

# URL base do webhook (ajustar conforme seu dominio)
N8N_WEBHOOK_URL=https://seu-n8n.easypanel.host

# Configuracoes opcionais
N8N_LOG_LEVEL=info
N8N_METRICS=true
```

---

## Passo 4: Ativar o Fluxo

1. Abra o fluxo no n8n
2. Clique no toggle **Active** no canto superior direito
3. O webhook estara disponivel em:
   ```
   https://seu-n8n.easypanel.host/webhook/chat/bible
   ```

---

## Endpoint da API

### URL
```
POST https://seu-n8n.easypanel.host/webhook/chat/bible
```

### Headers
```
Content-Type: application/json
```

### Body (JSON)
```json
{
  "message": "O que a Biblia diz sobre perdao?",
  "sessionId": "opcional-id-unico-sessao",
  "userId": "opcional-id-usuario"
}
```

### Resposta de Sucesso (200)
```json
{
  "response": "O perdao e um tema central nas Escrituras...",
  "status": "success",
  "metadata": {
    "requestId": "req_1234567890_abc123",
    "sessionId": "session_1234567890_xyz789",
    "userId": "anonymous",
    "timestamp": "2024-01-15T10:30:00.000Z",
    "responseTimestamp": "2024-01-15T10:30:05.000Z",
    "model": "gpt-4o-mini",
    "tokensUsed": {
      "prompt": 450,
      "completion": 320,
      "total": 770
    }
  }
}
```

### Resposta de Erro (4xx/5xx)
```json
{
  "response": null,
  "status": "error",
  "error": {
    "type": "VALIDATION_ERROR",
    "message": "Campo 'message' e obrigatorio",
    "code": 400,
    "timestamp": "2024-01-15T10:30:00.000Z"
  }
}
```

---

## Exemplo de Uso com cURL

```bash
curl -X POST https://seu-n8n.easypanel.host/webhook/chat/bible \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Qual o significado de Joao 3:16?",
    "sessionId": "minha-sessao-123"
  }'
```

---

## Exemplo de Uso com JavaScript (Frontend)

```javascript
async function sendMessage(message, sessionId) {
  const response = await fetch('https://seu-n8n.easypanel.host/webhook/chat/bible', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message,
      sessionId,
    }),
  });

  const data = await response.json();

  if (data.status === 'success') {
    return data.response;
  } else {
    throw new Error(data.error.message);
  }
}

// Uso
sendMessage('O que a Biblia diz sobre fe?', 'sessao-001')
  .then(resposta => console.log(resposta))
  .catch(erro => console.error(erro));
```

---

## Configuracao Alternativa: Anthropic Claude

Para usar Claude em vez de OpenAI:

### 1. Criar Credencial Anthropic

1. Va em **Settings** > **Credentials**
2. Clique em **Add Credential**
3. Selecione **HTTP Header Auth**
4. Configure:
   - **Name**: `Anthropic API Key`
   - **Header Name**: `x-api-key`
   - **Header Value**: `sk-ant-YOUR-ANTHROPIC-KEY`

### 2. Modificar Node HTTP Request

Altere o node **Chamar OpenAI API**:

**URL:**
```
https://api.anthropic.com/v1/messages
```

**Headers adicionais:**
```
anthropic-version: 2023-06-01
```

**Body:**
```json
{
  "model": "claude-3-sonnet-20240229",
  "max_tokens": 1500,
  "messages": [
    {"role": "user", "content": "..."}
  ],
  "system": "Voce e um assistente biblico..."
}
```

### 3. Ajustar Node Processar Resposta

Altere para extrair `content[0].text` em vez de `choices[0].message.content`.

---

## Persistencia de Logs (Opcional)

### Opcao 1: PostgreSQL

Adicione um node **PostgreSQL** apos o node "Log Interacao":

```sql
INSERT INTO chat_logs (request_id, session_id, user_id, message, response, tokens, created_at)
VALUES ($1, $2, $3, $4, $5, $6, NOW())
```

### Opcao 2: MongoDB

Adicione um node **MongoDB** para inserir documentos na collection `chat_logs`.

### Opcao 3: Arquivo JSON

Adicione um node **Write Binary File** para salvar em `/data/logs/chat_log.jsonl`.

---

## Troubleshooting

### Erro 401 - Unauthorized
- Verifique se a chave da API esta correta
- Confirme que o header `Authorization` tem o prefixo `Bearer `

### Erro 429 - Rate Limit
- Aguarde alguns segundos e tente novamente
- Considere implementar retry com backoff

### Erro 502 - Bad Gateway
- Servico de IA indisponivel
- Verifique status da OpenAI/Anthropic

### Webhook nao responde
- Verifique se o fluxo esta ativo (toggle verde)
- Confirme a URL do webhook no n8n

---

## Seguranca Recomendada

1. **CORS**: Configure allowed origins no webhook
2. **Rate Limiting**: Implemente no proxy/Nginx
3. **API Key propria**: Adicione autenticacao no webhook
4. **HTTPS**: Sempre use conexao segura

---

## Suporte

- Projeto original: https://github.com/Rojasspeedcuber/ChatbotwppBibleIA
- Documentacao n8n: https://docs.n8n.io
- OpenAI API: https://platform.openai.com/docs
