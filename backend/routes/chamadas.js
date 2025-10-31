const express = require('express');
const router = express.Router();
const dbManager = require('../db/db_manager');
const { DateTime } = require('luxon');

router.get('/configuracao/horarios', (req, res) => {
    res.json({ horarios: dbManager.getConfigHorarios() });
});

router.get('/presencas/hoje/:alunoId', async (req, res) => {
    const { alunoId } = req.params;
    if (!alunoId) {
        return res.status(400).json({ erro: "ID do aluno é obrigatório." });
    }
    
    try {
        const registros = await dbManager.getPresencasHoje(parseInt(alunoId, 10));
        res.json({ presencas: registros });
    } catch (err) {
        console.error("Erro ao buscar presenças de hoje:", err);
        res.status(500).json({ erro: "Erro ao buscar presenças." });
    }
});

router.get('/alunos', async (req, res) => {
    try {
        const alunos = await dbManager.getAlunos();
        res.json({ alunos });
    } catch (err) {
        res.status(500).json({ erro: "Erro ao buscar alunos." });
    }
});

router.post('/chamadas/iniciar', async (req, res) => {
    const { rodada: horaInicioString } = req.body;

    const config = dbManager.getConfigHorarios().find(c => c.hora_inicio === horaInicioString);
    if (!config) {
        return res.status(400).json({ erro: "Rodada (hora) inválida." });
    }

    try {
        const chamada = await dbManager.iniciarNovaChamada(
            config.rodada, 
            config.duracao_minutos,
            config.hora_inicio // Passa a hora de início programada
        );
        res.json(chamada);
    } catch (err) {
        console.error("Erro ao iniciar chamada:", err);
        res.status(500).json({ erro: "Erro ao iniciar chamada." });
    }
});

router.post('/presencas', async (req, res) => {
    const { 
        aluno_id, 
        id_chamada, 
        validacao_toque_tela,
        validacao_movimento 
    } = req.body;

    if (!aluno_id || !id_chamada || validacao_toque_tela === undefined || validacao_movimento === undefined)
        return res.status(400).json({ erro: "Dados obrigatórios ausentes (id, chamada, validacoes)." });

    try {
        const chamada = await dbManager.getChamadaById(id_chamada);
        if (!chamada)
            return res.status(404).json({ erro: "Chamada não encontrada." });

        const agora = DateTime.now().setZone('America/Sao_Paulo');
        const horaFim = chamada.data_hora_fim;
        
        const config = dbManager.getConfigHorarios().find(c => c.rodada === chamada.rodada);
        if (!config) {
            return res.status(500).json({ erro: "Erro de configuração da rodada." });
        }
        
        const duracaoTotal = config.duracao_minutos;
        const tempoTolerancia = config.tolerancia_minutos;
        const tempoNormal = duracaoTotal - tempoTolerancia;
        
        const horaInicio = horaFim.minus({ minutes: duracaoTotal });
        const horaFimNormal = horaInicio.plus({ minutes: tempoNormal });

        let status = "Faltou";
        let obs = "";

        const cumpriuCriterios = (validacao_toque_tela && validacao_movimento);

        if (!cumpriuCriterios) {
            obs = "Não cumpriu os critérios de validação.";
            status = "Faltou";
        } else if (agora > horaFim) {
            status = "Faltou";
            obs = "Registro após o tempo limite.";
        } else if (agora > horaFimNormal) {
            status = "Atrasado";
            obs = `Registro com atraso.`;
        } else {
            status = "Presente";
            obs = `Presença registrada.`;
        }
        
        const registro = await dbManager.registrarPresenca(aluno_id, id_chamada, status, obs);
        
        if (registro.error) {
            return res.status(409).json({ erro: registro.error });
        }

        res.status(201).json(registro);
    } catch (err) {
        console.error("Erro ao registrar presença:", err);
        res.status(500).json({ erro: "Erro ao registrar presença." });
    }
});

router.get('/relatorio', async (req, res) => {
    try {
        const relatorio = await dbManager.getRelatorioDados();
        res.json({ registros: relatorio });
    } catch (err) {
        res.status(500).json({ erro: "Erro ao gerar relatório." });
    }
});

router.get('/chamadas/ativa/:horaInicio', async (req, res) => {
    const { horaInicio } = req.params;
    
    try {
        const chamada = await dbManager.getChamadaAtivaPorRodada(horaInicio); 

        if (!chamada) {
            return res.status(404).json({ erro: "Nenhuma chamada ativa encontrada para este horário." });
        }

        res.json({ id_chamada: chamada.id, data_hora_fim: chamada.data_hora_fim });

    } catch (err) {
        console.error("Erro ao buscar chamada ativa:", err);
        res.status(500).json({ erro: "Erro ao buscar chamada ativa." });
    }
});


module.exports = router;