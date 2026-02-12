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
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
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

    // ── Seed demo data (idempotent) ────────────────────────────────
    const userCount = await db.count('users');
    if (userCount > 0) {
      console.log('✅ Base de données PostgreSQL déjà initialisée');
      return;
    }

    console.log('🚀 Initialisation de la base de données PostgreSQL…');

    // Hospitals
    await db.insert('hospitals', {
      name: 'Hôpital Général de Montréal',
      address: '1650 Avenue Cedar, Montréal, QC H3G 1A4',
      latitude: 45.4735, longitude: -73.5920, capacity: 150,
    });
    await db.insert('hospitals', {
      name: 'CHUM — Centre Hospitalier de l\'Université de Montréal',
      address: '1051 Rue Sanguinet, Montréal, QC H2X 3E4',
      latitude: 45.5115, longitude: -73.5572, capacity: 200,
    });
    await db.insert('hospitals', {
      name: 'Hôpital Sainte-Justine',
      address: '3175 Chemin de la Côte-Sainte-Catherine, Montréal, QC H3T 1C5',
      latitude: 45.5015, longitude: -73.6191, capacity: 120,
    });

    // Demo users
    const hash = (pw) => bcrypt.hashSync(pw, 10);

    await db.insert('users', {
      role: 'admin', email: 'admin@allourgence.ca', password_hash: hash('admin123'),
      nom: 'Admin', prenom: 'Super', telephone: '514-555-0000',
    });
    await db.insert('users', {
      role: 'nurse', email: 'nurse@allourgence.ca', password_hash: hash('nurse123'),
      nom: 'Tremblay', prenom: 'Marie', telephone: '514-555-0101',
    });
    await db.insert('users', {
      role: 'doctor', email: 'doctor@allourgence.ca', password_hash: hash('doctor123'),
      nom: 'Gagnon', prenom: 'Jean', telephone: '514-555-0202',
    });
    await db.insert('users', {
      role: 'patient', email: 'patient@test.ca', password_hash: hash('patient123'),
      nom: 'Bouchard', prenom: 'Luc', telephone: '514-555-0303',
      date_naissance: '1985-05-15', ramq_number: 'BOUL85051599',
      contact_urgence: 'Sophie Bouchard — 514-555-0304',
    });

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
