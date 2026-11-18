const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
app.use(express.json());

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

// L'API répond
app.get('/', (req, res) => {
  res.json({ message: 'API DepotExpresse OK' });
});

// Test de la connexion à MySQL
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ api: 'ok', database: 'ok' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ api: 'ok', database: 'erreur' });
  }
});

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => console.log(`API démarrée sur le port ${port}`));
