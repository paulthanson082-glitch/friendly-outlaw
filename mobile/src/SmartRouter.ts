/**
 * SmartRouter.ts
 *
 * Routes AI requests between the local llama.cpp server (on-device, free,
 * private) and the remote WritersApp API (cloud, full-featured).
 *
 * Strategy:
 *  1. If the local server is healthy → use local for short / low-stakes tasks.
 *  2. Fall back to the remote API for complex tasks or when local is unavailable.
 *  3. Always prefer local when the device is offline.
 */

import axios from 'axios';
import { localReasoning, CompletionOptions, CompletionResult, Message } from './LocalReasoningProvider';

export type RouteTarget = 'local' | 'remote';

export interface RouterOptions {
  /** Remote API base URL (defaults to EXPO_PUBLIC_API_URL env var). */
  remoteApiUrl?: string;
  /** Auth token for remote API calls. */
  authToken?: string;
  /** Word count threshold: prompts shorter than this go local first. */
  localMaxPromptWords?: number;
  /** Force a specific target, bypassing heuristics. */
  forceTarget?: RouteTarget;
}

export interface RouterResult extends CompletionResult {
  routedTo: RouteTarget;
}

const REMOTE_API_URL =
  process.env.EXPO_PUBLIC_API_URL ?? 'http://localhost:3000/api';

const DEFAULT_LOCAL_PROMPT_WORD_LIMIT = 300;

export class SmartRouter {
  private remoteApiUrl: string;
  private authToken?: string;
  private localMaxPromptWords: number;
  private forceTarget?: RouteTarget;

  /** Cached availability flag; refreshed at most once per minute. */
  private localAvailable: boolean = false;
  private lastHealthCheck: number = 0;
  private healthCheckIntervalMs = 60_000;

  constructor(options: RouterOptions = {}) {
    this.remoteApiUrl = options.remoteApiUrl ?? REMOTE_API_URL;
    this.authToken = options.authToken;
    this.localMaxPromptWords = options.localMaxPromptWords ?? DEFAULT_LOCAL_PROMPT_WORD_LIMIT;
    this.forceTarget = options.forceTarget;
  }

  setAuthToken(token: string) {
    this.authToken = token;
  }

  /**
   * Primary entry point. Sends prompt to the best available provider.
   */
  async complete(
    messages: Message[],
    options: CompletionOptions = {}
  ): Promise<RouterResult> {
    const target = await this.pickTarget(messages);

    if (target === 'local') {
      try {
        const result = await localReasoning.complete(messages, options);
        return { ...result, routedTo: 'local' };
      } catch (err) {
        // Local failed mid-request — fall through to remote
        console.warn('[SmartRouter] Local inference failed, falling back to remote:', err);
      }
    }

    const result = await this.callRemote(messages, options);
    return { ...result, routedTo: 'remote' };
  }

  /** Single-turn convenience wrapper. */
  async ask(
    prompt: string,
    systemPrompt?: string,
    options?: CompletionOptions
  ): Promise<RouterResult> {
    const messages: Message[] = [];
    if (systemPrompt) {
      messages.push({ role: 'system', content: systemPrompt });
    }
    messages.push({ role: 'user', content: prompt });
    return this.complete(messages, options);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  private async pickTarget(messages: Message[]): Promise<RouteTarget> {
    if (this.forceTarget) return this.forceTarget;

    const promptWords = messages
      .map((m) => m.content.split(/\s+/).length)
      .reduce((a, b) => a + b, 0);

    const isShortPrompt = promptWords <= this.localMaxPromptWords;
    const localOk = isShortPrompt && (await this.checkLocalAvailability());

    return localOk ? 'local' : 'remote';
  }

  private async checkLocalAvailability(): Promise<boolean> {
    const now = Date.now();
    if (now - this.lastHealthCheck < this.healthCheckIntervalMs) {
      return this.localAvailable;
    }

    this.lastHealthCheck = now;
    this.localAvailable = await localReasoning.isAvailable();
    return this.localAvailable;
  }

  /** Calls the WritersApp remote AI endpoint. */
  private async callRemote(
    messages: Message[],
    options: CompletionOptions
  ): Promise<CompletionResult> {
    const startTime = Date.now();

    const response = await axios.post<{ text: string }>(
      `${this.remoteApiUrl}/ai/complete`,
      { messages, ...options },
      {
        headers: {
          'Content-Type': 'application/json',
          ...(this.authToken ? { Authorization: `Bearer ${this.authToken}` } : {}),
        },
        timeout: 30_000,
      }
    );

    return {
      text: response.data.text,
      latencyMs: Date.now() - startTime,
    };
  }
}

/** Singleton — configure once at app startup via `router.setAuthToken(token)`. */
export const router = new SmartRouter();
