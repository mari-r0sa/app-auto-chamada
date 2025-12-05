const express = require('express');
const app = express();
const chamadasRoutes = require('./routes/chamadas');
const relatorioRouter = require('./routes/relatorio');
const usuariosRoutes  = require('./routes/usuarios');
const cors = require('cors');

app.use(cors());
app.use(express.json());
app.use('/api/chamadas', chamadasRoutes);
app.use('/api/usuarios', usuariosRoutes);
app.use('/api/relatorio', relatorioRouter);

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Servidor rodando em http://0.0.0.0:${PORT}`);
});