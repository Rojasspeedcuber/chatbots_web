# Guia de Deploy com Docker - Bible AI Chat

## Requisitos

- Docker 24.0+ (recomendado: 25.x ou 26.x)
- Docker Compose V2 (incluido no Docker Desktop)
- 2GB RAM minimo (4GB recomendado)
- 10GB disco livre

## Versoes das Imagens

| Servico | Imagem | Versao |
|---------|--------|--------|
| Frontend | nginx | 1.27.3-alpine3.20 |
| n8n | n8nio/n8n | 1.73.1 |
| PostgreSQL | postgres | 16.6-alpine3.21 |
| Redis | redis | 7.4.2-alpine3.21 |

## Estrutura de Arquivos

```
chatbots_web/
├── docker-compose.yml          # Compose principal
├── docker-compose.prod.yml     # Override para producao
├── Dockerfile.frontend         # Build do frontend
├── .env.example               # Variaveis de ambiente (exemplo)
├── .env                       # Variaveis de ambiente (criar)
├── .dockerignore              # Arquivos ignorados no build
├── nginx/
│   ├── nginx.conf             # Config principal nginx
│   └── default.conf           # Config do site
├── postgres/
│   └── init.sql               # Script de inicializacao do banco
├── n8n/
│   └── workflows/             # Workflows n8n (JSONs)
├── scripts/
│   ├── start.sh               # Script de inicializacao
│   ├── stop.sh                # Script de parada
│   └── backup.sh              # Script de backup
└── frontend_complete.html     # Frontend principal
```

## Deploy Rapido

### 1. Configurar variaveis de ambiente

```bash
cp .env.example .env
nano .env  # ou seu editor preferido
```

Configure obrigatoriamente:
- `OPENAI_API_KEY`: Sua chave da OpenAI
- `MP_ACCESS_TOKEN`: Seu token do Mercado Pago
- `POSTGRES_PASSWORD`: Senha segura para o banco

### 2. Iniciar servicos

```bash
# Dar permissao aos scripts (Linux/Mac)
chmod +x scripts/*.sh

# Iniciar
./scripts/start.sh

# Ou manualmente:
docker compose up -d --build
```

### 3. Verificar status

```bash
docker compose ps
docker compose logs -f
```

### 4. Acessar

- Frontend: http://localhost
- n8n Admin: http://localhost:5678
- API Webhooks: http://localhost/webhook/

## Deploy em Producao

### Usar docker-compose.prod.yml

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Configuracoes de producao

1. **Altere TODAS as senhas** no `.env`
2. Configure `WEBHOOK_URL` com seu dominio real
3. Configure SSL/HTTPS (use Traefik, Caddy ou nginx externo)
4. Ative `N8N_PROTOCOL=https`

## Comandos Uteis

### Logs

```bash
# Todos os servicos
docker compose logs -f

# Servico especifico
docker compose logs -f n8n
docker compose logs -f postgres
```

### Reiniciar

```bash
# Todos
docker compose restart

# Servico especifico
docker compose restart n8n
```

### Atualizar imagens

```bash
# Parar servicos
docker compose down

# Puxar novas imagens
docker compose pull

# Reconstruir e iniciar
docker compose up -d --build
```

### Backup

```bash
./scripts/backup.sh
```

### Limpar tudo (CUIDADO)

```bash
# Para e remove containers, redes
docker compose down

# Remove tambem volumes (APAGA DADOS!)
docker compose down -v
```

## Importar Workflows n8n

1. Acesse http://localhost:5678
2. Crie uma conta admin
3. Va em Settings > Import from file
4. Importe os arquivos:
   - `n8n_bible_chatbot_flow_with_subscription.json`
   - `n8n_subscription_create_flow.json`
   - `n8n_subscription_status_flow.json`
   - `n8n_mercadopago_webhook_flow.json`

5. Configure as credenciais:
   - HTTP Header Auth para OpenAI
   - HTTP Header Auth para Mercado Pago

6. Ative os workflows

## Troubleshooting

### Container nao inicia

```bash
# Ver logs detalhados
docker compose logs n8n

# Verificar recursos
docker stats
```

### Erro de conexao com banco

```bash
# Verificar se postgres esta rodando
docker compose ps postgres

# Ver logs do postgres
docker compose logs postgres

# Testar conexao
docker compose exec postgres psql -U n8n -d n8n -c "SELECT 1"
```

### Webhook nao funciona

1. Verifique se n8n esta healthy: `docker compose ps`
2. Verifique logs: `docker compose logs n8n`
3. Teste direto: `curl http://localhost:5678/healthz`
4. Verifique nginx: `docker compose logs frontend`

### Permissao negada (Linux)

```bash
# Ajustar permissoes do volume n8n
sudo chown -R 1000:1000 ./n8n
```

## Monitoramento

### Health checks

```bash
# Status dos containers
docker compose ps

# Health individual
docker inspect bible-chat-n8n --format='{{.State.Health.Status}}'
```

### Metricas n8n

Acesse: http://localhost:5678/metrics (se habilitado)

### Logs estruturados

Em producao, os logs sao JSON. Use ferramentas como:
- Loki + Grafana
- ELK Stack
- Datadog

## Seguranca

### Checklist de producao

- [ ] Senhas fortes em `.env`
- [ ] SSL/HTTPS configurado
- [ ] Firewall configurado
- [ ] Backups automatizados
- [ ] Monitoramento ativo
- [ ] Rate limiting ativo (nginx)
- [ ] Logs centralizados

### Portas expostas

| Porta | Servico | Exposicao |
|-------|---------|-----------|
| 80 | Frontend/nginx | Publica |
| 5678 | n8n | Opcional (admin) |
| 5432 | PostgreSQL | Interna apenas |
| 6379 | Redis | Interna apenas |

## Escalar

### Horizontal (multiplas instancias n8n)

1. Ative modo queue no docker-compose
2. Configure Redis como broker
3. Use load balancer externo

### Vertical

Ajuste `deploy.resources` no docker-compose.prod.yml

## Suporte

- Documentacao n8n: https://docs.n8n.io
- Docker: https://docs.docker.com
- Issues: Abra uma issue no repositorio
