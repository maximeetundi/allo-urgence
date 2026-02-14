const https = require('https');

const API_HOST = 'api.allo-urgence.tech-afm.com';
const API_PATH = '/api';

const USERS = [
    { email: 'infirmier@allourgence.ca', password: 'Password123!' },
    { email: 'medecin@allourgence.ca', password: 'Password123!' }
];

function postRequest(path, data) {
    return new Promise((resolve, reject) => {
        const postData = JSON.stringify(data);
        const options = {
            hostname: API_HOST,
            port: 443,
            path: API_PATH + path,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': postData.length
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, body: JSON.parse(body) });
                } catch (e) {
                    resolve({ status: res.statusCode, body: body });
                }
            });
        });

        req.on('error', (e) => reject(e));
        req.write(postData);
        req.end();
    });
}

async function checkUser(userCreds) {
    console.log(`\nChecking user: ${userCreds.email}...`);
    try {
        const res = await postRequest('/auth/login', { ...userCreds, client: 'mobile' });

        if (res.status !== 200) {
            console.error(`❌ Login failed: ${res.status}`);
            console.error(JSON.stringify(res.body, null, 2));
            return;
        }

        const user = res.body.user;
        console.log(`✅ Login successful!`);
        console.log(`   - Name: ${user.prenom} ${user.nom}`);
        console.log(`   - Role: ${user.role}`);
        console.log(`   - Hospital IDs: ${JSON.stringify(user.hospital_ids || [])}`);

        // Validation logic
        if (userCreds.email.includes('infirmier') && user.role !== 'nurse') {
            console.error(`   ❌ WARNING: Expected 'nurse' role, got '${user.role}'`);
        } else if (userCreds.email.includes('medecin') && user.role !== 'doctor') {
            console.error(`   ❌ WARNING: Expected 'doctor' role, got '${user.role}'`);
        } else {
            console.log(`   ✅ Role matches expected.`);
        }

    } catch (err) {
        console.error('Error:', err.message);
    }
}

async function main() {
    console.log('--- CHECKING PRODUCTION USERS (No Dependencies) ---');
    for (const user of USERS) {
        await checkUser(user);
    }
}

main();
