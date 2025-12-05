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
        console.log('[Job] Verificando chamadas expiradas...');
        const agora = DateTime.now().setZone(ZONA_HORARIO);

        const [chamadasHoje] = await dbManager.pool.query(
        `SELECT id, rodada, data_hora FROM chamada
        WHERE DATE(data_hora) = CURDATE()
        AND status = 'ATIVA'`
        );

        for (const chamada of chamadasHoje) {
        const config = dbManager.getConfigHorarios().find(c => c.rodada === chamada.rodada);
        if (!config) continue;

        const dataHoraInicio = DateTime.fromSQL(chamada.data_hora).setZone(ZONA_HORARIO);

        const dataHoraFim = dataHoraInicio.plus({ 
            minutes: config.duracao_minutos + config.tolerancia_minutos 
        });

        if (agora > dataHoraFim) {
            console.log(`[Job] Finalizando chamada ID ${chamada.id}...`);
            await dbManager.finalizarChamada(chamada.id);
            console.log(`[Job] Chamada ID ${chamada.id} finalizada.`);
        }
        }

        console.log('[Job] Concluído.');
    } catch (err) {
        console.error('[Job] Erro ao processar chamadas:', err);
    }
});