// backend/services/csv_service.js
const fs = require('fs');
const path = require('path');

// Gera string CSV a partir de array de objetos
function gerarCSVString(registros) {
  if (!registros || registros.length === 0) return '';

  const headers = Object.keys(registros[0]);
  const lines = [];

  // header com ';'
  lines.push(headers.join(';'));

  for (const row of registros) {
    const cols = headers.map(h => {
      const v = row[h] == null ? '' : String(row[h]);
      const escaped = v.replace(/"/g, '""');
      return `"${escaped}"`;
    });
    lines.push(cols.join(';'));
  }

  return lines.join('\n') + '\n';
}

// Salva arquivo CSV no servidor e retorna caminho absoluto
function salvarCSVLocal(registros, nomeArquivo) {
  const csv = gerarCSVString(registros);

  // BOM para Excel
  const bom = Buffer.from([0xEF, 0xBB, 0xBF]);
  const csvBuf = Buffer.from(csv, 'utf8');
  const finalBuf = Buffer.concat([bom, csvBuf]);

  const pastaDownloads = path.join(__dirname, '..', 'downloads');
  if (!fs.existsSync(pastaDownloads)) {
    fs.mkdirSync(pastaDownloads, { recursive: true });
  }

  const filePath = path.join(pastaDownloads, `${nomeArquivo}.csv`);
  fs.writeFileSync(filePath, finalBuf);

  return filePath;
}

module.exports = {
  gerarCSVString,
  salvarCSVLocal
};