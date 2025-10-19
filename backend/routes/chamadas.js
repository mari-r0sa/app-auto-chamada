const express = require('express');
const router = express.Router();
const dbManager = require('../db/db_manager');
const { DateTime } = require('luxon');

router.get('/configuracao/horarios', (req, res) => {
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
    const { rodada } = req.body;

    const config = dbManager.getConfigHorarios().find(c => c.rodada === rodada);
    if (!config) return res.status(400).json({ erro: "Rodada inválida." });

    try {
        const chamada = await dbManager.iniciarNovaChamada(rodada, config.duracao_minutos);
        res.json(chamada);
    } catch (err) {
        res.status(500).json({ erro: "Erro ao iniciar chamada." });
    }
});

router.post('/presencas', async (req, res) => {
    const { aluno_id, id_chamada, validacao_toque_tela, validacao_movimento } = req.body;

    if (!aluno_id || !id_chamada)
        return res.status(400).json({ erro: "Dados obrigatórios ausentes." });

    try {
        const chamada = await dbManager.getChamadaById(id_chamada);
        if (!chamada)
            return res.status(404).json({ erro: "Chamada não encontrada." });

        if (DateTime.now() > chamada.data_hora_fim)
            return res.status(400).json({ erro: "Chamada expirada." });

        const status = (validacao_toque_tela && validacao_movimento) ? "Presente" : "Faltou";
        const obs = status === "Presente" ? "" : "Não cumpriu critérios.";

        const registro = await dbManager.registrarPresenca(aluno_id, id_chamada, status, obs);
        if (registro.error) return res.status(409).json({ erro: registro.error });

        res.status(201).json(registro);
    } catch (err) {
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

module.exports = router;
