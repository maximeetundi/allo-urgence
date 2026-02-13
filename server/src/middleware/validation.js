const { ValidationError } = require('../utils/errors');

// ── Validation Middleware ───────────────────────────────────────
function validate(schema, property = 'body') {
    return (req, res, next) => {
        const { error, value } = schema.validate(req[property], {
            abortEarly: false, // Return all errors, not just the first one
            stripUnknown: true, // Remove unknown fields
        });

        if (error) {
            const message = error.details.map(detail => detail.message).join(', ');
            return next(new ValidationError(message));
        }

        // Replace request data with validated and sanitized data
        req[property] = value;
        next();
    };
}

module.exports = { validate };
