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

    // ✅ SECURITY: Whitelist allowed columns for ORDER BY
    if (orderBy) {
      const allowedColumns = ['id', 'created_at', 'updated_at', 'priority', 'status', 'nom', 'prenom', 'email', 'name'];
      const parts = orderBy.trim().split(/\s+/);
      const column = parts[0];
      const direction = (parts[1] || 'ASC').toUpperCase();

      if (!allowedColumns.includes(column)) {
        throw new Error(`Invalid order column: ${column}`);
      }

      if (!['ASC', 'DESC'].includes(direction)) {
        throw new Error(`Invalid order direction: ${direction}`);
      }

      query += ` ORDER BY ${column} ${direction}`;
    }

    // ✅ SECURITY: Validate LIMIT is a safe integer
    if (limit) {
      const limitNum = parseInt(limit, 10);
      if (isNaN(limitNum) || limitNum < 1 || limitNum > 1000) {
        throw new Error('Invalid limit value (must be 1-1000)');
      }
      query += ` LIMIT ${limitNum}`;
    }

    const result = await this.query(query, values);
    return result.rows;
  }

  async findWithPagination(table, { page = 1, limit = 20, search = '', searchColumns = [], orderBy = 'id DESC' }) {
    const offset = (page - 1) * limit;
    const values = [];
    let query = `SELECT * FROM ${table}`;
    let countQuery = `SELECT COUNT(*) as total FROM ${table}`;

    let whereClause = '';
    if (search && searchColumns.length > 0) {
      whereClause = ' WHERE ' + searchColumns.map((col, i) => `${col} ILIKE $${i + 1}`).join(' OR ');
      values.push(...searchColumns.map(() => `%${search}%`));
    }

    query += whereClause;
    countQuery += whereClause;

    // Order By
    query += ` ORDER BY ${orderBy}`;

    // Pagination
    query += ` LIMIT $${values.length + 1} OFFSET $${values.length + 2}`;
    values.push(limit, offset);

    const [rowsResult, countResult] = await Promise.all([
      this.query(query, values),
      this.query(countQuery, values.slice(0, values.length - 2)) // Remove limit/offset for count
    ]);

    return {
      data: rowsResult.rows,
      meta: {
        total: parseInt(countResult.rows[0].total),
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(parseInt(countResult.rows[0].total) / limit)
      }
    };
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
