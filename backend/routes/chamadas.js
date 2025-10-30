const express = require('express');
const router = express.Router();
const dbManager = require('../db/db_manager');
const { DateTime } = require('luxon');

// Rota para o app (home.dart) buscar os horários
router.get('/configuracao/horarios', (req, res) => {
    // Retorna a lista de horários do db_manager (ex: [{ rodada: 1, hora_inicio: "19:00", ... }])
    res.json({ horarios: dbManager.getConfigHorarios() });
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

    // Encontrar a configuração pela string da HORA
    const config = dbManager.getConfigHorarios().find(c => c.hora_inicio === horaInicioString);
    if (!config) {
        return res.status(400).json({ erro: "Rodada (hora) inválida." });
    }

    // Passa o NÚMERO da rodada (ex: 1) e a duração para o dbManager
    try {
        const chamada = await dbManager.iniciarNovaChamada(config.rodada, config.duracao_minutos);
        res.json(chamada);
    } catch (err) {
        console.error("Erro ao iniciar chamada:", err);
        res.status(500).json({ erro: "Erro ao iniciar chamada." });
    }
});

// Rota para o ALUNO registrar a presença
router.post('/presencas', async (req, res) => {
    const { aluno_id, id_chamada, validacao_toque_tela, validacao_movimento } = req.body;

    if (!aluno_id || !id_chamada)
        return res.status(400).json({ erro: "Dados obrigatórios ausentes." });

    try {
        // Busca a chamada (e o seu data_hora_fim) do db_manager
        const chamada = await dbManager.getChamadaById(id_chamada);
        if (!chamada)
            return res.status(404).json({ erro: "Chamada não encontrada." });

        // O getChamadaById (corrigido) já retorna 'data_hora_fim' como um objeto DateTime
        if (DateTime.now().setZone('America/Sao_Paulo') > chamada.data_hora_fim)
            return res.status(400).json({ erro: "Chamada expirada." });

        const status = (validacao_toque_tela && validacao_movimento) ? "Presente" : "Faltou";
        const obs = status === "Presente" ? "" : "Não cumpriu critérios.";

        const registro = await dbManager.registrarPresenca(aluno_id, id_chamada, status, obs);
        if (registro.error) return res.status(409).json({ erro: registro.error });

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


// --- ROTA NOVA ADICIONADA ---
router.get('/chamadas/ativa/:horaInicio', async (req, res) => {
    const { horaInicio } = req.params;
    
    try {
        // Usa a nova função do db_manager (que busca no SQL)
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