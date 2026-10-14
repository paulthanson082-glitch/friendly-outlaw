const admin = require('firebase-admin');

const firestore = admin.firestore();

const getUserName = async (uid) => {
  const userDoc = await firestore.collection('users').doc(uid).get();
  return userDoc.exists ? userDoc.data().name : 'Friend';
};

const logError = (message, error) => {
  console.error(`[ERROR] ${message}:`, error);
};

const createErrorResponse = (code, message, statusCode = 400) => {
  return {
    error: code,
    message: message,
    statusCode: statusCode
  };
};

const validateRequestBody = (body, requiredFields) => {
  const missing = requiredFields.filter(field => !body[field]);
  if (missing.length > 0) {
    throw createErrorResponse(
      'invalid_request',
      `Missing required fields: ${missing.join(', ')}`
    );
  }
};

module.exports = {
  firestore,
  getUserName,
  logError,
  createErrorResponse,
  validateRequestBody
};
