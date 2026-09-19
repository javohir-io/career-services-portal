const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuid } = require('uuid');
const usersRepo = require('../repositories/usersRepo');
const { authMiddleware } = require('../middleware/auth');
const { imageUpload, imageUrlFor } = require('../middleware/imageUpload');

const router = express.Router();

function signToken(userId) {
  return jwt.sign({ sub: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

function publicUser(user) {
  if (!user) return null;
  const { passwordHash, ...rest } = user;
  return rest;
}

// POST /api/auth/register
router.post('/register', async (req, res, next) => {
  try {
    const { name, email, password, university, phone } = req.body;

    if (!name || !email || !password) {
      return res
        .status(400)
        .json({ error: 'name, email and password are required' });
    }

    const existing = await usersRepo.findByEmail(email);
    if (existing) {
      return res
        .status(409)
        .json({ error: 'An account with this email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await usersRepo.create({
      id: uuid(),
      name,
      email,
      passwordHash,
      university: university || '',
      phone: phone || '',
    });

    const token = signToken(user.id);
    res.status(201).json({ token, user: publicUser(user) });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res
        .status(400)
        .json({ error: 'email and password are required' });
    }

    const user = await usersRepo.findByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = signToken(user.id);
    res.json({ token, user: publicUser(user) });
  } catch (err) {
    next(err);
  }
});

// GET /api/auth/me
router.get('/me', authMiddleware, async (req, res, next) => {
  try {
    const user = await usersRepo.findById(req.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ user: publicUser(user) });
  } catch (err) {
    next(err);
  }
});

// PUT /api/auth/me
router.put('/me', authMiddleware, async (req, res, next) => {
  try {
    const { name, university, degreeProgram, phone, about } = req.body;
    const user = await usersRepo.update(req.userId, {
      name,
      university,
      degreeProgram,
      phone,
      about,
    });
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ user: publicUser(user) });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/me/photo (auth required, multipart/form-data)
// File field name: "photo".
router.post('/me/photo', authMiddleware, (req, res, next) => {
  imageUpload.single('photo')(req, res, async (err) => {
    if (err) return res.status(400).json({ error: err.message });

    try {
      if (!req.file) {
        return res.status(400).json({ error: 'photo file is required' });
      }
      const user = await usersRepo.update(req.userId, {
        profilePhotoUrl: imageUrlFor(req.file.filename),
      });
      if (!user) return res.status(404).json({ error: 'User not found' });
      res.json({ user: publicUser(user) });
    } catch (dbErr) {
      next(dbErr);
    }
  });
});

module.exports = router;
