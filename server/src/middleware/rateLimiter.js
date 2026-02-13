const rateLimit = require('express-rate-limit');
const logger = require('../utils/logger');

// ── Rate Limiting Configuration ─────────────────────────────────

// General API rate limiter
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    message: 'Trop de requêtes depuis cette adresse IP, veuillez réessayer dans 15 minutes',
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
    handler: (req, res) => {
        logger.warn('Rate limit exceeded', {
            ip: req.ip,
            url: req.originalUrl,
        });
        res.status(429).json({
            error: 'Trop de requêtes, veuillez réessayer dans 15 minutes',
        });
    },
});

// Strict limiter for authentication endpoints (login)
const authLoginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // Limit each IP to 5 login attempts per windowMs
    skipSuccessfulRequests: true, // Don't count successful requests
    message: 'Trop de tentatives de connexion, veuillez réessayer dans 15 minutes',
    handler: (req, res) => {
        logger.warn('Login rate limit exceeded', {
            ip: req.ip,
            email: req.body?.email,
        });
        res.status(429).json({
            error: 'Trop de tentatives de connexion. Veuillez réessayer dans 15 minutes',
        });
    },
});

// Limiter for registration
const authRegisterLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 3, // Limit each IP to 3 registrations per hour
    message: 'Trop de créations de compte, veuillez réessayer dans 1 heure',
    handler: (req, res) => {
        logger.warn('Registration rate limit exceeded', {
            ip: req.ip,
            email: req.body?.email,
        });
        res.status(429).json({
            error: 'Trop de créations de compte. Veuillez réessayer dans 1 heure',
        });
    },
});

// Limiter for email verification resend
const resendVerificationLimiter = rateLimit({
    windowMs: 5 * 60 * 1000, // 5 minutes
    max: 3, // Limit each IP to 3 resends per 5 minutes
    message: 'Trop de demandes de renvoi, veuillez réessayer dans 5 minutes',
    handler: (req, res) => {
        logger.warn('Resend verification rate limit exceeded', {
            ip: req.ip,
            userId: req.user?.id,
        });
        res.status(429).json({
            error: 'Trop de demandes de renvoi. Veuillez réessayer dans 5 minutes',
        });
    },
});

// Limiter for ticket creation
const createTicketLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 10, // Limit each IP to 10 ticket creations per hour
    message: 'Trop de tickets créés, veuillez réessayer dans 1 heure',
    handler: (req, res) => {
        logger.warn('Create ticket rate limit exceeded', {
            ip: req.ip,
            userId: req.user?.id,
        });
        res.status(429).json({
            error: 'Trop de tickets créés. Veuillez réessayer dans 1 heure',
        });
    },
});

module.exports = {
    apiLimiter,
    authLoginLimiter,
    authRegisterLimiter,
    resendVerificationLimiter,
    createTicketLimiter,
};
