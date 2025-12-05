const express = require('express');
const app = express();
const chamadasRoutes = require('./routes/chamadas');
const relatorioRouter = require('./routes/relatorio');
const usuariosRoutes  = require('./routes/usuarios');
const cors = require('cors');
const cron = require('node-cron');
const dbManager = require('./db/db_manager');
const { CONFIG_HORARIOS, ZONA_HORARIO } = dbManager;
const { DateTime } = require('luxon');

app.use(cors());
app.use(express.json());
app.use('/api/chamadas', chamadasRoutes);
app.use('/api/usuarios', usuariosRoutes);
app.use('/api/relatorio', relatorioRouter);

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Servidor rodando em http://0.0.0.0:${PORT}`);
});

// Rodando a cada minuto
cron.schedule('* * * * *', async () => {
    try {
        console.log("[Job] Verificando chamadas ativas...");

        const [chamadas] = await dbManager.pool.query(
            "SELECT id, data_hora, rodada FROM chamada WHERE status = 'ATIVA'"
        );

        const agora = DateTime.now().setZone(ZONA_HORARIO);

        for (const chamada of chamadas) {
            const config = CONFIG_HORARIOS.find(c => c.rodada === chamada.rodada);
            if (!config) continue;

            const dataHoraInicio = DateTime.fromSQL(chamada.data_hora).setZone(ZONA_HORARIO);
            const dataHoraFim = dataHoraInicio.plus({ minutes: config.duracao_minutos });

            // Se a chamada já passou do horário de fim, finaliza
            if (agora > dataHoraFim) {
                // 1. Finaliza a chamada
                await dbManager.pool.query(
                    "UPDATE chamada SET status = 'FINALIZADA' WHERE id = ?",
                    [chamada.id]
                );

                // 2. Registra faltas automaticamente para alunos sem registro
                const [alunos] = await dbManager.pool.query(
                    `SELECT id FROM usuario WHERE tipo = 2
                    AND id NOT IN (SELECT aluno FROM aluno_chamada WHERE chamada = ?)`,
                    [chamada.id]
                );

                for (const aluno of alunos) {
                    const [presencaRows] = await dbManager.pool.query(
                        "SELECT id FROM presenca WHERE descricao = 'Faltou'"
                    );
                    if (presencaRows.length === 0) continue;

                    const presencaId = presencaRows[0].id;

                    await dbManager.pool.query(
                        "INSERT INTO aluno_chamada (aluno, chamada, presenca, obs) VALUES (?, ?, ?, ?)",
                        [aluno.id, chamada.id, presencaId, "Falta registrada automaticamente"]
                    );
                }

                console.log(`[Job] Chamada ${chamada.id} finalizada e faltas registradas.`);
            }
        }

    } catch (err) {
        console.error("[Job] Erro ao processar chamadas:", err);
    }
});