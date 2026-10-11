const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const authMiddleware = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];

  if (!token) {
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Missing authorization token'
    });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email
    };
    next();
  } catch (error) {
    return res.status(401).json({
      error: 'invalid_token',
      message: 'Invalid or expired token'
    });
  }
};

const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  const statusCode = err.statusCode || 500;
  const errorCode = err.code || 'internal_error';
  const message = err.message || 'Internal server error';

  res.status(statusCode).json({
    error: errorCode,
    message: message
  });
};

module.exports = {
  authMiddleware,
  errorHandler,
  admin
};
