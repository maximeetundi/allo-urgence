const cron = require('node-cron');
const db = require('../db/pg_connection');
const mailService = require('./mail.service');

/**
 * Initializes all cron jobs
 */
function initCron() {
    console.log('⏰ Initialisation du service de tâches planifiées (Cron)...');

    // Check for tickets needing reminders every minute
    cron.schedule('* * * * *', async () => {
        try {
            // Find tickets: waiting, wait time <= 45 min, reminder not sent
            const query = `
        SELECT t.id, t.estimated_wait_minutes, t.queue_position, u.email, u.prenom, u.nom, h.name as hospital_name
        FROM tickets t
        JOIN users u ON t.patient_id = u.id
        JOIN hospitals h ON t.hospital_id = h.id
        WHERE t.status = 'waiting'
          AND t.estimated_wait_minutes <= 45
          AND t.estimated_wait_minutes > 0
          AND (t.reminder_sent IS FALSE OR t.reminder_sent IS NULL)
      `;

            const { rows: tickets } = await db.query(query);

            if (tickets.length > 0) {
                console.log(`⏰ Cron: ${tickets.length} rappels à envoyer.`);

                for (const t of tickets) {
                    // Send email
                    const subject = `🏥 Rappel : Votre tour approche (${t.estimated_wait_minutes} min)`;
                    const html = `
            <div style="font-family: Arial, sans-serif; color: #333;">
              <h2 style="color: #3b82f6;">Allo Urgence - Rappel</h2>
              <p>Bonjour <strong>${t.prenom}</strong>,</p>
              <p>Ceci est un rappel automatisé concernant votre visite à <strong>${t.hospital_name}</strong>.</p>
              
              <div style="background-color: #f3f4f6; padding: 15px; border-radius: 10px; margin: 20px 0;">
                <p style="margin: 5px 0;">⏳ Temps d'attente estimé : <strong>${t.estimated_wait_minutes} minutes</strong></p>
                <p style="margin: 5px 0;">👥 Position dans la file : <strong>${t.queue_position}</strong></p>
              </div>

              <p>Nous vous recommandons de vous diriger vers la salle d'attente si ce n'est pas déjà fait.</p>
              <p>À bientôt,<br>L'équipe Allo Urgence</p>
            </div>
          `;

                    try {
                        await mailService.sendMail(t.email, subject, html);
                        // Update reminder_sent
                        await db.query(`UPDATE tickets SET reminder_sent = TRUE WHERE id = $1`, [t.id]);
                        console.log(`✅ Rappel envoyé à ${t.email}`);
                    } catch (err) {
                        console.error(`❌ Erreur envoi rappel à ${t.email}:`, err.message);
                    }
                }
            }
        } catch (error) {
            console.error('❌ Erreur Cron Job:', error.message);
        }
    });

    // ── Cleanup old verification attempts (daily at 3 AM) ───────────
    cron.schedule('0 3 * * *', async () => {
        console.log('🧹 Running verification attempts cleanup...');
        const { cleanupOldAttempts } = require('../middleware/otpLimiter');
        await cleanupOldAttempts();
    });

    console.log('✅ Cron jobs initialized');
}

module.exports = { initCron };
