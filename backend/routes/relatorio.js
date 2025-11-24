const express = require("express");
const router = express.Router();
const db = require("../db/db_manager");

// Relatório completo
router.get("/", async (req, res) => {
    try {
        const dados = await db.getRelatorioDados();
        res.json(dados);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erro ao obter relatório geral." });
    }
});

// Relatório por aluno
router.get("/aluno/:id", async (req, res) => {
    try {
        const dados = await db.getRelatorioPorAluno(req.params.id);
        res.json(dados);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erro ao obter relatório por aluno." });
    }
});

// Relatório por data específica (YYYY-MM-DD)
router.get("/data/:data", async (req, res) => {
    try {
        const dados = await db.getRelatorioPorData(req.params.data);
        res.json(dados);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erro ao obter relatório por data." });
    }
});

// Relatório do dia atual
router.get("/hoje", async (req, res) => {
    try {
        const dados = await db.getRelatorioHoje();
        res.json(dados);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erro ao obter relatório de hoje." });
    }
});

module.exports = router;