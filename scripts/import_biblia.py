#!/usr/bin/env python3
"""
Script para importar a base de dados da Biblia para PostgreSQL

Uso:
    python import_biblia.py

Requisitos:
    pip install psycopg2-binary

Variaveis de ambiente necessarias:
    POSTGRES_HOST (default: localhost)
    POSTGRES_PORT (default: 5432)
    POSTGRES_DB (default: n8n)
    POSTGRES_USER (default: n8n)
    POSTGRES_PASSWORD (default: n8n_secure_password_2025)
"""

import os
import re
import sys
from pathlib import Path

try:
    import psycopg2
    from psycopg2.extras import execute_values
except ImportError:
    print("Erro: psycopg2 nao instalado.")
    print("Execute: pip install psycopg2-binary")
    sys.exit(1)

# Carrega variaveis do arquivo .env se existir
def load_env_file():
    """Carrega variaveis do arquivo .env"""
    env_file = Path(__file__).parent.parent / '.env'
    if env_file.exists():
        print(f"Carregando configuracoes de: {env_file}")
        with open(env_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    # Nao sobrescreve variaveis ja definidas no ambiente
                    if key not in os.environ:
                        os.environ[key] = value

load_env_file()

# Configuracoes do banco (compativel com variaveis do Easypanel/Docker)
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST') or os.getenv('DB_POSTGRESDB_HOST', 'localhost'),
    'port': int(os.getenv('POSTGRES_PORT') or os.getenv('DB_POSTGRESDB_PORT', '5432')),
    'dbname': os.getenv('POSTGRES_DB') or os.getenv('DB_POSTGRESDB_DATABASE', 'n8n'),
    'user': os.getenv('POSTGRES_USER') or os.getenv('DB_POSTGRESDB_USER', 'n8n'),
    'password': os.getenv('POSTGRES_PASSWORD') or os.getenv('DB_POSTGRESDB_PASSWORD', 'n8n_secure_password_2025')
}

# Caminho do arquivo SQL
SCRIPT_DIR = Path(__file__).parent.parent
SQL_FILE = SCRIPT_DIR / 'biblia_base_sql' / 'biblia.sql'


def parse_versiculos_from_sql(sql_file: Path) -> list:
    """
    Extrai os versiculos do arquivo SQL MySQL
    """
    versiculos = []

    print(f"Lendo arquivo: {sql_file}")

    with open(sql_file, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()

    # Encontra todos os INSERTs de versiculos
    # Formato: INSERT INTO `versiculos` (`ver_id`, `ver_vrs_id`, `ver_liv_id`, `ver_capitulo`, `ver_versiculo`, `ver_texto`) VALUES
    # (1, 0, 1, 1, 1, 'No principio criou Deus os ceus e a terra.'),

    # Regex para extrair valores
    pattern = r"\((\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*'((?:[^'\\]|\\.|'')*)'\)"

    matches = re.findall(pattern, content)

    print(f"Encontrados {len(matches)} versiculos")

    for match in matches:
        ver_id, ver_vrs_id, ver_liv_id, ver_capitulo, ver_versiculo, ver_texto = match

        # Limpa o texto (remove escapes MySQL)
        ver_texto = ver_texto.replace("\\'", "'")
        ver_texto = ver_texto.replace("''", "'")
        ver_texto = ver_texto.replace("\\n", "\n")
        ver_texto = ver_texto.replace("\\r", "")

        versiculos.append({
            'ver_liv_id': int(ver_liv_id),
            'ver_capitulo': int(ver_capitulo),
            'ver_versiculo': int(ver_versiculo),
            'ver_texto': ver_texto
        })

    return versiculos


def import_to_postgres(versiculos: list):
    """
    Importa os versiculos para o PostgreSQL
    """
    print(f"\nConectando ao PostgreSQL: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}")

    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    try:
        # Verifica se ja existem versiculos
        cur.execute("SELECT COUNT(*) FROM versiculos")
        count = cur.fetchone()[0]

        if count > 0:
            print(f"Tabela versiculos ja contem {count} registros.")
            response = input("Deseja limpar e reimportar? (s/N): ")
            if response.lower() != 's':
                print("Importacao cancelada.")
                return

            print("Limpando tabela versiculos...")
            cur.execute("TRUNCATE TABLE versiculos RESTART IDENTITY CASCADE")
            conn.commit()

        # Insere em lotes
        print(f"\nInserindo {len(versiculos)} versiculos...")

        batch_size = 1000
        total_batches = (len(versiculos) + batch_size - 1) // batch_size

        for i in range(0, len(versiculos), batch_size):
            batch = versiculos[i:i + batch_size]
            values = [(v['ver_liv_id'], v['ver_capitulo'], v['ver_versiculo'], v['ver_texto']) for v in batch]

            execute_values(
                cur,
                """
                INSERT INTO versiculos (ver_liv_id, ver_capitulo, ver_versiculo, ver_texto)
                VALUES %s
                """,
                values
            )

            batch_num = (i // batch_size) + 1
            print(f"  Lote {batch_num}/{total_batches} inserido ({len(batch)} registros)")

        conn.commit()

        # Verifica total inserido
        cur.execute("SELECT COUNT(*) FROM versiculos")
        total = cur.fetchone()[0]
        print(f"\nTotal de versiculos inseridos: {total}")

        # Mostra estatisticas
        print("\n--- Estatisticas ---")
        cur.execute("""
            SELECT t.tes_nome, COUNT(DISTINCT l.liv_id) as livros, COUNT(v.ver_id) as versiculos
            FROM testamentos t
            JOIN livros l ON t.tes_id = l.liv_tes_id
            JOIN versiculos v ON l.liv_id = v.ver_liv_id
            GROUP BY t.tes_nome
            ORDER BY t.tes_id
        """)
        for row in cur.fetchall():
            print(f"  {row[0]}: {row[1]} livros, {row[2]} versiculos")

        print("\nImportacao concluida com sucesso!")

    except Exception as e:
        conn.rollback()
        print(f"\nErro durante importacao: {e}")
        raise
    finally:
        cur.close()
        conn.close()


def test_busca():
    """
    Testa a funcao de busca
    """
    print("\n--- Testando busca ---")

    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    try:
        # Teste 1: Busca por texto
        print("\nBusca por 'amor':")
        cur.execute("SELECT * FROM buscar_versiculos('amor', 5)")
        for row in cur.fetchall():
            print(f"  {row[4]}: {row[3][:80]}...")

        # Teste 2: Busca por referencia
        print("\nJoao 3:16:")
        cur.execute("SELECT * FROM buscar_por_referencia('Joao', 3, 16)")
        for row in cur.fetchall():
            print(f"  {row[4]}: {row[3]}")

    finally:
        cur.close()
        conn.close()


def main():
    print("=" * 60)
    print("IMPORTADOR DE BIBLIA PARA POSTGRESQL")
    print("=" * 60)

    if not SQL_FILE.exists():
        print(f"\nErro: Arquivo nao encontrado: {SQL_FILE}")
        sys.exit(1)

    # Parse o arquivo SQL
    versiculos = parse_versiculos_from_sql(SQL_FILE)

    if not versiculos:
        print("\nNenhum versiculo encontrado no arquivo SQL!")
        sys.exit(1)

    # Importa para o PostgreSQL
    import_to_postgres(versiculos)

    # Testa a busca
    test_busca()


if __name__ == '__main__':
    main()
