export interface User {
  uid: string;
  email: string;
  name: string;
}

export interface Joke {
  text: string;
  category: string;
}

export interface SavedJoke extends Joke {
  jokeId: string;
  savedAt: Date;
}

export interface ChatMessage {
  type: 'user' | 'bot';
  text: string;
  timestamp?: Date;
}
