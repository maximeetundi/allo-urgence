const fetch = require('node-fetch');
const jwt = require('jsonwebtoken');

const API_URL = 'https://api.allo-urgence.tech-afm.com/api';
const CREDENTIALS = {
    email: 'infirmier@allourgence.ca',
    password: 'Password123!',
    client: 'mobile'
};

async function debugProd() {
    console.log('1. Logging in...');
    const loginRes = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(CREDENTIALS)
    });

    if (!loginRes.ok) {
        console.error('Login failed:', loginRes.status, await loginRes.text());
        return;
    }

    const data = await loginRes.json();
    const token = data.token;
    console.log('Login successful.');
    
    // Decode token
    const decoded = jwt.decode(token);
    console.log('\n2. Decoded Token Claims:');
    console.log(JSON.stringify(decoded, null, 2));

    if (!decoded.hospital_ids || decoded.hospital_ids.length === 0) {
        console.warn('\nWARNING: Token is missing hospital_ids or it is empty!');
    }

    const hospitalId = decoded.hospital_ids ? decoded.hospital_ids[0] : '5d0d4d92-79ff-4cb2-8069-52ad65f0086e';

    // Test endpoints
    console.log('\n3. Testing Endpoints...');

    // Test 1: With hospital_id
    await testEndpoint(token, `/nurse/patients?hospital_id=${hospitalId}`, 'With hospital_id');

    // Test 2: Without hospital_id
    await testEndpoint(token, `/nurse/patients`, 'WITHOUT hospital_id');

    // Test 3: Alerts
    await testEndpoint(token, `/nurse/alerts?hospital_id=${hospitalId}`, 'Alerts with ID');
}

async function testEndpoint(token, path, label) {
    console.log(`\nTesting ${label} (${path})...`);
    const res = await fetch(`${API_URL}${path}`, {
        headers: { 'Authorization': `Bearer ${token}` }
    });
    
    console.log(`Status: ${res.status}`);
    if (!res.ok) {
        console.log('Error Body:', await res.text());
    } else {
        const body = await res.json();
        console.log('Success! Result count:', body.patients ? body.patients.length : 'N/A');
    }
}

debugProd().catch(console.error);
