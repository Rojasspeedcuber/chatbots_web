// ========================================
// VALIDACAO DE PARAMETROS DA REQUISICAO (CORRIGIDO)
// ========================================

const items = $input.all();
const results = [];

for (const item of items) {
  const data = item.json;

  // DEBUG: Log para ver o que está chegando
  console.log('Dados recebidos:', JSON.stringify(data, null, 2));

  // Tentar múltiplas formas de acessar o body
  let body = data.body || data.query || data;

  // Se body for string, fazer parse
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch (e) {
      console.log('Erro ao fazer parse do body:', e);
      body = data;
    }
  }

  // Se body não for objeto, usar data diretamente
  if (!body || typeof body !== 'object') {
    body = data;
  }

  // Extrair message (tentar vários campos possíveis)
  const message = body.message || body.msg || body.text ||
                  data.message || data.msg || data.text || '';

  console.log('Message extraída:', message);

  // Validar campo obrigatorio: message
  if (!message || typeof message !== 'string' || message.trim() === '') {
    throw new Error('VALIDATION_ERROR: Campo "message" e obrigatorio e deve ser uma string nao vazia. Recebido: ' + JSON.stringify(data));
  }

  // Extrair userId (tentar vários campos)
  const userIdRaw = body.userId || body.user_id || body.userid ||
                    data.userId || data.user_id || data.userid || '';

  // Validar userId (obrigatorio para sistema de assinatura)
  if (!userIdRaw || typeof userIdRaw !== 'string' || userIdRaw.trim() === '') {
    throw new Error('VALIDATION_ERROR: Campo "userId" e obrigatorio para verificacao de assinatura. Recebido: ' + JSON.stringify(data));
  }

  // Extrair email (enviado pelo frontend)
  const email = body.email || data.email || '';

  // Extrair sessionId
  const sessionId = body.sessionId || body.session_id ||
                    data.sessionId || data.session_id ||
                    `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // Limitar tamanho da mensagem
  const userMessage = message.trim().substring(0, 2000);

  results.push({
    json: {
      userMessage,
      sessionId,
      userId: userIdRaw.trim(),
      email: email.trim().toLowerCase(),
      timestamp: new Date().toISOString(),
      requestId: `req_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`
    }
  });
}

return results;
