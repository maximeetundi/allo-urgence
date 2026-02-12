const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'allourgence',
  host: process.env.DB_HOST || 'db',
  database: process.env.DB_NAME || 'allourgence',
  password: process.env.DB_PASSWORD || 'secretpassword',
  port: process.env.DB_PORT || 5432,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test de connexion
pool.on('connect', () => {
  console.log('🔌 Connecté à PostgreSQL');
});

pool.on('error', (err) => {
  console.error('❌ Erreur de connexion PostgreSQL:', err.message);
});

// Helper pour les requêtes
class Database {
  async query(text, params) {
    const start = Date.now();
    try {
      const res = await pool.query(text, params);
      const duration = Date.now() - start;
      console.log('📊 Query executed', { duration, rows: res.rowCount });
      return res;
    } catch (error) {
      console.error('❌ Query error:', error.message);
      throw error;
    }
  }

  async insert(table, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');
    
    const query = `
      INSERT INTO ${table} (${columns.join(', ')})
      VALUES (${placeholders})
      RETURNING *
    `;
    
    const result = await this.query(query, values);
    return result.rows[0];
  }

  async findById(table, id) {
    const query = `SELECT * FROM ${table} WHERE id = $1`;
    const result = await this.query(query, [id]);
    return result.rows[0] || null;
  }

  async findOne(table, conditions) {
    const columns = Object.keys(conditions);
    const values = Object.values(conditions);
    const whereClause = columns.map((col, i) => `${col} = $${i + 1}`).join(' AND ');
    
    const query = `SELECT * FROM ${table} WHERE ${whereClause}`;
    const result = await this.query(query, values);
    return result.rows[0] || null;
  }

  async findMany(table, conditions = null, orderBy = null, limit = null) {
    let query = `SELECT * FROM ${table}`;
    const values = [];
    
    if (conditions) {
      const columns = Object.keys(conditions);
      const whereClause = columns.map((col, i) => `${col} = $${i + 1}`).join(' AND ');
      query += ` WHERE ${whereClause}`;
      values.push(...Object.values(conditions));
    }
    
    if (orderBy) {
      query += ` ORDER BY ${orderBy}`;
    }
    
    if (limit) {
      query += ` LIMIT ${limit}`;
    }
    
    const result = await this.query(query, values);
    return result.rows;
  }

  async update(table, id, data) {
    const columns = Object.keys(data);
    const values = Object.values(data);
    const setClause = columns.map((col, i) => `${col} = $${i + 2}`).join(', ');
    
    const query = `
      UPDATE ${table}
      SET ${setClause}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;
    
    const result = await this.query(query, [id, ...values]);
    return result.rows[0] || null;
  }

  async delete(table, id) {
    const query = `DELETE FROM ${table} WHERE id = $1 RETURNING *`;
    const result = await this.query(query, [id]);
    return result.rows[0] || null;
  }

  async count(table, conditions = null) {
    let query = `SELECT COUNT(*) as count FROM ${table}`;
    const values = [];
    
    if (conditions) {
      const columns = Object.keys(conditions);
      const whereClause = columns.map((col, i) => `${col} = $${i + 1}`).join(' AND ');
      query += ` WHERE ${whereClause}`;
      values.push(...Object.values(conditions));
    }
    
    const result = await this.query(query, values);
    return parseInt(result.rows[0].count);
  }

  async close() {
    await pool.end();
  }
}

const db = new Database();
module.exports = db;
