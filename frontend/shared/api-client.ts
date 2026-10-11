import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5001/api';

export class ApiClient {
  private client = axios.create({ baseURL: API_BASE_URL, headers: { 'Content-Type': 'application/json' } });
  private token: string | null = null;

  constructor() {
    if (typeof window !== 'undefined') {
      this.token = localStorage.getItem('auth_token');
    }
  }

  setToken(token: string) {
    this.token = token;
    localStorage.setItem('auth_token', token);
    this.client.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  }

  clearToken() {
    this.token = null;
    localStorage.removeItem('auth_token');
    delete this.client.defaults.headers.common['Authorization'];
  }

  async signup(email: string, password: string, name: string) {
    const response = await this.client.post('/auth/signup', { email, password, name });
    this.setToken(response.data.token);
    return response.data;
  }

  async login(email: string, password: string) {
    const response = await this.client.post('/auth/login', { email, password });
    this.setToken(response.data.token);
    return response.data;
  }

  async logout() {
    await this.client.post('/auth/logout');
    this.clearToken();
  }

  async getRandomJoke(category: string = 'general') {
    const response = await this.client.get(`/jokes/random?category=${category}`);
    return response.data;
  }

  async requestJoke(topic: string) {
    const response = await this.client.post('/jokes/request', { topic });
    return response.data;
  }

  async saveFavorite(jokeId: string, jokeText: string, category: string) {
    const response = await this.client.post('/jokes/favorites', { jokeId, jokeText, category, action: 'save' });
    return response.data;
  }

  async unsaveFavorite(jokeId: string) {
    const response = await this.client.post('/jokes/favorites', { jokeId, action: 'unsave' });
    return response.data;
  }

  async getFavorites() {
    const response = await this.client.get('/jokes/my-favorites');
    return response.data;
  }

  async sendChat(message: string, conversationId?: string) {
    const response = await this.client.post('/chat', { message, conversationId });
    return response.data;
  }

  async getChatHistory(limit: number = 50) {
    const response = await this.client.get(`/chat/history?limit=${limit}`);
    return response.data;
  }
}

export const apiClient = new ApiClient();
