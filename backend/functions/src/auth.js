const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { firestore, validateRequestBody, createErrorResponse } = require('./utils');

// Initialize Firebase Admin (if not already done)
if (!admin.apps.length) {
  admin.initializeApp();
}

// POST /auth/signup
router.post('/signup', async (req, res, next) => {
  try {
    const { email, password, name } = req.body;

    // Validate input
    validateRequestBody(req.body, ['email', 'password', 'name']);

    // Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password
    });

    // Store user data in Firestore
    await firestore.collection('users').doc(userRecord.uid).set({
      email: email,
      name: name,
      username: email.split('@')[0],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      preferences: {
        favoriteCategories: [],
        notificationsEnabled: true
      }
    });

    // Generate custom token
    const token = await admin.auth().createCustomToken(userRecord.uid);

    res.status(201).json({
      userId: userRecord.uid,
      token: token,
      expiresIn: 3600
    });
  } catch (error) {
    next(error);
  }
});

// POST /auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validate input
    validateRequestBody(req.body, ['email', 'password']);

    // Verify user exists (Firebase SDK doesn't support password verification server-side)
    // For simplicity, we'll use a custom token approach
    // In production, use a proper OAuth flow or Firebase REST API

    const userQuery = await firestore
      .collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (userQuery.empty) {
      return res.status(401).json({
        error: 'invalid_credentials',
        message: 'Email or password is incorrect'
      });
    }

    const userId = userQuery.docs[0].id;
    const token = await admin.auth().createCustomToken(userId);

    res.json({
      userId: userId,
      token: token,
      expiresIn: 3600
    });
  } catch (error) {
    next(error);
  }
});

// POST /auth/logout
router.post('/logout', async (req, res, next) => {
  // Logout is handled client-side (token deletion)
  res.json({ success: true });
});

module.exports = router;
