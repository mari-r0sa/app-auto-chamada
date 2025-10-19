const express = require('express');
const app = express();
const chamadasRoutes = require('./routes/chamadas');
const usuariosRoutes  = require('./routes/usuarios');
const cors = require('cors');

app.use(cors());
app.use(express.json());
app.use('/api/chamadas', chamadasRoutes);
app.use('/api/usuarios', usuariosRoutes);

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
});