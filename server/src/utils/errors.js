// ── Custom Error Classes ────────────────────────────────────────

class AppError extends Error {
    constructor(message, statusCode, isOperational = true) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = isOperational;
        this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
        Error.captureStackTrace(this, this.constructor);
    }
}

class ValidationError extends AppError {
    constructor(message) {
        super(message, 400);
    }
}

class AuthenticationError extends AppError {
    constructor(message = 'Non authentifié') {
        super(message, 401);
    }
}

class AuthorizationError extends AppError {
    constructor(message = 'Non autorisé') {
        super(message, 403);
    }
}

class NotFoundError extends AppError {
    constructor(message = 'Ressource non trouvée') {
        super(message, 404);
    }
}

class ConflictError extends AppError {
    constructor(message) {
        super(message, 409);
    }
}

class RateLimitError extends AppError {
    constructor(message = 'Trop de requêtes, veuillez réessayer plus tard') {
        super(message, 429);
    }
}

module.exports = {
    AppError,
    ValidationError,
    AuthenticationError,
    AuthorizationError,
    NotFoundError,
    ConflictError,
    RateLimitError,
};
