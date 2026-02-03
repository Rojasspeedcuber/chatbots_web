#!/bin/bash
# Script para ativar workflow via CLI do n8n

echo "Listando workflows..."
n8n list:workflow

echo ""
echo "Para ativar um workflow, use:"
echo "n8n update:workflow --id=<WORKFLOW_ID> --active=true"
echo ""
echo "Exemplo:"
echo "n8n update:workflow --id=1 --active=true"
