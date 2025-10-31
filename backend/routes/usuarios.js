const express = require('express');
const router = express.Router();
const dbManager = require('../db/db_manager');

// RF002: Rota de Cadastro
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

    if (!email || !senha) {
        return res.status(400).json({ erro: "E-mail e senha são obrigatórios." });
    }

    try {
        const resultado = await dbManager.loginAluno(email, senha);
        
        if (!resultado) {
            return res.status(401).json({ erro: "Credenciais inválidas." }); // 401 = Não autorizado
        }

        // Sucesso
        res.json(resultado); // Retorna { token, usuario }

    } catch (err) {
        console.error("Erro no login:", err);
        res.status(500).json({ erro: "Erro interno no servidor." });
    }
});

module.exports = router;