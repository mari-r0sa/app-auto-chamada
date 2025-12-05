// backend/routes/relatorio.js
const express = require('express');
const router = express.Router();
const db = require('../db/db_manager');
const { salvarCSVLocal } = require('../services/csv_service');

// GET /api/relatorio/hoje
router.get('/hoje', async (req, res) => {
  try {
    const registros = await db.getRelatorioHoje();
    const filePath = salvarCSVLocal(registros, 'relatorio_hoje');

    // envia como download
    return res.download(filePath, 'relatorio_hoje.csv', err => {
      if (err) {
        console.error('Erro ao enviar arquivo:', err);
        // se erro, tenta mandar JSON
        if (!res.headersSent) res.status(500).json({ erro: 'Falha ao enviar CSV.' });
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ erro: 'Falha ao gerar relatório de hoje.' });
  }
});

// GET /api/relatorio/aluno/:id
router.get('/aluno/:id', async (req, res) => {
  try {
    const alunoId = parseInt(req.params.id, 10);
    if (!alunoId) return res.status(400).json({ erro: 'ID inválido.' });

    const registros = await db.getRelatorioPorAluno(alunoId);
    const filePath = salvarCSVLocal(registros, `relatorio_aluno_${alunoId}`);

    return res.download(filePath, `relatorio_aluno_${alunoId}.csv`, err => {
      if (err) {
        console.error('Erro ao enviar arquivo:', err);
        if (!res.headersSent) res.status(500).json({ erro: 'Falha ao enviar CSV.' });
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ erro: 'Falha ao gerar relatório do aluno.' });
  }
});

// GET /api/relatorio/data/:yyyy-mm-dd
router.get('/data/:data', async (req, res) => {
  try {
    const dataString = req.params.data; // ex: 2025-12-05
    // validação simples
    if (!/^\d{4}-\d{1,2}-\d{1,2}$/.test(dataString)) {
      return res.status(400).json({ erro: 'Formato de data inválido. Use YYYY-M-D' });
    }

    const registros = await db.getRelatorioPorData(dataString);
    const safeName = dataString.replace(/[^0-9\-]/g, '');
    const filePath = salvarCSVLocal(registros, `relatorio_${safeName}`);

    return res.download(filePath, `relatorio_${safeName}.csv`, err => {
      if (err) {
        console.error('Erro ao enviar arquivo:', err);
        if (!res.headersSent) res.status(500).json({ erro: 'Falha ao enviar CSV.' });
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ erro: 'Falha ao gerar relatório por data.' });
  }
});

module.exports = router;