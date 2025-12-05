const mysql = require('mysql2/promise');
const { DateTime } = require('luxon');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'sua_chave_secreta';

const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'auto_chamada',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    charset: 'utf8mb4'
});

const ZONA_HORARIO = 'America/Sao_Paulo';

const CONFIG_HORARIOS = [
    // { rodada: 1, hora_inicio: "12:00", duracao_minutos: 10, tolerancia_minutos: 5 },
    // { rodada: 2, hora_inicio: "13:05", duracao_minutos: 10, tolerancia_minutos: 5 },
    // { rodada: 3, hora_inicio: "15:30", duracao_minutos: 10, tolerancia_minutos: 5 },
    // { rodada: 4, hora_inicio: "16:35", duracao_minutos: 10, tolerancia_minutos: 5 }
    
    { rodada: 1, hora_inicio: "19:15", duracao_minutos: 10, tolerancia_minutos: 5 },
    { rodada: 2, hora_inicio: "20:00", duracao_minutos: 10, tolerancia_minutos: 5 },
    { rodada: 3, hora_inicio: "20:45", duracao_minutos: 10, tolerancia_minutos: 5 },
    { rodada: 4, hora_inicio: "21:30", duracao_minutos: 10, tolerancia_minutos: 5 }
];

const dbManager = {
    getConfigHorarios: () => CONFIG_HORARIOS,

    // ----------------------
    // USUÁRIOS
    // ----------------------
    async getAlunos() {
        const [rows] = await pool.query("SELECT id, nome FROM usuario WHERE tipo = 2");
        return rows;
    },

    async loginUsuario(email, senha) {
        console.log("DEBUG LOGIN USER:", email);

        try {
            const [rows] = await pool.query("SELECT * FROM usuario WHERE email = ?", [email]);
            if (rows.length === 0) return null;

            const user = rows[0];
            if (!user.senha) return null;

            const senhaCorreta = await bcrypt.compare(senha, user.senha);
            if (!senhaCorreta) return null;

            const token = jwt.sign({ id: user.id, tipo: user.tipo }, JWT_SECRET, { expiresIn: "12h" });

            return {
                token,
                usuario: {
                    id: user.id,
                    nome: user.nome,
                    email: user.email,
                    tipo: user.tipo
                }
            };
        } catch (err) {
            console.error("Erro interno em loginUsuario:", err);
            return null;
        }
    },

    async cadastrarAluno(nome, email, senha) {
        const [rows] = await pool.query("SELECT id FROM usuario WHERE email = ?", [email]);
        if (rows.length > 0) return { error: "E-mail já cadastrado." };

        const hashSenha = await bcrypt.hash(senha, 10);
        const [result] = await pool.query(
            "INSERT INTO usuario (nome, email, senha, tipo) VALUES (?, ?, ?, ?)",
            [nome, email, hashSenha, 2]
        );
        return { id: result.insertId, nome, email };
    },

    // ----------------------
    // CHAMADAS
    // ----------------------
    async iniciarNovaChamada(rodadaNum, duracaoMinutos, horaInicioString) {
        const agora = DateTime.now().setZone(ZONA_HORARIO);
        const [h, m] = horaInicioString.split(':').map(Number);
        const dataHoraInicio = agora.set({ hour: h, minute: m, second: 0, millisecond: 0 });

        const [result] = await pool.query(
            "INSERT INTO chamada (data_hora, rodada) VALUES (?, ?)", 
            [dataHoraInicio.toFormat("yyyy-MM-dd HH:mm"), rodadaNum]
        );

        const dataHoraFim = dataHoraInicio.plus({ minutes: duracaoMinutos });
        return {
            id: result.insertId,
            rodada: rodadaNum,
            data_hora_inicio: dataHoraInicio.toFormat("yyyy-MM-dd HH:mm"),
            data_hora_fim: dataHoraFim.toFormat("yyyy-MM-dd HH:mm"),
            status: "ATIVA"
        };
    },

    async getChamadaById(chamadaId) {
        const [rows] = await pool.query("SELECT id, data_hora, rodada FROM chamada WHERE id = ?", [chamadaId]);
        if (rows.length === 0) return null;

        const chamada = rows[0];
        const config = CONFIG_HORARIOS.find(c => c.rodada === chamada.rodada);
        const duracaoTotal = (config?.duracao_minutos || 10) + (config?.tolerancia_minutos || 0);
        const dataHoraInicio = DateTime.fromSQL(chamada.data_hora).setZone(ZONA_HORARIO);
        const dataHoraFim = dataHoraInicio.plus({ minutes: duracaoTotal });

        return { ...chamada, data_hora_inicio: dataHoraInicio, data_hora_fim: dataHoraFim };
    },

    async getChamadaAtivaPorRodada(horaInicioString) {
        const config = CONFIG_HORARIOS.find(c => c.hora_inicio === horaInicioString);
        if (!config) return undefined;

        const rodadaNum = config.rodada;
        const agora = DateTime.now().setZone(ZONA_HORARIO);

        const hojeInicio = agora.startOf('day').toSQL();
        const hojeFim = agora.endOf('day').toSQL();

        const [rows] = await pool.query(
            `SELECT id, data_hora, rodada FROM chamada
             WHERE rodada = ? AND data_hora BETWEEN ? AND ?
             ORDER BY data_hora DESC LIMIT 1`,
            [rodadaNum, hojeInicio, hojeFim]
        );

        if (rows.length > 0) {
            const chamada = rows[0];
            const dataHoraInicio = DateTime.fromSQL(chamada.data_hora).setZone(ZONA_HORARIO);
            const dataHoraFim = dataHoraInicio.plus({ minutes: config.duracao_minutos + config.tolerancia_minutos });
            if (agora > dataHoraFim) return undefined;
            return { id: chamada.id, data_hora_inicio: dataHoraInicio.toISO(), data_hora_fim: dataHoraFim.toISO() };
        }

        // Cria nova chamada se estiver dentro da janela
        const [h, m] = config.hora_inicio.split(':').map(Number);
        const horaInicioHoje = agora.set({ hour: h, minute: m, second: 0, millisecond: 0 });
        const horaFimTotal = horaInicioHoje.plus({ minutes: config.duracao_minutos + config.tolerancia_minutos });
        if (agora >= horaInicioHoje && agora <= horaFimTotal) {
            const dataHoraInicioSQL = horaInicioHoje.toFormat("yyyy-MM-dd HH:mm");
            const [result] = await pool.query("INSERT INTO chamada (data_hora, rodada) VALUES (?, ?)", [dataHoraInicioSQL, rodadaNum]);
            return { id: result.insertId, data_hora_inicio: horaInicioHoje.toISO(), data_hora_fim: horaFimTotal.toISO() };
        }

        return undefined;
    },

    async finalizarChamada(idChamada) {
        await this.registrarFaltasAutomaticas(idChamada);
        await pool.query("UPDATE chamada SET status = 'FINALIZADA' WHERE id = ?", [idChamada]);
        return { idChamada, status: "FINALIZADA" };
    },

    async registrarFaltasAutomaticas(idChamada) {
        const chamada = await this.getChamadaById(idChamada);
        if (!chamada) throw new Error("Chamada não encontrada");

        const alunos = await this.getAlunos();
        const [rows] = await pool.query("SELECT aluno FROM aluno_chamada WHERE chamada = ?", [idChamada]);
        const alunosPresentes = rows.map(r => r.aluno);

        const faltosos = alunos.filter(a => !alunosPresentes.includes(a.id));
        for (const aluno of faltosos) {
            await this.registrarPresenca(aluno.id, idChamada, "Faltou", "Não registrou presença até o fim da chamada");
        }
        return { qtdFaltosos: faltosos.length };
    },

    async registrarPresenca(alunoId, chamadaId, statusDesc, obs = "") {
        const [statusRows] = await pool.query("SELECT id FROM presenca WHERE descricao = ?", [statusDesc]);
        if (statusRows.length === 0) return { error: "Status de presença inválido." };
        const presencaId = statusRows[0].id;

        try {
            const [result] = await pool.query(
                "INSERT INTO aluno_chamada (aluno, chamada, presenca, obs) VALUES (?, ?, ?, ?)",
                [alunoId, chamadaId, presencaId, obs]
            );
            return { id_registro: result.insertId, user_id: alunoId, id_chamada: chamadaId, status_presenca: statusDesc };
        } catch (err) {
            if (err.code === 'ER_DUP_ENTRY') return { error: "Aluno já registrou presença nesta rodada." };
            throw err;
        }
    },

    // ----------------------
    // RELATÓRIOS
    // ----------------------
    async getPresencasHoje(alunoId) {
        const hojeInicio = DateTime.now().setZone(ZONA_HORARIO).startOf('day').toSQL();
        const hojeFim = DateTime.now().setZone(ZONA_HORARIO).endOf('day').toSQL();

        const [rows] = await pool.query(
            `SELECT c.rodada, p.descricao as status_presenca
             FROM aluno_chamada ac
             JOIN chamada c ON ac.chamada = c.id
             JOIN presenca p ON ac.presenca = p.id
             WHERE ac.aluno = ? AND c.data_hora BETWEEN ? AND ?`,
            [alunoId, hojeInicio, hojeFim]
        );

        return rows.map(r => ({
            rodada: r.rodada,
            status_presenca: r.status_presenca
        }));
    },

    async getRelatorioPorAluno(alunoId) {
        const [rows] = await pool.query(
            `SELECT u.nome AS aluno, c.data_hora, p.descricao AS presenca, ac.obs
             FROM aluno_chamada ac
             JOIN usuario u ON ac.aluno = u.id
             JOIN chamada c ON ac.chamada = c.id
             JOIN presenca p ON ac.presenca = p.id
             WHERE ac.aluno = ?
             ORDER BY c.data_hora DESC`,
            [alunoId]
        );

        return rows.map(r => ({
            aluno: r.aluno,
            data: DateTime.fromSQL(r.data_hora).setZone(ZONA_HORARIO).toFormat("dd/MM/yyyy HH:mm"),
            presenca: r.presenca || "",
            observacoes: r.obs || ""
        }));
    },

    async getRelatorioHoje() {
        const hojeInicio = DateTime.now().setZone(ZONA_HORARIO).startOf('day').toSQL();
        const hojeFim = DateTime.now().setZone(ZONA_HORARIO).endOf('day').toSQL();

        const [rows] = await pool.query(
            `SELECT u.nome AS aluno, c.data_hora, p.descricao AS presenca, ac.obs
             FROM aluno_chamada ac
             JOIN usuario u ON ac.aluno = u.id
             JOIN chamada c ON ac.chamada = c.id
             JOIN presenca p ON ac.presenca = p.id
             WHERE c.data_hora BETWEEN ? AND ?
             ORDER BY c.data_hora DESC`,
            [hojeInicio, hojeFim]
        );

        return rows.map(r => ({
            aluno: r.aluno,
            data: DateTime.fromSQL(r.data_hora).setZone(ZONA_HORARIO).toFormat("dd/MM/yyyy HH:mm"),
            presenca: r.presenca || "",
            observacoes: r.obs || ""
        }));
    },

    async getRelatorioPorData(dataInicio, dataFim) {
        const inicioSQL = DateTime.fromJSDate(dataInicio).setZone(ZONA_HORARIO).toSQL();
        const fimSQL = DateTime.fromJSDate(dataFim).setZone(ZONA_HORARIO).toSQL();

        const [rows] = await pool.query(
            `SELECT u.nome AS aluno, c.data_hora, p.descricao AS presenca, ac.obs
             FROM aluno_chamada ac
             JOIN usuario u ON ac.aluno = u.id
             JOIN chamada c ON ac.chamada = c.id
             JOIN presenca p ON ac.presenca = p.id
             WHERE c.data_hora BETWEEN ? AND ?
             ORDER BY c.data_hora DESC`,
            [inicioSQL, fimSQL]
        );

        return rows.map(r => ({
            aluno: r.aluno,
            data: DateTime.fromSQL(r.data_hora).setZone(ZONA_HORARIO).toFormat("dd/MM/yyyy HH:mm"),
            presenca: r.presenca || "",
            observacoes: r.obs || ""
        }));
    }
};

module.exports = {
    ...dbManager,
    pool
};