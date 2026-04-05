import axios from 'axios';

export interface Message {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

export interface GenerationResult {
  content: string;
  thinkingBlock?: string;
  finalAnswer: string;
  tokensUsed: number;
  timeMs: number;
}

export class LocalReasoningProvider {
  private baseUrl: string;

  constructor(baseUrl: string = 'http://127.0.0.1:8080') {
    this.baseUrl = baseUrl;
  }

  async generate(messages: Message[]): Promise<GenerationResult> {
    const startTime = Date.now();

    const response = await axios.post(
      `${this.baseUrl}/v1/chat/completions`,
      {
        messages,
        max_tokens: 2048,
        temperature: 0.7,
        stream: false,
      },
      {
        timeout: 60000,
      }
    );

    const content = response.data.choices[0].message.content;
    const tokensUsed = response.data.usage?.total_tokens || 0;
    const timeMs = Date.now() - startTime;

    const { thinkingBlock, finalAnswer } = this.parseResponse(content);

    return {
      content,
      thinkingBlock,
      finalAnswer,
      tokensUsed,
      timeMs,
    };
  }

  private parseResponse(response: string): {
    thinkingBlock?: string;
    finalAnswer: string;
  } {
    const thinkingMatch = response.match(/<think>([\s\S]*?)<\/think>/);

    if (thinkingMatch) {
      const thinkingBlock = thinkingMatch[1].trim();
      const finalAnswer = response
        .replace(/<think>[\s\S]*?<\/think>\s*/, '')
        .trim();

      return { thinkingBlock, finalAnswer };
    }

    return { finalAnswer: response };
  }

  async isAvailable(): Promise<boolean> {
    try {
      const response = await axios.get(`${this.baseUrl}/health`, {
        timeout: 5000,
      });
      return response.status === 200;
    } catch {
      return false;
    }
  }
}
