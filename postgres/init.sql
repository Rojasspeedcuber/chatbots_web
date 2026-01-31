-- ============================================
-- SCRIPT DE INICIALIZACAO - PostgreSQL
-- Bible AI Chat - Sistema de Assinaturas
-- ============================================

-- Criar extensoes uteis
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================
-- TABELA: subscriptions (assinaturas)
-- ============================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    mp_subscription_id VARCHAR(255),
    plan_id VARCHAR(50) DEFAULT 'monthly',
    plan_name VARCHAR(100) DEFAULT 'Plano Mensal',
    amount DECIMAL(10, 2) DEFAULT 19.90,
    currency VARCHAR(10) DEFAULT 'BRL',
    status VARCHAR(50) DEFAULT 'pending',
    mp_status VARCHAR(50),
    init_point TEXT,
    next_payment_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indices para performance
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_email ON subscriptions(email);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_mp_subscription_id ON subscriptions(mp_subscription_id);

-- ============================================
-- TABELA: webhook_logs (logs de webhooks MP)
-- ============================================
CREATE TABLE IF NOT EXISTS webhook_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    webhook_id VARCHAR(255),
    event_type VARCHAR(100),
    topic VARCHAR(100),
    resource_id VARCHAR(255),
    user_id VARCHAR(255),
    status VARCHAR(50),
    raw_data JSONB,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_webhook_logs_user_id ON webhook_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_event_type ON webhook_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_created_at ON webhook_logs(created_at DESC);

-- ============================================
-- TABELA: chat_logs (logs de conversas)
-- ============================================
CREATE TABLE IF NOT EXISTS chat_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id VARCHAR(255),
    session_id VARCHAR(255),
    user_id VARCHAR(255),
    user_message TEXT,
    ai_response TEXT,
    model VARCHAR(100),
    tokens_prompt INTEGER DEFAULT 0,
    tokens_completion INTEGER DEFAULT 0,
    tokens_total INTEGER DEFAULT 0,
    subscription_status VARCHAR(50),
    access_reason VARCHAR(50),
    response_time_ms INTEGER,
    status VARCHAR(50) DEFAULT 'success',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_chat_logs_user_id ON chat_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_logs_session_id ON chat_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_logs_created_at ON chat_logs(created_at DESC);

-- ============================================
-- TABELA: free_tier_usage (uso gratuito)
-- ============================================
CREATE TABLE IF NOT EXISTS free_tier_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255) NOT NULL,
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    message_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, usage_date)
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_free_tier_user_date ON free_tier_usage(user_id, usage_date);

-- ============================================
-- FUNCAO: Atualizar updated_at automaticamente
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_free_tier_updated_at ON free_tier_usage;
CREATE TRIGGER update_free_tier_updated_at
    BEFORE UPDATE ON free_tier_usage
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS UTEIS
-- ============================================

-- View: Assinaturas ativas
CREATE OR REPLACE VIEW active_subscriptions AS
SELECT
    user_id,
    email,
    plan_name,
    amount,
    status,
    next_payment_date,
    created_at
FROM subscriptions
WHERE status IN ('active', 'authorized');

-- View: Metricas diarias de chat
CREATE OR REPLACE VIEW daily_chat_metrics AS
SELECT
    DATE(created_at) as date,
    COUNT(*) as total_messages,
    COUNT(DISTINCT user_id) as unique_users,
    SUM(tokens_total) as total_tokens,
    AVG(response_time_ms) as avg_response_time_ms
FROM chat_logs
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- ============================================
-- DADOS INICIAIS (opcional)
-- ============================================

-- Comentado: Descomente para inserir dados de teste
-- INSERT INTO subscriptions (user_id, email, status, plan_id)
-- VALUES ('test_user_001', 'teste@exemplo.com', 'active', 'monthly')
-- ON CONFLICT (user_id) DO NOTHING;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
-- O usuario n8n precisa de permissoes completas
-- (ja configurado via POSTGRES_USER no docker-compose)

COMMENT ON TABLE subscriptions IS 'Tabela de assinaturas de usuarios';
COMMENT ON TABLE webhook_logs IS 'Logs de webhooks do Mercado Pago';
COMMENT ON TABLE chat_logs IS 'Logs de conversas do chat';
COMMENT ON TABLE free_tier_usage IS 'Controle de uso do tier gratuito';
