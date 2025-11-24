const express = require('express');
const router = express.Router();
const dbManager = require('../db/db_manager');

router.post('/cadastro', async (req, res) => {
    const { nome, email, senha } = req.body;

    if (!nome || !email || !senha) {
        return res.status(400).json({ erro: "Nome, e-mail e senha são obrigatórios." });
    }

    try {
        const resultado = await dbManager.cadastrarAluno(nome, email, senha);
        if (resultado.error) {
            return res.status(409).json({ erro: resultado.error }); // 409 = Conflito (e-mail duplicado)
        }
        res.status(201).json(resultado);
    } catch (err) {
        console.error("Erro no cadastro:", err);
        res.status(500).json({ erro: "Erro interno ao cadastrar usuário." });
    }
});

router.post('/login', async (req, res) => {
    const { email, senha } = req.body;

    console.log("REQ LOGIN:", req.body);

    try {
        const resultado = await dbManager.loginUsuario(email, senha);

        if (!resultado) {
            return res.status(401).json({ erro: "Credenciais inválidas." });
        }

        res.json(resultado);

    } catch (err) {
        res.status(500).json({ erro: "Erro interno no servidor." });
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

module.exports = router;