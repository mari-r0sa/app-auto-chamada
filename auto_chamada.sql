CREATE DATABASE auto_chamada;
USE auto_chamada;

-- Tabela de tipos de usuário
CREATE TABLE tipo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo VARCHAR(30) NOT NULL
);

INSERT INTO tipo (tipo) VALUES ('Professor'), ('Aluno');

-- Tabela de usuários
CREATE TABLE usuario (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    senha VARCHAR(100) NOT NULL,
    tipo INT NOT NULL,
    CONSTRAINT FK_USU_TIPO FOREIGN KEY (tipo) REFERENCES tipo(id)
);

-- Tabela de chamadas
CREATE TABLE chamada (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data_hora DATETIME NOT NULL
);

-- Tabela de status de presença
CREATE TABLE presenca (
    id INT PRIMARY KEY AUTO_INCREMENT,
    descricao VARCHAR(30) NOT NULL
);

-- Corrigido: 'desc' é palavra reservada, por isso trocamos por 'descricao'
INSERT INTO presenca (descricao) VALUES ('Presente'), ('Faltou'), ('Atrasado');

-- Associação entre aluno, chamada e status
CREATE TABLE aluno_chamada (
    id INT PRIMARY KEY AUTO_INCREMENT,
    aluno INT NOT NULL,
    chamada INT NOT NULL,
    presenca INT NOT NULL,
    obs VARCHAR(100),
    CONSTRAINT FK_ALUNO_CHAMADA_AL FOREIGN KEY (aluno) REFERENCES usuario(id),
    CONSTRAINT FK_ALUNO_CHAMADA_CH FOREIGN KEY (chamada) REFERENCES chamada(id),
    CONSTRAINT FK_ALUNO_CHAMADA_PR FOREIGN KEY (presenca) REFERENCES presenca(id)
);