const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const db = require('./pg_connection');

async function initDatabase() {
  try {
    // Vérifier si la base a déjà des données
    const userCount = await db.count('users');
    if (userCount > 0) {
      console.log('✅ Base de données PostgreSQL déjà initialisée');
      return;
    }

    console.log('🚀 Initialisation de la base de données PostgreSQL...');

    // Insérer les hôpitaux
    await db.insert('hospitals', {
      name: 'Hôpital Général de Montréal',
      address: '1650 Avenue Cedar, Montréal, QC H3G 1A4',
      latitude: 45.4735,
      longitude: -73.5920,
      capacity: 150,
    });

    await db.insert('hospitals', {
      name: 'CHUM - Centre Hospitalier de l\'Université de Montréal',
      address: '1051 Rue Sanguinet, Montréal, QC H2X 3E4',
      latitude: 45.5115,
      longitude: -73.5572,
      capacity: 200,
    });

    await db.insert('hospitals', {
      name: 'Hôpital Sainte-Justine',
      address: '3175 Chemin de la Côte-Sainte-Catherine, Montréal, QC H3T 1C5',
      latitude: 45.5015,
      longitude: -73.6191,
      capacity: 120,
    });

    // Créer les comptes de démo
    const adminHash = bcrypt.hashSync('admin123', 10);
    const nurseHash = bcrypt.hashSync('nurse123', 10);
    const doctorHash = bcrypt.hashSync('doctor123', 10);
    const patientHash = bcrypt.hashSync('patient123', 10);

    await db.insert('users', {
      role: 'admin',
      email: 'admin@allourgence.ca',
      password_hash: adminHash,
      nom: 'Admin',
      prenom: 'Super',
      telephone: '514-555-0000',
    });

    await db.insert('users', {
      role: 'nurse',
      email: 'nurse@allourgence.ca',
      password_hash: nurseHash,
      nom: 'Tremblay',
      prenom: 'Marie',
      telephone: '514-555-0101',
    });

    await db.insert('users', {
      role: 'doctor',
      email: 'doctor@allourgence.ca',
      password_hash: doctorHash,
      nom: 'Gagnon',
      prenom: 'Jean',
      telephone: '514-555-0202',
    });

    await db.insert('users', {
      role: 'patient',
      email: 'patient@test.ca',
      password_hash: patientHash,
      nom: 'Bouchard',
      prenom: 'Luc',
      telephone: '514-555-0303',
      date_naissance: '1985-05-15',
      ramq_number: 'BOUL85051599',
      contact_urgence: 'Sophie Bouchard - 514-555-0304',
    });

    console.log('');
    console.log('✅ Base de données PostgreSQL initialisée avec données de démo');
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
