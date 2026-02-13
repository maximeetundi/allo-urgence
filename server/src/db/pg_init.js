const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const db = require('./pg_connection');

async function initDatabase() {
  try {
    // ── Create tables ──────────────────────────────────────────────
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        role VARCHAR(20) NOT NULL DEFAULT 'patient',
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        nom VARCHAR(100) NOT NULL,
        prenom VARCHAR(100) NOT NULL,
        telephone VARCHAR(30),
        date_naissance DATE,
        ramq_number VARCHAR(20),
        contact_urgence TEXT,
        allergies TEXT,
        conditions_medicales TEXT,
        medicaments TEXT,
        email_verified BOOLEAN DEFAULT false,
        verification_code VARCHAR(6),
        verification_expires_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS hospitals (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        address TEXT NOT NULL,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        capacity INTEGER DEFAULT 100,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS tickets (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID REFERENCES users(id),
        hospital_id UUID REFERENCES hospitals(id),
        priority_level INTEGER NOT NULL DEFAULT 5,
        validated_priority INTEGER,
        status VARCHAR(30) NOT NULL DEFAULT 'waiting',
        queue_position INTEGER,
        estimated_wait_minutes INTEGER,
        code VARCHAR(20),
        qr_code TEXT,
        assigned_room VARCHAR(50),
        shared_token VARCHAR(20),
        pre_triage_category VARCHAR(100),
        triage_answers JSONB DEFAULT '{}',
        patient_nom VARCHAR(100),
        patient_prenom VARCHAR(100),
        patient_telephone VARCHAR(30),
        allergies TEXT,
        conditions_medicales TEXT,
        date_naissance DATE,
        reminder_sent BOOLEAN DEFAULT false,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(code)
      );
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS triage_notes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ticket_id UUID REFERENCES tickets(id),
        nurse_id UUID REFERENCES users(id),
        validated_priority INTEGER,
        notes TEXT,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS device_tokens (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        token TEXT NOT NULL UNIQUE,
        platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios')),
        last_used TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_device_tokens_user 
      ON device_tokens(user_id, last_used DESC)
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS doctor_notes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ticket_id UUID REFERENCES tickets(id),
        doctor_id UUID REFERENCES users(id),
        notes TEXT,
        diagnosis TEXT,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS share_tokens (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ticket_id UUID UNIQUE REFERENCES tickets(id) ON DELETE CASCADE,
        token VARCHAR(255) UNIQUE NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL,
        revoked BOOLEAN DEFAULT false,
        created_by UUID REFERENCES users(id),
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_share_tokens_token ON share_tokens(token);
      CREATE INDEX IF NOT EXISTS idx_share_tokens_ticket ON share_tokens(ticket_id);
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS audit_log (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id VARCHAR(255),
        action VARCHAR(255),
        details TEXT,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // ── Migrations (safe for existing DBs) ────────────────────────
    await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false`);
    await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_code VARCHAR(6)`);
    await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_expires_at TIMESTAMPTZ`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS reminder_sent BOOLEAN DEFAULT false`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS triage_answers JSONB`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS estimated_priority INTEGER CHECK (estimated_priority BETWEEN 1 AND 5)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS triage_justification TEXT`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS triaged_by UUID REFERENCES users(id)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS triaged_at TIMESTAMPTZ`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS alert_acknowledged BOOLEAN DEFAULT false`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS alert_acknowledged_by UUID REFERENCES users(id)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS alert_acknowledged_at TIMESTAMPTZ`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS checked_in BOOLEAN DEFAULT false`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS checked_in_at TIMESTAMPTZ`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS checked_in_by UUID REFERENCES users(id)`);
    await db.query(`ALTER TABLE hospitals ADD COLUMN IF NOT EXISTS image_url TEXT`);
    await db.query(`ALTER TABLE hospitals ADD COLUMN IF NOT EXISTS image_url TEXT`);
    await db.query(`ALTER TABLE hospitals ADD COLUMN IF NOT EXISTS image_url TEXT`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS priority_level INTEGER DEFAULT 5`);

    // ── Fix missing columns from initial schema drift ────────────────
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS pre_triage_category VARCHAR(100)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS patient_nom VARCHAR(100)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS patient_prenom VARCHAR(100)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS patient_telephone VARCHAR(30)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS allergies TEXT`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS conditions_medicales TEXT`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS date_naissance DATE`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS qr_code TEXT`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS assigned_room VARCHAR(50)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS assigned_room VARCHAR(50)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS shared_token VARCHAR(20)`);
    await db.query(`ALTER TABLE tickets ADD COLUMN IF NOT EXISTS validated_priority INTEGER DEFAULT NULL`);

    // ── Create verification_attempts table for OTP rate limiting ───
    await db.query(`
      CREATE TABLE IF NOT EXISTS verification_attempts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        attempt_type VARCHAR(20) NOT NULL CHECK (attempt_type IN ('verify', 'resend')),
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Index for faster queries
    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_verification_attempts_user_time 
      ON verification_attempts(user_id, created_at DESC)
    `);

    // ── Create token_blacklist table for server-side logout ──────────
    await db.query(`
      CREATE TABLE IF NOT EXISTS token_blacklist (
        token TEXT PRIMARY KEY,
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
      )
    `);
    // Cleanup old tokens automatically could be done via cron or on insert
    await db.query(`DELETE FROM token_blacklist WHERE expires_at < CURRENT_TIMESTAMP`);

    // ── Seed demo data (idempotent) ────────────────────────────────
    // ── Seed demo data (idempotent checks) ─────────────────────────

    // Check if users exist
    const userCount = await db.count('users');
    const hospitalCount = await db.count('hospitals');

    if (userCount > 0 && hospitalCount > 0) {
      console.log('✅ Base de données PostgreSQL déjà initialisée (Users & Hospitals présents)');
      return;
    }

    console.log('🚀 Vérification et remplissage des données manquantes...');

    // Hospitals
    if (hospitalCount === 0) {
      console.log('🏥 Insertion des hôpitaux par défaut...');
      await db.insert('hospitals', {
        name: 'Hôpital Général de Montréal',
        address: '1650 Avenue Cedar, Montréal, QC H3G 1A4',
        latitude: 45.4735, longitude: -73.5920, capacity: 150,
        image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Montreal_General_Hospital.jpg/800px-Montreal_General_Hospital.jpg',
      });
      await db.insert('hospitals', {
        name: 'CHUM — Centre Hospitalier de l\'Université de Montréal',
        address: '1051 Rue Sanguinet, Montréal, QC H2X 3E4',
        latitude: 45.5115, longitude: -73.5572, capacity: 200,
        image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/CHUM_Phase_2.jpg/800px-CHUM_Phase_2.jpg',
      });
      await db.insert('hospitals', {
        name: 'Hôpital Sainte-Justine',
        address: '3175 Chemin de la Côte-Sainte-Catherine, Montréal, QC H3T 1C5',
        latitude: 45.5015, longitude: -73.6191, capacity: 120,
        image_url: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/H%C3%B4pital_Sainte-Justine_2017.jpg/800px-H%C3%B4pital_Sainte-Justine_2017.jpg',
      });
    }

    // Demo users
    if (userCount === 0) {
      console.log('👤 Insertion des utilisateurs de démo...');
      const hash = (pw) => bcrypt.hashSync(pw, 10);

      await db.insert('users', {
        role: 'admin', email: 'admin@allourgence.ca', password_hash: hash('admin123'),
        nom: 'Admin', prenom: 'Super', telephone: '514-555-0000',
        email_verified: true,
      });
      await db.insert('users', {
        role: 'nurse', email: 'nurse@allourgence.ca', password_hash: hash('nurse123'),
        nom: 'Tremblay', prenom: 'Marie', telephone: '514-555-0101',
        email_verified: true,
      });
      await db.insert('users', {
        role: 'doctor', email: 'doctor@allourgence.ca', password_hash: hash('doctor123'),
        nom: 'Gagnon', prenom: 'Jean', telephone: '514-555-0202',
        email_verified: true,
      });
      await db.insert('users', {
        role: 'patient', email: 'patient@test.ca', password_hash: hash('patient123'),
        nom: 'Bouchard', prenom: 'Luc', telephone: '514-555-0303',
        date_naissance: '1985-05-15', ramq_number: 'BOUL85051599',
        contact_urgence: 'Sophie Bouchard — 514-555-0304',
        email_verified: true,
      });
    }

    console.log('');
    console.log('✅ Base de données PostgreSQL initialisée');
    console.log('   👤 Admin:     admin@allourgence.ca / admin123');
    console.log('   👤 Patient:   patient@test.ca / patient123');
    console.log('   👩‍⚕️ Infirmier: nurse@allourgence.ca / nurse123');
    console.log('   👨‍⚕️ Médecin:   doctor@allourgence.ca / doctor123');
    console.log('');
  } catch (error) {
    console.error('❌ Erreur lors de l\'initialisation:', error.message);
    throw error;
  }
}

module.exports = initDatabase;
