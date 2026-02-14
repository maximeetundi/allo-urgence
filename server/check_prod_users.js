const fetch = require('node-fetch');

const API_URL = 'https://api.allo-urgence.tech-afm.com/api';

const USERS = [
    { email: 'infirmier@allourgence.ca', password: 'Password123!' },
    { email: 'medecin@allourgence.ca', password: 'Password123!' }
];

async function checkUser(userCreds) {
    console.log(`\nChecking user: ${userCreds.email}...`);
    try {
        const res = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ...userCreds, client: 'mobile' })
        });

        if (!res.ok) {
            console.error(`Login failed: ${res.status} ${res.statusText}`);
            console.error(await res.text());
            return;
        }

        const data = await res.json();
        const user = data.user;

        console.log(`✅ Login successful!`);
        console.log(`- ID: ${user.id}`);
        console.log(`- Name: ${user.prenom} ${user.nom}`);
        console.log(`- Role: ${user.role}  <-- VERIFY THIS`);
        console.log(`- Hospital IDs: ${JSON.stringify(user.hospital_ids || [])}`);

        if (user.role === 'admin') {
            console.log('⚠️  User is ADMIN (should have access to everything)');
        } else if (['nurse', 'doctor'].includes(user.role)) {
            console.log(`ℹ️  User has correct role '${user.role}'`);
        } else {
            console.error(`❌  WRONG ROLE: Expected nurse/doctor, got '${user.role}'`);
        }

    } catch (err) {
        console.error('Error:', err.message);
    }
}

async function main() {
    console.log('--- CHECKING PRODUCTION USERS ---');
    for (const user of USERS) {
        await checkUser(user);
    }
}

main();
