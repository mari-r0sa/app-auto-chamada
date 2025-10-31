CREATE DATABASE IF NOT EXISTS auto_chamada;
USE auto_chamada;

-- Tabela de tipos de usuário
CREATE TABLE IF NOT EXISTS tipo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo VARCHAR(30) NOT NULL
);

-- Tabela de status de presença
CREATE TABLE IF NOT EXISTS presenca (
    id INT PRIMARY KEY AUTO_INCREMENT,
    descricao VARCHAR(30) NOT NULL
);

-- Tabela de usuários
CREATE TABLE IF NOT EXISTS usuario (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    senha VARCHAR(100) NOT NULL, -- Deveria ser VARCHAR(60) para bcrypt
    tipo INT NOT NULL,
    CONSTRAINT FK_USU_TIPO FOREIGN KEY (tipo) REFERENCES tipo(id)
);

-- Tabela de chamadas
CREATE TABLE IF NOT EXISTS chamada (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data_hora DATETIME NOT NULL,
    rodada INT NOT NULL -- <<< COLUNA ADICIONADA (essencial para o db_manager.js)
);

-- Associação entre aluno, chamada e status
CREATE TABLE IF NOT EXISTS aluno_chamada (
    id INT PRIMARY KEY AUTO_INCREMENT,
    aluno INT NOT NULL,
    chamada INT NOT NULL,
    presenca INT NOT NULL,
    obs VARCHAR(100),
    CONSTRAINT FK_ALUNO_CHAMADA_AL FOREIGN KEY (aluno) REFERENCES usuario(id),
    CONSTRAINT FK_ALUNO_CHAMADA_CH FOREIGN KEY (chamada) REFERENCES chamada(id),
    CONSTRAINT FK_ALUNO_CHAMADA_PR FOREIGN KEY (presenca) REFERENCES presenca(id),
    -- Adiciona restrição para evitar presença duplicada
    CONSTRAINT UQ_ALUNO_CHAMADA UNIQUE (aluno, chamada) 
);

-- Insere dados básicos se não existirem
INSERT IGNORE INTO tipo (id, tipo) VALUES (1, 'Professor'), (2, 'Aluno');
INSERT IGNORE INTO presenca (id, descricao) VALUES (1, 'Presente'), (2, 'Faltou'), (3, 'Atrasado');