const axios = require('axios');
const { firestore } = require('../utils');

const JOKE_API_URL = process.env.JOKE_API_URL || 'https://v2.jokeapi.dev/joke';

const categoryMap = {
  'work': 'Misc',
  'relationships': 'Miscellaneous',
  'programming': 'Programming',
  'general': 'Any',
  'knock-knock': 'Knock-Knock'
};

const getRandomJoke = async (category = 'general') => {
  try {
    const apiCategory = categoryMap[category] || 'Any';
    const response = await axios.get(
      `${JOKE_API_URL}/${apiCategory}?format=json`,
      { timeout: 5000 }
    );

    const data = response.data;

    if (data.error) {
      throw new Error('Joke API returned error');
    }

    // Format joke response
    let jokeText = '';
    if (data.type === 'single') {
      jokeText = data.joke;
    } else if (data.type === 'twopart') {
      jokeText = `${data.setup} ${data.delivery}`;
    }

    return {
      text: jokeText,
      category: category,
      source: 'jokeapi'
    };
  } catch (error) {
    console.error('JokeAPI error:', error);
    // Fallback to database joke
    return await getFallbackJoke(category);
  }
};

const getJokeByTopic = async (topic) => {
  try {
    // Try to match topic to a category
    const category = Object.keys(categoryMap).find(cat =>
      topic.toLowerCase().includes(cat) ||
      cat.includes(topic.toLowerCase())
    ) || 'general';

    return await getRandomJoke(category);
  } catch (error) {
    console.error('Error fetching joke by topic:', error);
    return await getFallbackJoke('general');
  }
};

const getFallbackJoke = async (category) => {
  try {
    const snapshot = await firestore
      .collection('jokes')
      .where('category', '==', category)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return {
        text: "Why did the chicken cross the road? To get to the other side!",
        category: 'general',
        source: 'fallback'
      };
    }

    const joke = snapshot.docs[0].data();
    return {
      jokeId: snapshot.docs[0].id,
      text: joke.text,
      category: joke.category,
      source: 'database'
    };
  } catch (error) {
    console.error('Fallback joke error:', error);
    return {
      text: "Why did the chicken cross the road? To get to the other side!",
      category: 'general',
      source: 'fallback'
    };
  }
};

module.exports = {
  getRandomJoke,
  getJokeByTopic,
  getFallbackJoke
};
