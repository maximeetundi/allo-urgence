const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', '..', 'data');
const DB_FILE = path.join(DATA_DIR, 'database.json');

// Ensure data directory
if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Simple JSON database
class Database {
    constructor() {
        this.data = {
            users: [],
            hospitals: [],
            tickets: [],
            triage_notes: [],
            doctor_notes: [],
            audit_log: []
        };
        this.load();
    }

    load() {
        try {
            if (fs.existsSync(DB_FILE)) {
                const raw = fs.readFileSync(DB_FILE, 'utf-8');
                this.data = JSON.parse(raw);
            }
        } catch (err) {
            console.error('Error loading database:', err.message);
        }
    }

    save() {
        try {
            fs.writeFileSync(DB_FILE, JSON.stringify(this.data, null, 2), 'utf-8');
        } catch (err) {
            console.error('Error saving database:', err.message);
        }
    }

    // Collection helpers
    collection(name) {
        if (!this.data[name]) this.data[name] = [];
        return this.data[name];
    }

    insert(collection, record) {
        this.data[collection].push(record);
        this.save();
        return record;
    }

    findById(collection, id) {
        return this.data[collection].find(r => r.id === id) || null;
    }

    findOne(collection, predicate) {
        return this.data[collection].find(predicate) || null;
    }

    findMany(collection, predicate) {
        if (!predicate) return [...this.data[collection]];
        return this.data[collection].filter(predicate);
    }

    update(collection, id, updates) {
        const index = this.data[collection].findIndex(r => r.id === id);
        if (index === -1) return null;
        this.data[collection][index] = { ...this.data[collection][index], ...updates, updated_at: new Date().toISOString() };
        this.save();
        return this.data[collection][index];
    }

    count(collection, predicate) {
        if (!predicate) return this.data[collection].length;
        return this.data[collection].filter(predicate).length;
    }
}

const db = new Database();
module.exports = db;
