const express = require('express');
const router = express.Router();
const dbManager = require('../db/db_manager');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'sua_chave_secreta_aqui'; // coloque em .env para produção

// --- LOGIN ---
router.post('/usuarios/login', async (req, res) => {
    const { email, senha } = req.body;

    if (!email || !senha)
        return res.status(400).json({ erro: "E-mail e senha são obrigatórios." });

    try {
        const usuario = await dbManager.getUsuarioByEmail(email);

        if (!usuario)
            return res.status(404).json({ erro: "Usuário não encontrado." });

        const senhaValida = await bcrypt.compare(senha, usuario.senha);
        if (!senhaValida) return res.status(401).json({ erro: "Senha inválida." });

        const token = jwt.sign(
            { id: usuario.id, nome: usuario.nome, email: usuario.email },
            JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({ token, usuario: { id: usuario.id, nome: usuario.nome, email: usuario.email } });
    } catch (err) {
        console.error(err);
        res.status(500).json({ erro: "Erro ao fazer login." });
    }
});

// --- CADASTRO ---
router.post('/usuarios/cadastrar', async (req, res) => {
    const { nome, email, senha } = req.body;

    if (!nome || !email || !senha)
        return res.status(400).json({ erro: "Nome, e-mail e senha são obrigatórios." });

    try {
        const usuarioExistente = await dbManager.getUsuarioByEmail(email);
        if (usuarioExistente)
            return res.status(409).json({ erro: "E-mail já cadastrado." });

        const senhaHash = await bcrypt.hash(senha, 10);
        const novoUsuario = await dbManager.cadastrarAluno(nome, email, senhaHash);

        const token = jwt.sign(
            { id: novoUsuario.id, nome: novoUsuario.nome, email: novoUsuario.email },
            JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.status(201).json({ token, usuario: novoUsuario });
    } catch (err) {
        console.error(err);
        res.status(500).json({ erro: "Erro ao cadastrar usuário." });
    }
});

module.exports = router;