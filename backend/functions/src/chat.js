const express = require('express');
const router = express.Router();
const { generateResponse } = require('./services/aiService');
const { firestore, getUserName, validateRequestBody } = require('./utils');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

router.post('/', async (req, res, next) => {
  try {
    const { message, conversationId } = req.body;
    validateRequestBody(req.body, ['message']);
    const userId = req.user.uid;
    const chatId = conversationId || uuidv4();
    const userName = await getUserName(userId);

    const historySnapshot = await firestore.collection('conversations').doc(userId).collection('messages').orderBy('timestamp', 'desc').limit(10).get();
    const history = historySnapshot.docs.reverse().map(doc => ({ type: doc.data().type, text: doc.data().text }));

    const { reply } = await generateResponse(message, userName, history);

    await firestore.collection('conversations').doc(userId).collection('messages').add({
      type: 'user', text: message, timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    await firestore.collection('conversations').doc(userId).collection('messages').add({
      type: 'bot', text: reply, timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ reply, conversationId: chatId });
  } catch (error) {
    next(error);
  }
});

router.get('/history', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const limit = parseInt(req.query.limit) || 50;
    const snapshot = await firestore.collection('conversations').doc(userId).collection('messages').orderBy('timestamp', 'asc').limitToLast(limit).get();
    const messages = snapshot.docs.map(doc => ({ type: doc.data().type, text: doc.data().text, timestamp: doc.data().timestamp }));
    res.json(messages);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
