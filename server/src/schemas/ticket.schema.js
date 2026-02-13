const Joi = require('joi');

// ── Ticket Schemas ──────────────────────────────────────────────

const createTicketSchema = Joi.object({
    hospital_id: Joi.string().uuid().required().messages({
        'string.guid': 'ID hôpital invalide',
        'any.required': 'ID hôpital requis',
    }),
    category_id: Joi.string().required().messages({
        'any.required': 'Catégorie requise',
    }),
    triage_answers: Joi.object().optional(),
    symptoms: Joi.string().max(1000).optional().allow('').messages({
        'string.max': 'La description des symptômes ne peut pas dépasser 1000 caractères',
    }),
});

const updateTicketStatusSchema = Joi.object({
    status: Joi.string().valid('waiting', 'checked_in', 'triaged', 'in_progress', 'completed').optional().messages({
        'any.only': 'Statut invalide',
    }),
    validated_priority: Joi.number().integer().min(1).max(5).optional().messages({
        'number.min': 'La priorité doit être entre 1 et 5',
        'number.max': 'La priorité doit être entre 1 et 5',
    }),
    notes: Joi.string().max(2000).optional().allow('').messages({
        'string.max': 'Les notes ne peuvent pas dépasser 2000 caractères',
    }),
    diagnosis: Joi.string().max(2000).optional().allow('').messages({
        'string.max': 'Le diagnostic ne peut pas dépasser 2000 caractères',
    }),
    room: Joi.string().max(50).optional().allow('').messages({
        'string.max': 'Le numéro de salle ne peut pas dépasser 50 caractères',
    }),
});

const triageSchema = Joi.object({
    validated_priority: Joi.number().integer().min(1).max(5).required().messages({
        'number.min': 'La priorité doit être entre 1 et 5',
        'number.max': 'La priorité doit être entre 1 et 5',
        'any.required': 'Priorité validée requise',
    }),
    notes: Joi.string().max(2000).optional().allow('').messages({
        'string.max': 'Les notes ne peuvent pas dépasser 2000 caractères',
    }),
});

const assignRoomSchema = Joi.object({
    room: Joi.string().max(50).required().messages({
        'string.max': 'Le numéro de salle ne peut pas dépasser 50 caractères',
        'any.required': 'Numéro de salle requis',
    }),
});

const doctorNoteSchema = Joi.object({
    notes: Joi.string().max(2000).optional().allow('').messages({
        'string.max': 'Les notes ne peuvent pas dépasser 2000 caractères',
    }),
    diagnosis: Joi.string().max(2000).optional().allow('').messages({
        'string.max': 'Le diagnostic ne peut pas dépasser 2000 caractères',
    }),
});

module.exports = {
    createTicketSchema,
    updateTicketStatusSchema,
    triageSchema,
    assignRoomSchema,
    doctorNoteSchema,
};
