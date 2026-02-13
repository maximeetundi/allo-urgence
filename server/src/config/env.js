const logger = require('../utils/logger');

// ── Environment Configuration & Validation ──────────────────────

const requiredEnvVars = [
    'NODE_ENV',
    'PORT',
    'JWT_SECRET',
    'DB_HOST',
    'DB_PORT',
    'DB_NAME',
    'DB_USER',
    'DB_PASSWORD',
];

const optionalEnvVars = [
    'API_URL',
    'JWT_EXPIRES_IN',
    'SMTP_HOST',
    'SMTP_PORT',
    'SMTP_USERNAME',
    'SMTP_PASSWORD',
    'SMTP_FROM_ADDRESS',
    'SMTP_FROM_NAME',
    'LOG_LEVEL',
];

// ── Validation Functions ────────────────────────────────────────

function validateEnvVars() {
    const missing = [];
    const warnings = [];

    // Check required variables
    for (const varName of requiredEnvVars) {
        if (!process.env[varName]) {
            missing.push(varName);
        }
    }

    if (missing.length > 0) {
        logger.error('Missing required environment variables', { missing });
        throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
    }

    // Check JWT_SECRET strength
    if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
        warnings.push('JWT_SECRET should be at least 32 characters for security');
    }

    // Warn about default/weak secrets
    const weakSecrets = [
        'secret',
        'change-me',
        'allo-urgence-secret',
        'secretpassword',
    ];

    if (process.env.JWT_SECRET && weakSecrets.some(weak => process.env.JWT_SECRET.toLowerCase().includes(weak))) {
        warnings.push('JWT_SECRET appears to be a default/weak value. Please use a strong random secret in production');
    }

    if (process.env.DB_PASSWORD && weakSecrets.some(weak => process.env.DB_PASSWORD.toLowerCase().includes(weak))) {
        warnings.push('DB_PASSWORD appears to be a default/weak value. Please use a strong password in production');
    }

    // Check NODE_ENV
    const validEnvs = ['development', 'production', 'test'];
    if (!validEnvs.includes(process.env.NODE_ENV)) {
        warnings.push(`NODE_ENV should be one of: ${validEnvs.join(', ')}`);
    }

    // Warn about missing SMTP in production
    if (process.env.NODE_ENV === 'production') {
        if (!process.env.SMTP_HOST || !process.env.SMTP_USERNAME || !process.env.SMTP_PASSWORD) {
            warnings.push('SMTP configuration missing in production. Email functionality will not work');
        }
    }

    // Log warnings
    if (warnings.length > 0) {
        warnings.forEach(warning => logger.warn('Environment warning', { warning }));
    }

    logger.info('Environment validation passed', {
        nodeEnv: process.env.NODE_ENV,
        port: process.env.PORT,
        smtpConfigured: !!(process.env.SMTP_HOST && process.env.SMTP_USERNAME),
    });
}

// ── Configuration Object ────────────────────────────────────────

const config = {
    env: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT || '3355', 10),
    apiUrl: process.env.API_URL || `http://localhost:${process.env.PORT || 3355}`,

    jwt: {
        secret: process.env.JWT_SECRET,
        expiresIn: process.env.JWT_EXPIRES_IN || '24h',
    },

    database: {
        host: process.env.DB_HOST,
        port: parseInt(process.env.DB_PORT || '5432', 10),
        name: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
    },

    smtp: {
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT || '587', 10),
        username: process.env.SMTP_USERNAME,
        password: process.env.SMTP_PASSWORD,
        fromAddress: process.env.SMTP_FROM_ADDRESS,
        fromName: process.env.SMTP_FROM_NAME || 'Allo Urgence',
    },

    logging: {
        level: process.env.LOG_LEVEL || 'info',
    },

    isDevelopment: process.env.NODE_ENV === 'development',
    isProduction: process.env.NODE_ENV === 'production',
    isTest: process.env.NODE_ENV === 'test',
};

// ── Helper: Generate Strong Secret ─────────────────────────────

function generateStrongSecret(length = 64) {
    const crypto = require('crypto');
    return crypto.randomBytes(length).toString('base64').slice(0, length);
}

module.exports = {
    validateEnvVars,
    config,
    generateStrongSecret,
};
