const express = require('express');
const app = express();
const chamadasRoutes = require('./routes/chamadas');
const cors = require('cors');

app.use(cors());
app.use(express.json());
app.use('/api', chamadasRoutes);

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
});