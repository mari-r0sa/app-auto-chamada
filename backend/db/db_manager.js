const mysql = require('mysql2/promise');
const { DateTime } = require('luxon');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'sua_chave_secreta';

// Configuração de conexão
const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'auto_chamada'
});

const CONFIG_HORARIOS = [
    { rodada: 1, hora_inicio: "19:00", duracao_minutos: 5 },
    { rodada: 2, hora_inicio: "19:50", duracao_minutos: 5 },
    { rodada: 3, hora_inicio: "20:40", duracao_minutos: 5 },
    { rodada: 4, hora_inicio: "21:30", duracao_minutos: 5 }
];

const dbManager = {
    getConfigHorarios: () => CONFIG_HORARIOS,

    async getAlunos() {
        const [rows] = await pool.query("SELECT id, nome FROM usuario WHERE tipo = 2");
        return rows;
    },

    // --- LOGIN ---
    async loginAluno(email, senha) {
        const [rows] = await pool.query(
            "SELECT id, nome, email, senha FROM usuario WHERE email = ? AND tipo = 2",
            [email]
        );

        if (rows.length === 0) return null; // usuário não encontrado

        const usuario = rows[0];
        const senhaValida = await bcrypt.compare(senha, usuario.senha);
        if (!senhaValida) return null;

        const token = jwt.sign(
            { id: usuario.id, nome: usuario.nome, email: usuario.email },
            JWT_SECRET,
            { expiresIn: '24h' }
        );

        return { token, usuario: { id: usuario.id, nome: usuario.nome, email: usuario.email } };
    },

    // --- CADASTRO ---
    async cadastrarAluno(nome, email, senha) {
        const [rows] = await pool.query(
            "SELECT id FROM usuario WHERE email = ? AND tipo = 2",
            [email]
        );
        if (rows.length > 0) return { error: "E-mail já cadastrado." };

        const hashSenha = await bcrypt.hash(senha, 10);
        const [result] = await pool.query(
            "INSERT INTO usuario (nome, email, senha, tipo) VALUES (?, ?, ?, ?)",
            [nome, email, hashSenha, 2]
        );

        return { id: result.insertId, nome, email };
    },

        // Obter usuário pelo e-mail
    async getUsuarioByEmail(email) {
        const [rows] = await pool.query(
            "SELECT id, nome, email, senha FROM usuario WHERE email = ? AND tipo = 2",
            [email]
        );
        return rows[0] || null;
    },

    // Cadastro de aluno com senha já hash
    async cadastrarAluno(nome, email, senhaHash) {
        const [result] = await pool.query(
            "INSERT INTO usuario (nome, email, senha, tipo) VALUES (?, ?, ?, 2)",
            [nome, email, senhaHash]
        );
        return { id: result.insertId, nome, email };
    },


    // --- Outras funções (chamada, presenca, relatorio) ---
    async iniciarNovaChamada(rodadaNum, duracaoMinutos) {
        const dataHoraInicio = DateTime.now().setZone('America/Sao_Paulo').toFormat("yyyy-MM-dd HH:mm:ss");
        const [result] = await pool.query("INSERT INTO chamada (data_hora) VALUES (?)", [dataHoraInicio]);
        const dataHoraFim = DateTime.fromFormat(dataHoraInicio, "yyyy-MM-dd HH:mm:ss", { zone: 'America/Sao_Paulo' })
            .plus({ minutes: duracaoMinutos })
            .toFormat("yyyy-MM-dd HH:mm:ss");

        return {
            id: result.insertId,
            rodada: rodadaNum,
            data_hora_inicio: dataHoraInicio,
            data_hora_fim: dataHoraFim,
            status: "ATIVA"
        };
    },

    async getChamadaById(chamadaId) {
        const [rows] = await pool.query("SELECT id, data_hora FROM chamada WHERE id = ?", [chamadaId]);
        if (rows.length === 0) return null;

        const chamada = rows[0];
        const config = CONFIG_HORARIOS.find(c => c.rodada === chamada.rodada);
        const duracao = config ? config.duracao_minutos : 5;
        const dataHoraInicio = DateTime.fromSQL(chamada.data_hora, { zone: 'America/Sao_Paulo' });
        const dataHoraFim = dataHoraInicio.plus({ minutes: duracao });

        return { ...chamada, data_hora_fim: dataHoraFim };
    },

    async registrarPresenca(alunoId, chamadaId, statusDesc, obs = "") {
        const [statusRows] = await pool.query("SELECT id FROM presenca WHERE descricao = ?", [statusDesc]);
        if (statusRows.length === 0) return { error: "Status de presença inválido." };
        const presencaId = statusRows[0].id;

        const [duplicado] = await pool.query(
            "SELECT id FROM aluno_chamada WHERE aluno = ? AND chamada = ?",
            [alunoId, chamadaId]
        );
        if (duplicado.length > 0) return { error: "Aluno já registrou presença nesta rodada." };

        const [result] = await pool.query(
            "INSERT INTO aluno_chamada (aluno, chamada, presenca, obs) VALUES (?, ?, ?, ?)",
            [alunoId, chamadaId, presencaId, obs]
        );
        return { id_registro: result.insertId, status_presenca: statusDesc };
    },

    async getRelatorioDados() {
        const [rows] = await pool.query(`
            SELECT
                u.nome AS aluno,
                c.data_hora AS data_hora_chamada,
                p.descricao AS presenca,
                ac.obs AS observacoes
            FROM aluno_chamada ac
            JOIN usuario u ON ac.aluno = u.id
            JOIN chamada c ON ac.chamada = c.id
            JOIN presenca p ON ac.presenca = p.id
            ORDER BY c.data_hora, u.nome
        `);

        return rows.map(r => ({
            aluno: r.aluno,
            data: DateTime.fromSQL(r.data_hora_chamada).toFormat("dd/MM/yyyy HH:mm"),
            presenca: r.presenca,
            observacoes: r.observacoes || ""
        }));
    }
};

module.exports = dbManager;