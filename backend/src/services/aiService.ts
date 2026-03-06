import Anthropic from '@anthropic-ai/sdk';
import { config } from '../config/env.js';
import logger from '../utils/logger.js';
import { AIServiceError } from '../utils/errors.js';

export interface AIMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface StreamChunk {
  type: 'text' | 'error' | 'stop';
  content: string;
}

export class AIService {
  private client: Anthropic;
  private model = 'claude-3-5-sonnet-20241022';
  private maxTokens = 4096;
  private temperature = 0.7;

  constructor() {
    this.client = new Anthropic({
      apiKey: config.ANTHROPIC_API_KEY,
    });
  }

  /**
   * Stream a message to Claude and yield chunks in real-time
   */
  async *streamMessage(
    userMessage: string,
    conversationHistory: AIMessage[] = [],
    systemPrompt?: string
  ): AsyncGenerator<StreamChunk, void, unknown> {
    try {
      const messages: AIMessage[] = [
        ...conversationHistory,
        { role: 'user', content: userMessage },
      ];

      const response = await this.client.messages.create({
        model: this.model,
        max_tokens: this.maxTokens,
        temperature: this.temperature,
        system: systemPrompt || this.getDefaultSystemPrompt(),
        messages: messages,
        stream: true,
      });

      for await (const event of response) {
        if (
          event.type === 'content_block_delta' &&
          event.delta.type === 'text_delta'
        ) {
          yield {
            type: 'text',
            content: event.delta.text,
          };
        } else if (event.type === 'message_stop') {
          yield { type: 'stop', content: '' };
        }
      }
    } catch (error) {
      logger.error('AI stream error:', error);
      yield {
        type: 'error',
        content: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Get full message response (non-streaming)
   */
  async getMessage(
    userMessage: string,
    conversationHistory: AIMessage[] = [],
    systemPrompt?: string
  ): Promise<string> {
    try {
      const messages: AIMessage[] = [
        ...conversationHistory,
        { role: 'user', content: userMessage },
      ];

      const response = await this.client.messages.create({
        model: this.model,
        max_tokens: this.maxTokens,
        temperature: this.temperature,
        system: systemPrompt || this.getDefaultSystemPrompt(),
        messages: messages,
      });

      const textContent = response.content.find((c) => c.type === 'text');
      if (!textContent || textContent.type !== 'text') {
        throw new Error('No text response from Claude');
      }

      return textContent.text;
    } catch (error) {
      throw new AIServiceError(
        error instanceof Error ? error : new Error(String(error)),
        'Failed to get AI response'
      );
    }
  }

  private getDefaultSystemPrompt(): string {
    return `You are Jules, an AI writing assistant for writers. Your role is to:
- Help writers brainstorm ideas and develop characters
- Suggest improvements to their writing
- Continue their stories or essays
- Check grammar and provide style suggestions
- Generate outlines and writing prompts
- Provide encouragement and motivation

Be supportive, constructive, and creative. Ask clarifying questions when needed.
Adapt your tone based on the writer's needs and the type of content they're working on.`;
  }

  /**
   * Update model configuration
   */
  setModel(model: string): void {
    this.model = model;
  }

  setMaxTokens(tokens: number): void {
    this.maxTokens = tokens;
  }

  setTemperature(temperature: number): void {
    this.temperature = Math.max(0, Math.min(2, temperature));
  }
}

export const aiService = new AIService();
