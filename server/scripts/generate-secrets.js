#!/usr/bin/env node

/**
 * Script to generate strong secrets for production use
 * 
 * Usage:
 *   node scripts/generate-secrets.js
 * 
 * This will generate:
 * - JWT_SECRET (64 characters)
 * - DB_PASSWORD (32 characters)
 */

const crypto = require('crypto');

function generateSecret(length = 64) {
    return crypto.randomBytes(Math.ceil(length * 3 / 4))
        .toString('base64')
        .slice(0, length)
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '');
}

console.log('');
console.log('🔐 ═══════════════════════════════════════════════════════════');
console.log('🔐  Strong Secrets Generator - Allo Urgence');
console.log('🔐 ═══════════════════════════════════════════════════════════');
console.log('');
console.log('⚠️  IMPORTANT: Keep these secrets safe and never commit them to git!');
console.log('');
console.log('Add these to your .env file:');
console.log('');
console.log('─────────────────────────────────────────────────────────────');
console.log(`JWT_SECRET=${generateSecret(64)}`);
console.log(`DB_PASSWORD=${generateSecret(32)}`);
console.log('─────────────────────────────────────────────────────────────');
console.log('');
console.log('✅ Secrets generated successfully!');
console.log('');
