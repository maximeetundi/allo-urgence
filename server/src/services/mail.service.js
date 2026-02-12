const nodemailer = require('nodemailer');

// ── Mail configuration ──────────────────────────────────────────
// By default uses Ethereal (fake SMTP for development).
// For production, set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS in .env
// Supports: Gmail, Outlook, SendGrid, Mailgun, OVH, custom SMTP

let transporter = null;

async function getTransporter() {
  if (transporter) return transporter;

  const host = process.env.SMTP_HOST;
  const port = parseInt(process.env.SMTP_PORT || '587');
  const user = process.env.SMTP_USERNAME;
  const pass = process.env.SMTP_PASSWORD;
  const fromEmail = process.env.SMTP_FROM_ADDRESS;
  const fromName = process.env.SMTP_FROM_NAME || 'Allo Urgence';

  if (host && user && pass) {
    // Production SMTP
    transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    });
    console.log(`📧 Mail configuré: ${host}:${port} (${user})`);
  } else {
    // Dev fallback: Ethereal test account
    const testAccount = await nodemailer.createTestAccount();
    transporter = nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false,
      auth: { user: testAccount.user, pass: testAccount.pass },
    });
    console.log(`📧 Mail dev (Ethereal): ${testAccount.user}`);
    console.log(`   Preview: https://ethereal.email/login`);
  }

  return transporter;
}

// ── Send email helper ────────────────────────────────────────────
async function sendMail({ to, subject, html }) {
  try {
    const t = await getTransporter();
    const fromName = process.env.SMTP_FROM_NAME || 'Allo Urgence';
    const fromEmail = process.env.SMTP_FROM_ADDRESS || '"Allo Urgence" <noreply@allourgence.ca>';
    const from = process.env.SMTP_FROM_ADDRESS ? `"${fromName}" <${fromEmail}>` : '"Allo Urgence" <noreply@allourgence.ca>';

    const info = await t.sendMail({
      from,
      to,
      subject,
      html,
    });
    // For Ethereal, log preview URL
    const previewUrl = nodemailer.getTestMessageUrl(info);
    if (previewUrl) {
      console.log(`📧 Preview: ${previewUrl}`);
    }
    return { success: true, messageId: info.messageId, previewUrl };
  } catch (err) {
    console.error('❌ Mail error:', err.message);
    return { success: false, error: err.message };
  }
}

// ── Template: Email verification ─────────────────────────────────
function verificationEmail(prenom, code) {
  return {
    subject: 'Allo Urgence — Vérification de votre courriel',
    html: `
      <div style="font-family:'Inter',sans-serif;max-width:520px;margin:auto;padding:40px 24px;background:#f8fafc;border-radius:16px">
        <div style="text-align:center;margin-bottom:32px">
          <div style="display:inline-block;background:linear-gradient(135deg,#6366f1,#3b82f6);color:#fff;width:56px;height:56px;border-radius:16px;line-height:56px;font-size:24px">🏥</div>
        </div>
        <h2 style="color:#0f172a;text-align:center;margin:0 0 8px;font-size:22px">Bienvenue, ${prenom} !</h2>
        <p style="color:#64748b;text-align:center;margin:0 0 32px;font-size:14px">Merci pour votre inscription sur Allo Urgence</p>
        <div style="background:#fff;border-radius:12px;padding:24px;text-align:center;border:1px solid #e2e8f0;margin-bottom:24px">
          <p style="color:#64748b;font-size:13px;margin:0 0 12px">Votre code de vérification :</p>
          <div style="font-size:36px;font-weight:800;letter-spacing:8px;color:#0f172a;font-family:monospace">${code}</div>
          <p style="color:#94a3b8;font-size:11px;margin:12px 0 0">Ce code expire dans 24 heures</p>
        </div>
        <p style="color:#94a3b8;text-align:center;font-size:11px;margin:0">Si vous n'avez pas créé de compte, ignorez ce courriel.</p>
      </div>
    `,
  };
}

// ── Template: Welcome email (post-verification) ──────────────────
function welcomeEmail(prenom) {
  return {
    subject: 'Bienvenue sur Allo Urgence !',
    html: `
      <div style="font-family:'Inter',sans-serif;max-width:520px;margin:auto;padding:40px 24px;background:#f8fafc;border-radius:16px">
        <div style="text-align:center;margin-bottom:32px">
          <div style="display:inline-block;background:linear-gradient(135deg,#22c55e,#16a34a);color:#fff;width:56px;height:56px;border-radius:16px;line-height:56px;font-size:24px">✅</div>
        </div>
        <h2 style="color:#0f172a;text-align:center;margin:0 0 8px;font-size:22px">Courriel vérifié !</h2>
        <p style="color:#64748b;text-align:center;margin:0 0 24px;font-size:14px">Bonjour ${prenom}, votre compte est maintenant actif.</p>
        <div style="background:#fff;border-radius:12px;padding:20px;border:1px solid #e2e8f0;margin-bottom:24px">
          <h3 style="color:#0f172a;font-size:15px;margin:0 0 12px">Vous pouvez maintenant :</h3>
          <ul style="color:#64748b;font-size:13px;padding-left:20px;margin:0;line-height:24px">
            <li>Déclarer une urgence depuis l'application mobile</li>
            <li>Obtenir un ticket de triage automatique</li>
            <li>Suivre votre position en temps réel</li>
          </ul>
        </div>
        <p style="color:#94a3b8;text-align:center;font-size:11px;margin:0">— L'équipe Allo Urgence</p>
      </div>
    `,
  };
}

module.exports = { sendMail, verificationEmail, welcomeEmail };
