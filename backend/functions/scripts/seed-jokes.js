const admin = require('firebase-admin');
const serviceAccount = require('../path-to-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const firestore = admin.firestore();

const jokes = [
  {
    text: "Why did the employee get fired from the calendar factory? They took a day off.",
    category: "work",
    type: "single"
  },
  {
    text: "I told my wife she was drawing her eyebrows too high. She looked surprised.",
    category: "relationships",
    type: "single"
  },
  {
    text: "Why don't scientists trust atoms? Because they make up everything!",
    category: "general",
    type: "single"
  },
  {
    text: "Why do Java developers wear glasses? Because they don't C#.",
    category: "programming",
    type: "single"
  },
  {
    text: "My wife told me to take the spider out instead of killing it. We went and had some drinks. Cool guy. Wants to be a web developer.",
    category: "relationships",
    type: "single"
  }
];

async function seedJokes() {
  for (const joke of jokes) {
    await firestore.collection('jokes').add({
      ...joke,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      rating: 0,
      timesJoked: 0
    });
  }
  console.log('Jokes seeded successfully');
  process.exit(0);
}

seedJokes();
