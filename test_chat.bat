@echo off
echo Testando o webhook do chat...
echo.

REM IMPORTANTE: Clique em "Execute Workflow" no n8n ANTES de rodar este comando!

curl -X POST https://n8n.rojasdev.cloud/webhook-test/chat/bible ^
  -H "Content-Type: application/json" ^
  -d "{\"message\":\"Quais as cartas de Paulo?\",\"userId\":\"user_test123\",\"email\":\"henriquer01@rojasdev.cloud\",\"sessionId\":\"session_test_123\"}"

echo.
pause
