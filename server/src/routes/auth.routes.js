const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../db/connection');
const { authenticateToken, auditLog } = require('../middleware/auth');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'allo-urgence-dev-secret';
const JWT_EXPIRES = process.env.JWT_EXPIRES_IN || '24h';

// POST /api/auth/register
router.post('/register', async (req, res) => {
    try {
        const { email, password, nom, prenom, date_naissance, ramq_number, telephone, contact_urgence, allergies, conditions_medicales, medicaments } = req.body;

        if (!email || !password || !nom || !prenom) {
            return res.status(400).json({ error: 'Email, mot de passe, nom et prénom sont obligatoires' });
        }

        const existing = db.findOne('users', u => u.email === email);
        if (existing) {
            return res.status(409).json({ error: 'Cet email est déjà utilisé' });
        }

        const id = uuidv4();
        const password_hash = await bcrypt.hash(password, 10);

        db.insert('users', {
            id, role: 'patient', email, password_hash, nom, prenom,
            date_naissance: date_naissance || null,
            ramq_number: ramq_number || null,
            telephone: telephone || null,
            contact_urgence: contact_urgence || null,
            allergies: allergies || null,
            conditions_medicales: conditions_medicales || null,
            medicaments: medicaments || null,
            created_at: new Date().toISOString()
        });

        const token = jwt.sign({ id, role: 'patient', email, nom, prenom }, JWT_SECRET, { expiresIn: JWT_EXPIRES });

        res.status(201).json({
            message: 'Compte créé avec succès',
            token,
            user: { id, role: 'patient', email, nom, prenom }
        });
    } catch (err) {
        console.error('Register error:', err);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: 'Email et mot de passe requis' });
        }

        const user = db.findOne('users', u => u.email === email);
        if (!user) return res.status(401).json({ error: 'Identifiants invalides' });

        const valid = await bcrypt.compare(password, user.password_hash);
        if (!valid) return res.status(401).json({ error: 'Identifiants invalides' });

        const token = jwt.sign(
            { id: user.id, role: user.role, email: user.email, nom: user.nom, prenom: user.prenom },
            JWT_SECRET, { expiresIn: JWT_EXPIRES }
        );

        auditLog('login', user.id, { email: user.email, role: user.role });

        res.json({
            token,
            user: { id: user.id, role: user.role, email: user.email, nom: user.nom, prenom: user.prenom }
        });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// GET /api/auth/me
router.get('/me', authenticateToken, (req, res) => {
    const user = db.findById('users', req.user.id);
    if (!user) return res.status(404).json({ error: 'Utilisateur non trouvé' });

    const { password_hash, ...safeUser } = user;
    res.json(safeUser);
});

module.exports = router;
