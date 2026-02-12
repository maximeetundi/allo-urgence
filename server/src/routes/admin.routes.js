const express = require('express');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const db = require('../db/pg_connection');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all users (admin only)
router.get('/users', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const users = await db.findMany('users');
    const filteredUsers = users.map(user => ({
      id: user.id,
      email: user.email,
      role: user.role,
      nom: user.nom,
      prenom: user.prenom,
      telephone: user.telephone,
      created_at: user.created_at,
    }));
    res.json(filteredUsers);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Create user (admin only)
router.post('/users', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { email, password, nom, prenom, role, telephone } = req.body;

    if (!email || !password || !nom || !prenom || !role) {
      return res.status(400).json({ error: 'Champs requis manquants' });
    }

    const existingUser = await db.findOne('users', { email });
    if (existingUser) {
      return res.status(409).json({ error: 'Cet email est déjà utilisé' });
    }

    const passwordHash = bcrypt.hashSync(password, 10);
    const newUser = await db.insert('users', {
      email,
      password_hash: passwordHash,
      nom,
      prenom,
      role,
      telephone: telephone || null,
    });
    
    res.status(201).json({
      id: newUser.id,
      email: newUser.email,
      role: newUser.role,
      nom: newUser.nom,
      prenom: newUser.prenom,
      telephone: newUser.telephone,
      created_at: newUser.created_at,
    });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Delete user (admin only)
router.delete('/users/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    
    // Prevent deleting yourself
    if (id === req.user.id) {
      return res.status(403).json({ error: 'Vous ne pouvez pas supprimer votre propre compte' });
    }

    const deletedUser = await db.delete('users', id);
    if (!deletedUser) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json({ message: 'Utilisateur supprimé' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Get dashboard stats (admin only)
router.get('/stats', authenticateToken, requireRole(['admin', 'nurse', 'doctor']), async (req, res) => {
  try {
    const stats = {
      totalUsers: await db.count('users'),
      totalHospitals: await db.count('hospitals'),
      totalTickets: await db.count('tickets'),
      waitingTickets: await db.count('tickets', { status: 'waiting' }),
      inProgressTickets: await db.count('tickets', { status: 'in_progress' }),
      completedTickets: await db.count('tickets', { status: 'completed' }),
    };
    res.json(stats);
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
