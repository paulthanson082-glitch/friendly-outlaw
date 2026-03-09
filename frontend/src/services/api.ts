import axios, { AxiosInstance, AxiosError } from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

interface AuthToken {
  token: string;
  user: {
    id: string;
    email: string;
    displayName: string;
  };
}

interface ChatSession {
  id: string;
  userId: string;
  startedAt: string;
  lastMessageAt: string;
  context?: Record<string, any>;
}

interface ChatMessage {
  id: string;
  sessionId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
}

class APIClient {
  private client: AxiosInstance;
  private token: string | null = null;

  constructor() {
    // Load token from localStorage if available
    const stored = localStorage.getItem('auth_token');
    if (stored) {
      this.token = stored;
    }

    this.client = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add token to every request
    this.client.interceptors.request.use((config) => {
      if (this.token) {
        config.headers.Authorization = `Bearer ${this.token}`;
      }
      return config;
    });

    // Handle errors
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        if (error.response?.status === 401) {
          this.clearAuth();
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // Auth Methods
  async register(
    email: string,
    password: string,
    displayName?: string
  ): Promise<AuthToken> {
    const response = await this.client.post('/auth/register', {
      email,
      password,
      displayName,
    });
    this.setAuth(response.data.token);
    return response.data;
  }

  async login(email: string, password: string): Promise<AuthToken> {
    const response = await this.client.post('/auth/login', {
      email,
      password,
    });
    this.setAuth(response.data.token);
    return response.data;
  }

  async getCurrentUser(): Promise<AuthToken['user']> {
    const response = await this.client.get('/auth/me');
    return response.data;
  }

  // Chat Methods
  async createSession(context?: Record<string, any>): Promise<ChatSession> {
    const response = await this.client.post('/chat/sessions', { context });
    return response.data;
  }

  async getSessions(): Promise<ChatSession[]> {
    const response = await this.client.get('/chat/sessions');
    return response.data;
  }

  async getSession(sessionId: string): Promise<ChatSession> {
    const response = await this.client.get(`/chat/sessions/${sessionId}`);
    return response.data;
  }

  async getHistory(sessionId: string): Promise<ChatMessage[]> {
    const response = await this.client.get(`/chat/sessions/${sessionId}/history`);
    return response.data;
  }

  async deleteSession(sessionId: string): Promise<void> {
    await this.client.delete(`/chat/sessions/${sessionId}`);
  }

  async clearHistory(sessionId: string): Promise<void> {
    await this.client.post(`/chat/sessions/${sessionId}/clear`);
  }

  /**
   * Stream a message to Jules using Server-Sent Events
   */
  streamMessage(
    sessionId: string,
    message: string,
    onChunk: (chunk: { type: string; content: string }) => void,
    onError: (error: Error) => void,
    systemPrompt?: string
  ): void {
    const eventSource = new EventSource(
      `${API_BASE_URL}/chat/send?sessionId=${sessionId}&message=${encodeURIComponent(message)}${
        systemPrompt ? `&systemPrompt=${encodeURIComponent(systemPrompt)}` : ''
      }`,
      {
        withCredentials: false,
      }
    );

    // Set auth header for EventSource (not directly supported, use fetch instead)
    // For now, using a POST request with fetch and ReadableStream

    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data === '[DONE]') {
          eventSource.close();
        } else {
          onChunk(data);
        }
      } catch (error) {
        onError(error instanceof Error ? error : new Error(String(error)));
      }
    };

    eventSource.onerror = () => {
      eventSource.close();
      onError(new Error('Stream connection failed'));
    };
  }

  /**
   * Alternative: Use fetch API with ReadableStream for better control
   */
  async streamMessageFetch(
    sessionId: string,
    message: string,
    onChunk: (chunk: { type: string; content: string }) => void,
    onError: (error: Error) => void,
    systemPrompt?: string
  ): Promise<void> {
    try {
      const response = await fetch(`${API_BASE_URL}/chat/send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.token || ''}`,
        },
        body: JSON.stringify({
          sessionId,
          message,
          systemPrompt,
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      if (!response.body) {
        throw new Error('No response body');
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n\n');

        // Process complete messages
        for (let i = 0; i < lines.length - 1; i++) {
          const line = lines[i].trim();
          if (line.startsWith('data: ')) {
            const jsonStr = line.slice(6);
            try {
              const data = JSON.parse(jsonStr);
              if (data === '[DONE]') {
                return;
              }
              onChunk(data);
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }

        // Keep incomplete message in buffer
        buffer = lines[lines.length - 1];
      }
    } catch (error) {
      onError(error instanceof Error ? error : new Error(String(error)));
    }
  }

  // Document Methods
  async createDocument(title: string, content?: string, category?: string): Promise<any> {
    const response = await this.client.post('/documents', { title, content, category });
    return response.data;
  }

  async getDocuments(limit = 50, offset = 0): Promise<any> {
    const response = await this.client.get('/documents', { params: { limit, offset } });
    return response.data;
  }

  async getDocument(id: string): Promise<any> {
    const response = await this.client.get(`/documents/${id}`);
    return response.data;
  }

  async updateDocument(id: string, data: any): Promise<any> {
    const response = await this.client.put(`/documents/${id}`, data);
    return response.data;
  }

  async deleteDocument(id: string): Promise<void> {
    await this.client.delete(`/documents/${id}`);
  }

  async searchDocuments(query: string): Promise<any[]> {
    const response = await this.client.get('/documents/search', { params: { q: query } });
    return response.data;
  }

  async exportDocument(id: string, format: 'markdown' | 'plaintext' | 'html' = 'markdown'): Promise<string> {
    const response = await this.client.get(`/documents/${id}/export`, { params: { format } });
    return response.data;
  }

  async duplicateDocument(id: string): Promise<any> {
    const response = await this.client.post(`/documents/${id}/duplicate`);
    return response.data;
  }

  // Template Methods
  async getTemplates(category?: string): Promise<any[]> {
    const response = await this.client.get('/templates', { params: category ? { category } : {} });
    return response.data;
  }

  async getTemplate(id: string): Promise<any> {
    const response = await this.client.get(`/templates/${id}`);
    return response.data;
  }

  async createTemplate(name: string, category: string, content: string, placeholders?: any[], description?: string): Promise<any> {
    const response = await this.client.post('/templates', { name, category, content, placeholders, description });
    return response.data;
  }

  async fillTemplate(id: string, values: Record<string, string>): Promise<{ content: string }> {
    const response = await this.client.post(`/templates/${id}/fill`, { values });
    return response.data;
  }

  async createDocumentFromTemplate(templateId: string, title: string, values?: Record<string, string>): Promise<any> {
    const response = await this.client.post(`/templates/${templateId}/create-doc`, { title, values });
    return response.data;
  }

  // Kanban Methods
  async createBoard(name: string, description?: string): Promise<any> {
    const response = await this.client.post('/kanban/boards', { name, description });
    return response.data;
  }

  async getBoards(): Promise<any[]> {
    const response = await this.client.get('/kanban/boards');
    return response.data;
  }

  async getBoard(boardId: string): Promise<any> {
    const response = await this.client.get(`/kanban/boards/${boardId}`);
    return response.data;
  }

  async deleteBoard(boardId: string): Promise<void> {
    await this.client.delete(`/kanban/boards/${boardId}`);
  }

  async createTask(boardId: string, title: string, description?: string, column?: string): Promise<any> {
    const response = await this.client.post('/kanban/tasks', { boardId, title, description, column });
    return response.data;
  }

  async getTask(taskId: string): Promise<any> {
    const response = await this.client.get(`/kanban/tasks/${taskId}`);
    return response.data;
  }

  async updateTask(taskId: string, data: any): Promise<any> {
    const response = await this.client.put(`/kanban/tasks/${taskId}`, data);
    return response.data;
  }

  async moveTask(taskId: string, column: string): Promise<any> {
    const response = await this.client.post(`/kanban/tasks/${taskId}/move`, { column });
    return response.data;
  }

  async deleteTask(taskId: string): Promise<void> {
    await this.client.delete(`/kanban/tasks/${taskId}`);
  }

  async searchTasks(query: string): Promise<any[]> {
    const response = await this.client.get('/kanban/tasks/search', { params: { q: query } });
    return response.data;
  }

  // Writing Goals Methods
  async createGoal(title: string, goalType: string, unit: string, targetValue: number, description?: string, deadline?: string): Promise<any> {
    const response = await this.client.post('/writing-goals', { title, goalType, unit, targetValue, description, deadline });
    return response.data;
  }

  async getGoals(): Promise<any[]> {
    const response = await this.client.get('/writing-goals');
    return response.data;
  }

  async getGoal(id: string): Promise<any> {
    const response = await this.client.get(`/writing-goals/${id}`);
    return response.data;
  }

  async updateGoal(id: string, data: any): Promise<any> {
    const response = await this.client.put(`/writing-goals/${id}`, data);
    return response.data;
  }

  async updateGoalProgress(id: string, currentValue: number): Promise<any> {
    const response = await this.client.post(`/writing-goals/${id}/progress`, { currentValue });
    return response.data;
  }

  async deleteGoal(id: string): Promise<void> {
    await this.client.delete(`/writing-goals/${id}`);
  }

  async getGoalStats(id: string): Promise<any> {
    const response = await this.client.get(`/writing-goals/${id}/stats`);
    return response.data;
  }

  // Auth state management
  setAuth(token: string): void {
    this.token = token;
    localStorage.setItem('auth_token', token);
  }

  clearAuth(): void {
    this.token = null;
    localStorage.removeItem('auth_token');
  }

  isAuthenticated(): boolean {
    return !!this.token;
  }

  getToken(): string | null {
    return this.token;
  }
}

export const apiClient = new APIClient();
export type { AuthToken, ChatSession, ChatMessage };
