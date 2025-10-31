const mysql = require('mysql2/promise');
const { DateTime } = require('luxon');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'sua_chave_secreta';

const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'auto_chamada',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

const ZONA_HORARIO = 'America/Sao_Paulo';

const CONFIG_HORARIOS = [
    { rodada: 1, hora_inicio: "19:30", duracao_minutos: 10, tolerancia_minutos: 5 },
    { rodada: 2, hora_inicio: "20:15", duracao_minutos: 10, tolerancia_minutos: 5 },
    { rodada: 3, hora_inicio: "21:00", duracao_minutos: 10, tolerancia_minutos: 5 },
    { rodada: 4, hora_inicio: "21:45", duracao_minutos: 10, tolerancia_minutos: 5 }
];

const dbManager = {
    getConfigHorarios: () => CONFIG_HORARIOS,

    async getAlunos() {
        const [rows] = await pool.query("SELECT id, nome FROM usuario WHERE tipo = 2");
        return rows;
    },

    async loginAluno(email, senha) {
        const [rows] = await pool.query(
            "SELECT id, nome, email, senha FROM usuario WHERE email = ? AND tipo = 2",
            [email]
        );
        if (rows.length === 0) return null; 
        const usuario = rows[0];
        const senhaValida = await bcrypt.compare(senha, usuario.senha);
        if (!senhaValida) return null;
        const token = jwt.sign(
            { id: usuario.id, nome: usuario.nome, email: usuario.email, tipo: 'Aluno' },
            JWT_SECRET,
            { expiresIn: '8h' }
        );
        return { 
            token, 
            usuario: { 
                id: usuario.id, 
                nome: usuario.nome, 
                email: usuario.email,
                tipo: 'Aluno' 
            } 
        };
    },

    async cadastrarAluno(nome, email, senha) {
        const [rows] = await pool.query(
            "SELECT id FROM usuario WHERE email = ?",
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

    async iniciarNovaChamada(rodadaNum, duracaoMinutos, horaInicioString) {
        const agora = DateTime.now().setZone(ZONA_HORARIO);
        const [h, m] = horaInicioString.split(':').map(Number);
        const dataHoraInicio = agora.set({ hour: h, minute: m, second: 0, millisecond: 0 });

        const [result] = await pool.query(
            "INSERT INTO chamada (data_hora, rodada) VALUES (?, ?)", 
            [dataHoraInicio.toFormat("yyyy-MM-dd HH:mm:ss"), rodadaNum]
        );
        
        const dataHoraFim = dataHoraInicio.plus({ minutes: duracaoMinutos });

        return {
            id: result.insertId,
            rodada: rodadaNum,
            data_hora_inicio: dataHoraInicio.toFormat("yyyy-MM-dd HH:mm:ss"),
            data_hora_fim: dataHoraFim.toFormat("yyyy-MM-dd HH:mm:ss"),
            status: "ATIVA"
        };
    },

    async getChamadaById(chamadaId) {
        const [rows] = await pool.query(
            "SELECT id, data_hora, rodada FROM chamada WHERE id = ?", 
            [chamadaId]
        );
        if (rows.length === 0) return null;
        const chamada = rows[0]; 
        const config = CONFIG_HORARIOS.find(c => c.rodada === chamada.rodada);
        const duracao = config ? config.duracao_minutos : 10;
        const dataHoraInicio = DateTime.fromSQL(chamada.data_hora).setZone(ZONA_HORARIO);
        const dataHoraFim = dataHoraInicio.plus({ minutes: duracao });
        return { ...chamada, data_hora_fim: dataHoraFim };
    },

    async getChamadaAtivaPorRodada(horaInicioString) {
        const config = CONFIG_HORARIOS.find(c => c.hora_inicio === horaInicioString);
        if (!config) {
            console.warn(`Nenhuma config encontrada para a hora: ${horaInicioString}`);
            return undefined;
        }
        
        const rodadaNum = config.rodada;
        const agora = DateTime.now().setZone(ZONA_HORARIO);

        // Tenta buscar uma chamada JÁ CRIADA para esta rodada hoje
        const hojeInicio = agora.startOf('day').toSQL();
        const hojeFim = agora.endOf('day').toSQL();

        const [rows] = await pool.query(
            `SELECT id, data_hora, rodada FROM chamada
            WHERE rodada = ?
            AND data_hora BETWEEN ? AND ?
            ORDER BY data_hora DESC
            LIMIT 1`,
            [rodadaNum, hojeInicio, hojeFim]
        );
        
        if (rows.length > 0) {
            const chamada = rows[0];
            const dataHoraInicio = DateTime.fromSQL(chamada.data_hora).setZone(ZONA_HORARIO);
            const dataHoraFim = dataHoraInicio.plus({ minutes: config.duracao_minutos });

            if (agora > dataHoraFim) {
                console.log(`Chamada ID ${chamada.id} encontrada, mas expirada.`);
                return undefined; // Expirada
            }
            // Retorna a chamada existente
            return {
                id: chamada.id,
                data_hora_fim: dataHoraFim.toISO() 
            };
        }

        // CHAMADA NÃO EXISTE
        // Verificar se estamos na janela de tempo para criá-la.
        
        const [h, m] = config.hora_inicio.split(':').map(Number);
        const horaInicioHoje = agora.set({ hour: h, minute: m, second: 0, millisecond: 0 });
        const horaFimTotal = horaInicioHoje.plus({ minutes: config.duracao_minutos });

        // Verifica se 'agora' está dentro da janela
        if (agora >= horaInicioHoje && agora <= horaFimTotal) {
            // Se sim, cria a chamada no banco
            const dataHoraInicioSQL = horaInicioHoje.toFormat("yyyy-MM-dd HH:mm:ss");
            
            const [result] = await pool.query(
                "INSERT INTO chamada (data_hora, rodada) VALUES (?, ?)", 
                [dataHoraInicioSQL, rodadaNum]
            );

            // Retorna a chamada recém-criada
            return {
                id: result.insertId,
                data_hora_fim: horaFimTotal.toISO() 
            };
        }

        // --- JANELA AINDA NÃO ABRIU OU JÁ PASSOU ---
        console.warn(`Tentativa de acesso fora da janela para ${horaInicioString}.`);
        return undefined;
    },

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
        return rows;
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
            return { id_registro: result.insertId, aluno_id: alunoId, id_chamada: chamadaId, status_presenca: statusDesc };
        } catch (err) {
            if (err.code === 'ER_DUP_ENTRY') {
                return { error: "Aluno já registrou presença nesta rodada." };
            }
            throw err;
        }
    },

    async getRelatorioDados() {
        const [rows] = await pool.query(
            `SELECT u.nome AS aluno, c.data_hora AS data_hora_chamada, p.descricao AS presenca, ac.obs AS observacoes
            FROM aluno_chamada ac
            JOIN usuario u ON ac.aluno = u.id
            JOIN chamada c ON ac.chamada = c.id
            JOIN presenca p ON ac.presenca = p.id
            ORDER BY c.data_hora DESC, u.nome ASC`
        );
        return rows.map(r => ({
            aluno: r.aluno,
            data: DateTime.fromSQL(r.data_hora_chamada).setZone(ZONA_HORARIO).toFormat("dd/MM/yyyy HH:mm"),
            presenca: r.presenca,
            observacoes: r.observacoes || ""
        }));
    }
};

module.exports = dbManager;