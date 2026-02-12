const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db/pg_connection');
const { authenticateToken, JWT_SECRET } = require('../middleware/auth');
const { sendMail, verificationEmail, welcomeEmail } = require('../services/mail.service');

// ── Helper: generate 6-digit verification code ──────────────────
function generateCode() {
    return String(Math.floor(100000 + Math.random() * 900000));
}

// ── POST /api/auth/register ─────────────────────────────────────
router.post('/register', async (req, res) => {
    try {
        const {
            email, password, nom, prenom, telephone,
            ramq_number, date_naissance, contact_urgence,
            allergies, conditions_medicales, medicaments,
        } = req.body;

        if (!email || !password || !nom || !prenom) {
            return res.status(400).json({ error: 'Champs obligatoires manquants' });
        }

        if (password.length < 6) {
            return res.status(400).json({ error: 'Le mot de passe doit contenir au moins 6 caractères' });
        }

        const existing = await db.findOne('users', { email });
        if (existing) {
            return res.status(409).json({ error: 'Un compte avec ce courriel existe déjà' });
        }

        const password_hash = bcrypt.hashSync(password, 10);
        const verificationCode = generateCode();
        const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h

        const user = await db.insert('users', {
            role: 'patient', email, password_hash, nom, prenom,
            telephone: telephone || null,
            ramq_number: ramq_number || null,
            date_naissance: date_naissance || null,
            contact_urgence: contact_urgence || null,
            allergies: allergies || null,
            conditions_medicales: conditions_medicales || null,
            medicaments: medicaments || null,
            email_verified: false,
            verification_code: verificationCode,
            verification_expires_at: verificationExpires.toISOString(),
        });

        // Send verification email (non-blocking)
        const emailTemplate = verificationEmail(prenom, verificationCode);
        sendMail({ to: email, ...emailTemplate })
            .then(result => {
                if (result.previewUrl) console.log(`📧 Dev preview: ${result.previewUrl}`);
            })
            .catch(err => console.error('Mail send error:', err));

        const token = jwt.sign(
            { id: user.id, role: user.role, email: user.email },
            JWT_SECRET,
            { expiresIn: '7d' },
        );

        const { password_hash: _, verification_code: __, verification_expires_at: ___, ...safeUser } = user;
        res.status(201).json({
            token,
            user: safeUser,
            message: 'Compte créé ! Un code de vérification a été envoyé à votre courriel.',
            requiresVerification: true,
        });
    } catch (err) {
        console.error('Register error:', err.message);
        res.status(500).json({ error: 'Erreur lors de l\'inscription' });
    }
});

// ── POST /api/auth/verify-email ─────────────────────────────────
router.post('/verify-email', authenticateToken, async (req, res) => {
    try {
        const { code } = req.body;
        if (!code) {
            return res.status(400).json({ error: 'Code de vérification requis' });
        }

        const user = await db.findById('users', req.user.id);
        if (!user) return res.status(404).json({ error: 'Utilisateur non trouvé' });

        if (user.email_verified) {
            return res.json({ message: 'Courriel déjà vérifié', verified: true });
        }

        if (user.verification_code !== code.trim()) {
            return res.status(400).json({ error: 'Code de vérification incorrect' });
        }

        if (user.verification_expires_at && new Date(user.verification_expires_at) < new Date()) {
            return res.status(400).json({ error: 'Code expiré, veuillez en demander un nouveau' });
        }

        await db.update('users', user.id, {
            email_verified: true,
            verification_code: null,
            verification_expires_at: null,
        });

        // Send welcome email
        const welcome = welcomeEmail(user.prenom);
        sendMail({ to: user.email, ...welcome }).catch(() => { });

        res.json({ message: 'Courriel vérifié avec succès !', verified: true });
    } catch (err) {
        console.error('Verify error:', err.message);
        res.status(500).json({ error: 'Erreur lors de la vérification' });
    }
});

// ── POST /api/auth/resend-verification ──────────────────────────
router.post('/resend-verification', authenticateToken, async (req, res) => {
    try {
        const user = await db.findById('users', req.user.id);
        if (!user) return res.status(404).json({ error: 'Utilisateur non trouvé' });

        if (user.email_verified) {
            return res.json({ message: 'Courriel déjà vérifié' });
        }

        const newCode = generateCode();
        const newExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);

        await db.update('users', user.id, {
            verification_code: newCode,
            verification_expires_at: newExpires.toISOString(),
        });

        const emailTemplate = verificationEmail(user.prenom, newCode);
        const result = await sendMail({ to: user.email, ...emailTemplate });

        res.json({
            message: 'Nouveau code envoyé',
            ...(result.previewUrl ? { previewUrl: result.previewUrl } : {}),
        });
    } catch (err) {
        console.error('Resend error:', err.message);
        res.status(500).json({ error: 'Erreur lors du renvoi' });
    }
});

// ── POST /api/auth/login ────────────────────────────────────────
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: 'Courriel et mot de passe requis' });
        }

        const user = await db.findOne('users', { email });
        if (!user || !bcrypt.compareSync(password, user.password_hash)) {
            return res.status(401).json({ error: 'Identifiants incorrects' });
        }

        const token = jwt.sign(
            { id: user.id, role: user.role, email: user.email },
            JWT_SECRET,
            { expiresIn: '7d' },
        );

        const { password_hash: _, verification_code: __, verification_expires_at: ___, ...safeUser } = user;
        res.json({ token, user: safeUser });
    } catch (err) {
        console.error('Login error:', err.message);
        res.status(500).json({ error: 'Erreur lors de la connexion' });
    }
});

// ── GET /api/auth/me ────────────────────────────────────────────
router.get('/me', authenticateToken, async (req, res) => {
    try {
        const user = await db.findById('users', req.user.id);
        if (!user) return res.status(404).json({ error: 'Utilisateur non trouvé' });
        const { password_hash: _, verification_code: __, verification_expires_at: ___, ...safeUser } = user;
        res.json(safeUser);
    } catch (err) {
        console.error('Me error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

module.exports = router;
