const express = require('express');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const db = require('../db/connection');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all users (admin only)
router.get('/users', authenticateToken, requireRole(['admin']), (req, res) => {
  const users = db.findMany('users').map(user => ({
    id: user.id,
    email: user.email,
    role: user.role,
    nom: user.nom,
    prenom: user.prenom,
    telephone: user.telephone,
    created_at: user.created_at,
  }));
  res.json(users);
});

// Create user (admin only)
router.post('/users', authenticateToken, requireRole(['admin']), (req, res) => {
  const { email, password, nom, prenom, role, telephone } = req.body;

  if (!email || !password || !nom || !prenom || !role) {
    return res.status(400).json({ error: 'Champs requis manquants' });
  }

  const existingUser = db.findOne('users', u => u.email === email);
  if (existingUser) {
    return res.status(409).json({ error: 'Cet email est déjà utilisé' });
  }

  const passwordHash = bcrypt.hashSync(password, 10);
  const newUser = {
    id: uuidv4(),
    email,
    password_hash: passwordHash,
    nom,
    prenom,
    role,
    telephone: telephone || null,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  db.insert('users', newUser);
  
  res.status(201).json({
    id: newUser.id,
    email: newUser.email,
    role: newUser.role,
    nom: newUser.nom,
    prenom: newUser.prenom,
    telephone: newUser.telephone,
    created_at: newUser.created_at,
  });
});

// Delete user (admin only)
router.delete('/users/:id', authenticateToken, requireRole(['admin']), (req, res) => {
  const { id } = req.params;
  
  const user = db.findById('users', id);
  if (!user) {
    return res.status(404).json({ error: 'Utilisateur non trouvé' });
  }

  // Prevent deleting yourself
  if (id === req.user.id) {
    return res.status(403).json({ error: 'Vous ne pouvez pas supprimer votre propre compte' });
  }

  const index = db.data.users.findIndex(u => u.id === id);
  if (index > -1) {
    db.data.users.splice(index, 1);
    db.save();
  }

  res.json({ message: 'Utilisateur supprimé' });
});

// Get dashboard stats (admin only)
router.get('/stats', authenticateToken, requireRole(['admin', 'nurse', 'doctor']), (req, res) => {
  const stats = {
    totalUsers: db.count('users'),
    totalHospitals: db.count('hospitals'),
    totalTickets: db.count('tickets'),
    waitingTickets: db.count('tickets', t => t.status === 'waiting'),
    inProgressTickets: db.count('tickets', t => t.status === 'in_progress'),
    completedTickets: db.count('tickets', t => t.status === 'completed'),
  };
  res.json(stats);
});

module.exports = router;
