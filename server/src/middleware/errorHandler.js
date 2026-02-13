const logger = require('../utils/logger');
const { AppError } = require('../utils/errors');

// ── Error Handler Middleware ────────────────────────────────────
function errorHandler(err, req, res, next) {
    let error = { ...err };
    error.message = err.message;
    error.stack = err.stack;

    // Log error
    logger.error('Error occurred', {
        message: err.message,
        stack: err.stack,
        url: req.originalUrl,
        method: req.method,
        ip: req.ip,
        userId: req.user?.id,
    });

    // Mongoose bad ObjectId
    if (err.name === 'CastError') {
        const message = 'Ressource non trouvée';
        error = new AppError(message, 404);
    }

    // Mongoose duplicate key
    if (err.code === 11000) {
        const message = 'Cette valeur existe déjà';
        error = new AppError(message, 409);
    }

    // Mongoose validation error
    if (err.name === 'ValidationError') {
        const message = Object.values(err.errors).map(val => val.message).join(', ');
        error = new AppError(message, 400);
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        const message = 'Token invalide';
        error = new AppError(message, 401);
    }

    if (err.name === 'TokenExpiredError') {
        const message = 'Token expiré';
        error = new AppError(message, 401);
    }

    // Joi validation error
    if (err.isJoi) {
        const message = err.details.map(detail => detail.message).join(', ');
        error = new AppError(message, 400);
    }

    // Send response
    const statusCode = error.statusCode || 500;
    const message = error.message || 'Erreur interne du serveur';

    res.status(statusCode).json({
        error: message,
        ...(process.env.NODE_ENV === 'development' && { stack: error.stack }),
    });
}

// ── 404 Handler ─────────────────────────────────────────────────
function notFoundHandler(req, res, next) {
    const error = new AppError(`Route non trouvée: ${req.originalUrl}`, 404);
    next(error);
}

module.exports = { errorHandler, notFoundHandler };
