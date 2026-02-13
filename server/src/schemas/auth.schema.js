const Joi = require('joi');

// ── Auth Schemas ────────────────────────────────────────────────

const registerSchema = Joi.object({
    email: Joi.string().email().required().messages({
        'string.email': 'Email invalide',
        'any.required': 'Email requis',
    }),
    password: Joi.string().min(8).required().messages({
        'string.min': 'Le mot de passe doit contenir au moins 8 caractères',
        'any.required': 'Mot de passe requis',
    }),
    nom: Joi.string().min(2).max(100).required().messages({
        'string.min': 'Le nom doit contenir au moins 2 caractères',
        'string.max': 'Le nom ne peut pas dépasser 100 caractères',
        'any.required': 'Nom requis',
    }),
    prenom: Joi.string().min(2).max(100).required().messages({
        'string.min': 'Le prénom doit contenir au moins 2 caractères',
        'string.max': 'Le prénom ne peut pas dépasser 100 caractères',
        'any.required': 'Prénom requis',
    }),
    telephone: Joi.string().pattern(/^[0-9+\-\s()]+$/).optional().allow(null, '').messages({
        'string.pattern.base': 'Numéro de téléphone invalide',
    }),
    ramq_number: Joi.string().optional().allow(null, ''),
    date_naissance: Joi.date().optional().allow(null, ''),
    contact_urgence: Joi.string().optional().allow(null, ''),
    allergies: Joi.string().optional().allow(null, ''),
    conditions_medicales: Joi.string().optional().allow(null, ''),
    medicaments: Joi.string().optional().allow(null, ''),
});

const loginSchema = Joi.object({
    email: Joi.string().email().required().messages({
        'string.email': 'Email invalide',
        'any.required': 'Email requis',
    }),
    password: Joi.string().required().messages({
        'any.required': 'Mot de passe requis',
    }),
});

const verifyEmailSchema = Joi.object({
    code: Joi.string().length(6).pattern(/^[0-9]+$/).required().messages({
        'string.length': 'Le code doit contenir 6 chiffres',
        'string.pattern.base': 'Le code doit contenir uniquement des chiffres',
        'any.required': 'Code de vérification requis',
    }),
});

const updateEmailSchema = Joi.object({
    newEmail: Joi.string().email().required().messages({
        'string.email': 'Email invalide',
        'any.required': 'Nouvel email requis',
    }),
});

const updateUserSchema = Joi.object({
    nom: Joi.string().min(2).max(100).optional().messages({
        'string.min': 'Le nom doit contenir au moins 2 caractères',
        'string.max': 'Le nom ne peut pas dépasser 100 caractères',
    }),
    prenom: Joi.string().min(2).max(100).optional().messages({
        'string.min': 'Le prénom doit contenir au moins 2 caractères',
        'string.max': 'Le prénom ne peut pas dépasser 100 caractères',
    }),
    telephone: Joi.string().pattern(/^[0-9+\-\s()]+$/).optional().allow(null, '').messages({
        'string.pattern.base': 'Numéro de téléphone invalide',
    }),
    ramq_number: Joi.string().optional().allow(null, ''),
    date_naissance: Joi.date().optional().allow(null, ''),
    contact_urgence: Joi.string().optional().allow(null, ''),
    allergies: Joi.string().optional().allow(null, ''),
    conditions_medicales: Joi.string().optional().allow(null, ''),
    medicaments: Joi.string().optional().allow(null, ''),
});

module.exports = {
    registerSchema,
    loginSchema,
    verifyEmailSchema,
    updateEmailSchema,
    updateUserSchema,
};
