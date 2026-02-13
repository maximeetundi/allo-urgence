const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db/pg_connection');
const { authenticateToken, JWT_SECRET } = require('../middleware/auth');
const { sendMail, verificationEmail, welcomeEmail } = require('../services/mail.service');
const { validate } = require('../middleware/validation');
const { registerSchema, loginSchema, verifyEmailSchema, updateEmailSchema, updateUserSchema } = require('../schemas/auth.schema');
const { authLoginLimiter, authRegisterLimiter, resendVerificationLimiter } = require('../middleware/rateLimiter');
const { otpVerificationLimiter, otpResendLimiter } = require('../middleware/otpLimiter');
const logger = require('../utils/logger');
const { ConflictError, ValidationError } = require('../utils/errors');

// ── Helper: generate 6-digit verification code ──────────────────
function generateCode() {
    return String(Math.floor(100000 + Math.random() * 900000));
}

// ── POST /api/auth/register ─────────────────────────────────────
router.post('/register', authRegisterLimiter, validate(registerSchema), async (req, res, next) => {
    try {
        const {
            email, password, nom, prenom, telephone,
            ramq_number, date_naissance, contact_urgence,
            allergies, conditions_medicales, medicaments,
        } = req.body;

        if (!email || !password || !nom || !prenom) {
            return res.status(400).json({ error: 'Champs obligatoires manquants' });
        }

        // Email validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ error: 'Format de courriel invalide' });
        }

        // Phone validation (if provided)
        if (telephone && !/^\d{10,15}$/.test(telephone.replace(/[\s\-\(\)\+]/g, ''))) {
            return res.status(400).json({ error: 'Numéro de téléphone invalide' });
        }

        if (password.length < 6) {
            return res.status(400).json({ error: 'Le mot de passe doit contenir au moins 6 caractères' });
        }

        const existing = await db.findOne('users', { email });
        if (existing) {
            throw new ConflictError('Un compte avec ce courriel existe déjà');
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
                if (result.previewUrl) logger.info('Email preview', { url: result.previewUrl });
            })
            .catch(err => logger.error('Mail send error', { error: err.message }));

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
        next(err);
    }
});

// ── POST /api/auth/verify-email ─────────────────────────────────
router.post('/verify-email', authenticateToken, otpVerificationLimiter, validate(verifyEmailSchema), async (req, res, next) => {
    try {
        const { code } = req.body;

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
        next(err);
    }
});

// ── POST /api/auth/resend-verification ──────────────────────────
router.post('/resend-verification', authenticateToken, resendVerificationLimiter, otpResendLimiter, async (req, res, next) => {
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
        });
    } catch (err) {
        next(err);
    }
});

// ── PUT /api/auth/update-email ──────────────────────────────────
router.put('/update-email', authenticateToken, validate(updateEmailSchema), async (req, res, next) => {
    try {
        const { newEmail } = req.body;

        const user = await db.findById('users', req.user.id);
        if (!user) return res.status(404).json({ error: 'Utilisateur non trouvé' });

        if (user.email_verified) {
            return res.status(403).json({ error: 'Compte déjà vérifié, modification impossible ici.' });
        }

        const existing = await db.findOne('users', { email: newEmail });
        if (existing) {
            throw new ConflictError('Cet email est déjà utilisé');
        }

        const newCode = generateCode();
        const newExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);

        await db.update('users', user.id, {
            email: newEmail,
            verification_code: newCode,
            verification_expires_at: newExpires.toISOString(),
        });

        // Send new code
        const emailTemplate = verificationEmail(user.prenom, newCode);
        const result = await sendMail({ to: newEmail, ...emailTemplate });

        res.json({
            message: 'Email mis à jour et code renvoyé',
            user: { ...user, email: newEmail },
        });
    } catch (err) {
        next(err);
    }
});

// ── POST /api/auth/login ────────────────────────────────────────
router.post('/login', authLoginLimiter, validate(loginSchema), async (req, res, next) => {
    try {
        const { email, password, client } = req.body;

        const user = await db.findOne('users', { email });
        if (!user || !bcrypt.compareSync(password, user.password_hash)) {
            return res.status(401).json({ error: 'Identifiants incorrects' });
        }

        // Role restriction based on client
        if (client === 'admin') {
            if (user.role !== 'admin') {
                // Return same error as invalid credentials for security
                return res.status(401).json({ error: 'Identifiants incorrects' });
            }
        } else if (client === 'mobile') {
            if (user.role === 'admin') {
                return res.status(401).json({ error: 'Identifiants incorrects' });
            }
        }
        // If no client specified, fallback to permissive or default? 
        // For now, let's assume if no client is sent, we default to mobile behavior (block admin) 
        // or just leave it for backward compatibility until all clients are updated.
        // Given the requirement "bloquer des 2 cotes", let's enforce it.
        // If client is missing, we can assume it's mobile (legacy).
        else {
            if (user.role === 'admin') {
                return res.status(401).json({ error: 'Identifiants incorrects' });
            }
        }

        const token = jwt.sign(
            { id: user.id, role: user.role, email: user.email },
            JWT_SECRET,
            { expiresIn: '7d' },
        );

        const { password_hash: _, verification_code: __, verification_expires_at: ___, ...safeUser } = user;
        res.json({ token, user: safeUser });
    } catch (err) {
        next(err);
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
        next(err);
    }
});

// ── PUT /api/auth/me ────────────────────────────────────────────
// Update user profile (excluding email/password)
router.put('/me', authenticateToken, validate(updateUserSchema), async (req, res, next) => {
    try {
        const userId = req.user.id;
        const updates = req.body;

        // Prevent updating restricted fields through this endpoint
        delete updates.email;
        delete updates.password;
        delete updates.role;
        delete updates.id;
        delete updates.email_verified;

        const user = await db.findById('users', userId);
        if (!user) return res.status(404).json({ error: 'Utilisateur non trouvé' });

        const updatedUser = await db.update('users', userId, updates);

        const { password_hash: _, verification_code: __, verification_expires_at: ___, ...safeUser } = updatedUser;
        res.json({
            message: 'Profil mis à jour avec succès',
            user: safeUser
        });
    } catch (err) {
        next(err);
    }
});

module.exports = router;
