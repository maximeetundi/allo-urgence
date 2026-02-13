require('dotenv').config();
const db = require('../db/pg_connection');

async function fixDatabase() {
    console.log('🔧 Running database schema fix...');
    try {
        // Add missing columns if they don't exist
        await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false`);
        await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_code VARCHAR(6)`);
        await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_expires_at TIMESTAMPTZ`);

        // Check if it worked
        const result = await db.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name='users' AND column_name='email_verified'
    `);

        if (result.rows.length > 0) {
            console.log('✅ Column email_verified exists!');
        } else {
            console.error('❌ Failed to add column email_verified');
        }

        console.log('✅ Database fix completed.');
        process.exit(0);
    } catch (err) {
        console.error('❌ Error executing fix:', err);
        process.exit(1);
    }
}

fixDatabase();
