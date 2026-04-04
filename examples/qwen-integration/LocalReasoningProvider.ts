import { spawn } from 'child_process';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface LocalConfig {
  /** HuggingFace model path or local directory. */
  modelPath?: string;
  maxTokens?: number;
  temperature?: number;
  /** Emit <think> blocks in the response. Default true. */
  enableThinking?: boolean;
  /** Strip <think>…</think> from the returned `content` field. Default false. */
  stripThinkingTags?: boolean;
}

export interface LocalMetrics {
  latencyMs: number;
  tokensGenerated: number;
  modelPath: string;
}

export interface LocalResponse {
  /** Full model output (may include thinking block unless stripThinkingTags=true). */
  content: string;
  /** Raw text inside <think>…</think>, if present. */
  thinkingBlock?: string;
  /** Model answer with thinking block removed. */
  finalAnswer: string;
  metrics: LocalMetrics;
}

export type Message = { role: 'system' | 'user' | 'assistant'; content: string };

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

const DEFAULT_MODEL =
  'BeastCode/Qwen3.5-27B-Claude-4.6-Opus-Distilled-MLX-4bit';

export class LocalReasoningProvider {
  private readonly cfg: Required<LocalConfig>;

  constructor(config: LocalConfig = {}) {
    this.cfg = {
      modelPath: config.modelPath ?? DEFAULT_MODEL,
      maxTokens: config.maxTokens ?? 4096,
      temperature: config.temperature ?? 0.7,
      enableThinking: config.enableThinking ?? true,
      stripThinkingTags: config.stripThinkingTags ?? false,
    };
  }

  async generate(messages: Message[]): Promise<LocalResponse> {
    const prompt = this.formatMessages(messages);
    const startTime = Date.now();
    const raw = await this.runMLX(prompt);
    const latencyMs = Date.now() - startTime;

    const { thinkingBlock, finalAnswer } = this.parseThinking(raw);
    const content = this.cfg.stripThinkingTags ? finalAnswer : raw;

    return {
      content,
      thinkingBlock,
      finalAnswer,
      metrics: {
        latencyMs,
        tokensGenerated: estimateTokens(raw),
        modelPath: this.cfg.modelPath,
      },
    };
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /** Format a message array into the ChatML prompt format used by Qwen. */
  private formatMessages(messages: Message[]): string {
    const parts = messages.map((m) => {
      const tag = m.role === 'system' ? 'system' : m.role === 'user' ? 'user' : 'assistant';
      return `<|im_start|>${tag}\n${m.content}<|im_end|>`;
    });
    // Open the assistant turn so the model continues from here.
    parts.push('<|im_start|>assistant');
    return parts.join('\n');
  }

  private runMLX(prompt: string): Promise<string> {
    return new Promise((resolve, reject) => {
      const args = [
        '-m', 'mlx_lm.generate',
        '--model', this.cfg.modelPath,
        '--prompt', prompt,
        '--max-tokens', String(this.cfg.maxTokens),
        '--temp', String(this.cfg.temperature),
      ];

      const proc = spawn('python3', args, { stdio: ['ignore', 'pipe', 'pipe'] });

      let stdout = '';
      let stderr = '';

      proc.stdout.on('data', (chunk: Buffer) => { stdout += chunk.toString(); });
      proc.stderr.on('data', (chunk: Buffer) => { stderr += chunk.toString(); });

      proc.on('close', (code) => {
        if (code !== 0) {
          reject(new Error(`mlx_lm exited with code ${code}: ${stderr.slice(0, 500)}`));
        } else {
          resolve(stdout.trim());
        }
      });

      proc.on('error', (err) => {
        reject(new Error(
          `Failed to spawn python3. Is mlx-lm installed?\n  pip install mlx-lm --break-system-packages\n  Original: ${err.message}`
        ));
      });
    });
  }

  private parseThinking(output: string): { thinkingBlock?: string; finalAnswer: string } {
    const match = output.match(/<think>([\s\S]*?)<\/think>/);
    if (match) {
      return {
        thinkingBlock: match[1].trim(),
        finalAnswer: output.replace(/<think>[\s\S]*?<\/think>/, '').trim(),
      };
    }
    return { finalAnswer: output };
  }
}

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

/** Rough token estimate (~4 chars per token). */
function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}
