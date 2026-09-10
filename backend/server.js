require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');
const os = require('os');

const app = express();
app.use(express.json());

const PORT = process.env.APP_PORT || 5000;

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Redis client
const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT,
  },
});
redisClient.on('error', (err) => console.error('Redis error:', err));
redisClient.connect();

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', servedBy: os.hostname() });
});

app.get('/products', async (req, res) => {
  try {
    const cached = await redisClient.get('products');
    if (cached) {
      return res.json({ source: 'cache', data: JSON.parse(cached) });
    }

    const result = await pool.query('SELECT * FROM products ORDER BY id');
    await redisClient.set('products', JSON.stringify(result.rows), { EX: 30 });

    res.json({ source: 'database', data: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Something went wrong' });
  }
});

app.post('/products', async (req, res) => {
  try {
    const { name, price } = req.body;
    const result = await pool.query(
      'INSERT INTO products (name, price) VALUES ($1, $2) RETURNING *',
      [name, price]
    );
    await redisClient.del('products'); // invalidate cache
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Something went wrong' });
  }
});

app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});