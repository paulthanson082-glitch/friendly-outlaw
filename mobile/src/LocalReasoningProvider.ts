/**
 * LocalReasoningProvider.ts
 *
 * Connects to a llama.cpp server running locally on the device (via Termux)
 * and exposes an OpenAI-compatible chat-completion interface.
 *
 * The server is started by $HOME/start-llama-server.sh and listens on
 * http://127.0.0.1:8080 by default.
 */

import axios, { AxiosInstance } from 'axios';

export interface Message {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface CompletionOptions {
  maxTokens?: number;
  temperature?: number;
  stopSequences?: string[];
}

export interface CompletionResult {
  text: string;
  tokenCount?: number;
  latencyMs: number;
}

export interface ServerHealth {
  status: 'ok' | 'loading' | 'error';
  modelLoaded: boolean;
}

const LOCAL_SERVER_URL = 'http://127.0.0.1:8080';
const DEFAULT_TIMEOUT_MS = 120_000; // 2 minutes — local inference is slow

export class LocalReasoningProvider {
  private client: AxiosInstance;

  constructor(serverUrl: string = LOCAL_SERVER_URL) {
    this.client = axios.create({
      baseURL: serverUrl,
      timeout: DEFAULT_TIMEOUT_MS,
    });
  }

  /** Returns true if the llama.cpp server is reachable and has a model loaded. */
  async isAvailable(): Promise<boolean> {
    try {
      const health = await this.getHealth();
      return health.status === 'ok' && health.modelLoaded;
    } catch {
      return false;
    }
  }

  /** Fetches server health from /health endpoint. */
  async getHealth(): Promise<ServerHealth> {
    const response = await this.client.get<{ status: string; slots_idle?: number }>(
      '/health',
      { timeout: 5_000 }
    );
    const data = response.data;
    return {
      status: data.status === 'ok' ? 'ok' : 'error',
      modelLoaded: data.status === 'ok',
    };
  }

  /**
   * Sends a chat-completion request to the local llama.cpp server.
   * Uses the /v1/chat/completions endpoint (OpenAI-compatible).
   */
  async complete(
    messages: Message[],
    options: CompletionOptions = {}
  ): Promise<CompletionResult> {
    const { maxTokens = 512, temperature = 0.7, stopSequences = [] } = options;

    const startTime = Date.now();

    const response = await this.client.post<{
      choices: Array<{ message: { content: string } }>;
      usage?: { completion_tokens: number };
    }>('/v1/chat/completions', {
      messages,
      max_tokens: maxTokens,
      temperature,
      stop: stopSequences.length > 0 ? stopSequences : undefined,
      stream: false,
    });

    const latencyMs = Date.now() - startTime;
    const choice = response.data.choices[0];

    return {
      text: choice?.message?.content ?? '',
      tokenCount: response.data.usage?.completion_tokens,
      latencyMs,
    };
  }

  /**
   * Convenience wrapper: single-turn prompt → completion.
   */
  async ask(
    prompt: string,
    systemPrompt?: string,
    options?: CompletionOptions
  ): Promise<CompletionResult> {
    const messages: Message[] = [];
    if (systemPrompt) {
      messages.push({ role: 'system', content: systemPrompt });
    }
    messages.push({ role: 'user', content: prompt });
    return this.complete(messages, options);
  }
}

export const localReasoning = new LocalReasoningProvider();
