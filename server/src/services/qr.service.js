const QRCode = require('qrcode');
const crypto = require('crypto');

/**
 * Generate QR code for ticket
 */
async function generateTicketQRCode(ticketId, hospitalId) {
    try {
        // Create unique QR data
        const qrData = {
            ticket_id: ticketId,
            hospital_id: hospitalId,
            timestamp: Date.now(),
            checksum: generateChecksum(ticketId, hospitalId),
        };

        // Generate QR code as data URL
        const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData), {
            errorCorrectionLevel: 'H',
            type: 'image/png',
            quality: 0.95,
            margin: 1,
            width: 300,
            color: {
                dark: '#000000',
                light: '#FFFFFF',
            },
        });

        return qrCodeDataURL;
    } catch (error) {
        console.error('Error generating QR code:', error);
        throw new Error('Failed to generate QR code');
    }
}

/**
 * Generate checksum for QR validation
 */
function generateChecksum(ticketId, hospitalId) {
    const data = `${ticketId}:${hospitalId}:${process.env.JWT_SECRET}`;
    return crypto.createHash('sha256').update(data).digest('hex').substring(0, 16);
}

/**
 * Validate QR code data
 */
function validateQRCode(qrData) {
    try {
        const data = typeof qrData === 'string' ? JSON.parse(qrData) : qrData;

        // Check required fields
        if (!data.ticket_id || !data.hospital_id || !data.checksum) {
            return { valid: false, error: 'Invalid QR code format' };
        }

        // Validate checksum
        const expectedChecksum = generateChecksum(data.ticket_id, data.hospital_id);
        if (data.checksum !== expectedChecksum) {
            return { valid: false, error: 'Invalid QR code checksum' };
        }

        // Check expiration (24 hours)
        const qrAge = Date.now() - data.timestamp;
        const maxAge = 24 * 60 * 60 * 1000; // 24 hours
        if (qrAge > maxAge) {
            return { valid: false, error: 'QR code expired' };
        }

        return {
            valid: true,
            ticket_id: data.ticket_id,
            hospital_id: data.hospital_id,
        };
    } catch (error) {
        return { valid: false, error: 'Failed to parse QR code' };
    }
}

module.exports = {
    generateTicketQRCode,
    validateQRCode,
    generateChecksum,
};
