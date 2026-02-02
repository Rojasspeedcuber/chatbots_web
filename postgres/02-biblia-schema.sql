-- ============================================
-- SCRIPT DE SCHEMA - Biblia Sagrada
-- Bible AI Chat - Base de dados biblica
-- ============================================

-- ============================================
-- TABELA: testamentos
-- ============================================
CREATE TABLE IF NOT EXISTS testamentos (
    tes_id SMALLINT PRIMARY KEY,
    tes_nome VARCHAR(30) NOT NULL
);

-- Inserir testamentos
INSERT INTO testamentos (tes_id, tes_nome) VALUES
(1, 'Antigo Testamento'),
(2, 'Novo Testamento')
ON CONFLICT (tes_id) DO NOTHING;

-- ============================================
-- TABELA: livros
-- ============================================
CREATE TABLE IF NOT EXISTS livros (
    liv_id SMALLINT PRIMARY KEY,
    liv_tes_id SMALLINT NOT NULL REFERENCES testamentos(tes_id),
    liv_posicao SMALLINT NOT NULL,
    liv_nome VARCHAR(30) NOT NULL,
    UNIQUE(liv_tes_id, liv_posicao)
);

-- Criar indice para buscas por nome
CREATE INDEX IF NOT EXISTS idx_livros_nome ON livros(liv_nome);
CREATE INDEX IF NOT EXISTS idx_livros_testamento ON livros(liv_tes_id);

-- Inserir livros
INSERT INTO livros (liv_id, liv_tes_id, liv_posicao, liv_nome) VALUES
-- Antigo Testamento
(1, 1, 1, 'Genesis'),
(2, 1, 2, 'Exodo'),
(3, 1, 3, 'Levitico'),
(4, 1, 4, 'Numeros'),
(5, 1, 5, 'Deuteronomio'),
(6, 1, 6, 'Josue'),
(7, 1, 7, 'Juizes'),
(8, 1, 8, 'Rute'),
(9, 1, 9, 'I Samuel'),
(10, 1, 10, 'II Samuel'),
(11, 1, 11, 'I Reis'),
(12, 1, 12, 'II Reis'),
(13, 1, 13, 'I Cronicas'),
(14, 1, 14, 'II Cronicas'),
(15, 1, 15, 'Esdras'),
(16, 1, 16, 'Neemias'),
(17, 1, 17, 'Ester'),
(18, 1, 18, 'Jo'),
(19, 1, 19, 'Salmos'),
(20, 1, 20, 'Proverbios'),
(21, 1, 21, 'Eclesiastes'),
(22, 1, 22, 'Cantico dos Canticos'),
(23, 1, 23, 'Isaias'),
(24, 1, 24, 'Jeremias'),
(25, 1, 25, 'Lamentacoes Jeremias'),
(26, 1, 26, 'Ezequiel'),
(27, 1, 27, 'Daniel'),
(28, 1, 28, 'Oseias'),
(29, 1, 29, 'Joel'),
(30, 1, 30, 'Amos'),
(31, 1, 31, 'Obadias'),
(32, 1, 32, 'Jonas'),
(33, 1, 33, 'Miqueias'),
(34, 1, 34, 'Naum'),
(35, 1, 35, 'Habacuque'),
(36, 1, 36, 'Sofonias'),
(37, 1, 37, 'Ageu'),
(38, 1, 38, 'Zacarias'),
(39, 1, 39, 'Malaquias'),
-- Novo Testamento
(40, 2, 1, 'Mateus'),
(41, 2, 2, 'Marcos'),
(42, 2, 3, 'Lucas'),
(43, 2, 4, 'Joao'),
(44, 2, 5, 'Atos'),
(45, 2, 6, 'Romanos'),
(46, 2, 7, 'I Corintios'),
(47, 2, 8, 'II Corintios'),
(48, 2, 9, 'Galatas'),
(49, 2, 10, 'Efesios'),
(50, 2, 11, 'Filipenses'),
(51, 2, 12, 'Colossenses'),
(52, 2, 13, 'I Tessalonicenses'),
(53, 2, 14, 'II Tessalonicenses'),
(54, 2, 15, 'I Timoteo'),
(55, 2, 16, 'II Timoteo'),
(56, 2, 17, 'Tito'),
(57, 2, 18, 'Filemom'),
(58, 2, 19, 'Hebreus'),
(59, 2, 20, 'Tiago'),
(60, 2, 21, 'I Pedro'),
(61, 2, 22, 'II Pedro'),
(62, 2, 23, 'I Joao'),
(63, 2, 24, 'II Joao'),
(64, 2, 25, 'III Joao'),
(65, 2, 26, 'Judas'),
(66, 2, 27, 'Apocalipse')
ON CONFLICT (liv_id) DO NOTHING;

-- ============================================
-- TABELA: versiculos
-- ============================================
CREATE TABLE IF NOT EXISTS versiculos (
    ver_id SERIAL PRIMARY KEY,
    ver_liv_id SMALLINT NOT NULL REFERENCES livros(liv_id),
    ver_capitulo SMALLINT NOT NULL,
    ver_versiculo SMALLINT NOT NULL,
    ver_texto TEXT NOT NULL
);

-- Indices para performance em buscas
CREATE INDEX IF NOT EXISTS idx_versiculos_livro ON versiculos(ver_liv_id);
CREATE INDEX IF NOT EXISTS idx_versiculos_capitulo ON versiculos(ver_liv_id, ver_capitulo);
CREATE INDEX IF NOT EXISTS idx_versiculos_referencia ON versiculos(ver_liv_id, ver_capitulo, ver_versiculo);

-- Indice de busca full-text para portugues
CREATE INDEX IF NOT EXISTS idx_versiculos_texto_fts ON versiculos USING gin(to_tsvector('portuguese', ver_texto));

-- ============================================
-- FUNCAO: Buscar versiculos por texto
-- ============================================
CREATE OR REPLACE FUNCTION buscar_versiculos(
    p_termo TEXT,
    p_limite INTEGER DEFAULT 20
)
RETURNS TABLE (
    livro VARCHAR(30),
    capitulo SMALLINT,
    versiculo SMALLINT,
    texto TEXT,
    referencia TEXT,
    relevancia REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.liv_nome,
        v.ver_capitulo,
        v.ver_versiculo,
        v.ver_texto,
        l.liv_nome || ' ' || v.ver_capitulo || ':' || v.ver_versiculo,
        ts_rank(to_tsvector('portuguese', v.ver_texto), plainto_tsquery('portuguese', p_termo)) as rank
    FROM versiculos v
    JOIN livros l ON v.ver_liv_id = l.liv_id
    WHERE to_tsvector('portuguese', v.ver_texto) @@ plainto_tsquery('portuguese', p_termo)
    ORDER BY rank DESC
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCAO: Buscar versiculo por referencia
-- ============================================
CREATE OR REPLACE FUNCTION buscar_por_referencia(
    p_livro VARCHAR(50),
    p_capitulo INTEGER,
    p_versiculo_inicio INTEGER,
    p_versiculo_fim INTEGER DEFAULT NULL
)
RETURNS TABLE (
    livro VARCHAR(30),
    capitulo SMALLINT,
    versiculo SMALLINT,
    texto TEXT,
    referencia TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.liv_nome,
        v.ver_capitulo,
        v.ver_versiculo,
        v.ver_texto,
        l.liv_nome || ' ' || v.ver_capitulo || ':' || v.ver_versiculo
    FROM versiculos v
    JOIN livros l ON v.ver_liv_id = l.liv_id
    WHERE LOWER(l.liv_nome) LIKE LOWER(p_livro || '%')
      AND v.ver_capitulo = p_capitulo
      AND v.ver_versiculo >= p_versiculo_inicio
      AND v.ver_versiculo <= COALESCE(p_versiculo_fim, p_versiculo_inicio)
    ORDER BY v.ver_versiculo;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VIEW: Estatisticas da Biblia
-- ============================================
CREATE OR REPLACE VIEW biblia_estatisticas AS
SELECT
    t.tes_nome as testamento,
    l.liv_nome as livro,
    COUNT(DISTINCT v.ver_capitulo) as total_capitulos,
    COUNT(v.ver_id) as total_versiculos
FROM testamentos t
JOIN livros l ON t.tes_id = l.liv_tes_id
JOIN versiculos v ON l.liv_id = v.ver_liv_id
GROUP BY t.tes_nome, l.liv_nome, l.liv_posicao
ORDER BY l.liv_tes_id, l.liv_posicao;

-- ============================================
-- COMENTARIOS
-- ============================================
COMMENT ON TABLE testamentos IS 'Antigo e Novo Testamento';
COMMENT ON TABLE livros IS '66 livros da Biblia';
COMMENT ON TABLE versiculos IS 'Todos os versiculos da Biblia';
COMMENT ON FUNCTION buscar_versiculos IS 'Busca full-text em versiculos';
COMMENT ON FUNCTION buscar_por_referencia IS 'Busca versiculo por referencia (ex: Joao 3:16)';
