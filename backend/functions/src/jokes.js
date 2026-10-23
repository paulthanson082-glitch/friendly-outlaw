const express = require('express');
const router = express.Router();
const { getRandomJoke, getJokeByTopic } = require('./services/jokeService');
const { firestore, validateRequestBody } = require('./utils');
const admin = require('firebase-admin');

router.get('/random', async (req, res, next) => {
  try {
    const category = req.query.category || 'general';
    const joke = await getRandomJoke(category);
    res.json({ text: joke.text, category: joke.category, source: joke.source });
  } catch (error) {
    next(error);
  }
});

router.post('/request', async (req, res, next) => {
  try {
    const { topic } = req.body;
    validateRequestBody(req.body, ['topic']);
    const joke = await getJokeByTopic(topic);
    res.json({ text: joke.text, category: joke.category, source: joke.source });
  } catch (error) {
    next(error);
  }
});

router.post('/favorites', async (req, res, next) => {
  try {
    const { jokeId, action, jokeText, category } = req.body;
    validateRequestBody(req.body, ['jokeId', 'action']);
    const userId = req.user.uid;

    if (action === 'save') {
      await firestore.collection('favorites').doc(userId).collection('jokes').doc(jokeId).set({
        jokeId, text: jokeText, category, savedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      res.json({ isFavorited: true });
    } else if (action === 'unsave') {
      await firestore.collection('favorites').doc(userId).collection('jokes').doc(jokeId).delete();
      res.json({ isFavorited: false });
    } else {
      res.status(400).json({ error: 'invalid_action', message: 'Action must be "save" or "unsave"' });
    }
  } catch (error) {
    next(error);
  }
});

router.get('/my-favorites', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const snapshot = await firestore.collection('favorites').doc(userId).collection('jokes').orderBy('savedAt', 'desc').get();
    const favorites = snapshot.docs.map(doc => ({ jokeId: doc.id, ...doc.data() }));
    res.json(favorites);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
