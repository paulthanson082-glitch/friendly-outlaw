import Anthropic from '@anthropic-ai/sdk';
import { LocalReasoningProvider, Message } from './LocalReasoningProvider';

// ---------------------------------------------------------------------------
// Enums & interfaces
// ---------------------------------------------------------------------------

export enum TaskType {
  CODE_REVIEW = 'code_review',
  SECURITY_AUDIT = 'security_audit',
  COUNSELING_SCENARIO = 'counseling_scenario',
  TEMPLATE_GENERATION = 'template_generation',
  REASONING_CHAIN = 'reasoning_chain',
  DOCUMENTATION = 'documentation',
  WEB_RESEARCH = 'web_research',
  GENERAL = 'general',
}

export interface TaskCharacteristics {
  taskType?: TaskType;
  /** Query involves news, real-time data, or anything post training-cutoff. */
  requiresLatestKnowledge?: boolean;
  /** Task requires live web search capability. */
  requiresWebSearch?: boolean;
  /** Task needs MCP tools, function-calling, etc. */
  requiresToolUse?: boolean;
  /** 1 (trivial) – 10 (highly complex). Defaults to 5. */
  complexityScore?: number;
  /** Estimated prompt + completion token count. */
  estimatedTokens?: number;
  /** Data must not leave the device (counseling, PII, etc.). */
  privacySensitive?: boolean;
}

export interface RoutingDecision {
  provider: 'local' | 'api';
  /** 0–1 confidence in the routing choice. */
  confidence: number;
  /** Human-readable explanation. */
  reasoning: string;
}

export interface RouterResult {
  content: string;
  provider: 'local' | 'api';
  decision: RoutingDecision;
  metrics: {
    latencyMs: number;
    /** USD cost. Zero for local. */
    cost: number;
    tokensUsed: number;
  };
  /** Preserved <think> block when local provider is used. */
  thinkingBlock?: string;
}

export interface RouterMetrics {
  totalRequests: number;
  localRequests: number;
  apiRequests: number;
  /** Tokens that were processed locally (not sent to the API). */
  localTokensSaved: number;
  /** Estimated USD saved by routing to local. */
  estimatedCostSaved: number;
  avgLocalLatencyMs: number;
  avgApiLatencyMs: number;
  /** Per-task-type breakdown. */
  byTaskType: Partial<Record<TaskType, { local: number; api: number }>>;
}

// ---------------------------------------------------------------------------
// Pricing constants (Claude Sonnet 4.5 as reference baseline)
// ---------------------------------------------------------------------------
const COST_PER_INPUT_TOKEN = 3 / 1_000_000; // $3 per 1M
const COST_PER_OUTPUT_TOKEN = 15 / 1_000_000; // $15 per 1M

// Local is preferred for these task types when token count is substantial.
const LOCAL_PREFERRED_TASKS = new Set<TaskType>([
  TaskType.CODE_REVIEW,
  TaskType.SECURITY_AUDIT,
  TaskType.COUNSELING_SCENARIO,
  TaskType.TEMPLATE_GENERATION,
  TaskType.REASONING_CHAIN,
  TaskType.DOCUMENTATION,
]);

const LOCAL_TOKEN_THRESHOLD = 500;
const LOCAL_MAX_COMPLEXITY = 8;

// ---------------------------------------------------------------------------
// SmartRouter
// ---------------------------------------------------------------------------

export class SmartRouter {
  protected readonly local: LocalReasoningProvider;
  private readonly anthropic: Anthropic;
  private readonly apiModel = 'claude-sonnet-4-5';

  private _metrics: RouterMetrics = {
    totalRequests: 0,
    localRequests: 0,
    apiRequests: 0,
    localTokensSaved: 0,
    estimatedCostSaved: 0,
    avgLocalLatencyMs: 0,
    avgApiLatencyMs: 0,
    byTaskType: {},
  };

  // Running totals for latency averages.
  private _localLatencySum = 0;
  private _apiLatencySum = 0;

  constructor(
    anthropicApiKey: string,
    localConfig?: ConstructorParameters<typeof LocalReasoningProvider>[0]
  ) {
    this.local = new LocalReasoningProvider(localConfig);
    this.anthropic = new Anthropic({ apiKey: anthropicApiKey });
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  async execute(
    messages: Message[],
    characteristics?: TaskCharacteristics
  ): Promise<RouterResult> {
    const decision = await this.route(messages, characteristics);
    const startTime = Date.now();

    if (decision.provider === 'local') {
      const result = await this.local.generate(messages);
      const latencyMs = Date.now() - startTime;
      const cost = 0;

      this.recordMetrics('local', latencyMs, result.metrics.tokensGenerated, cost, characteristics?.taskType);

      return {
        content: result.content,
        provider: 'local',
        decision,
        metrics: { latencyMs, cost, tokensUsed: result.metrics.tokensGenerated },
        thinkingBlock: result.thinkingBlock,
      };
    }

    // --- API path ---
    const apiMessages = messages.filter((m) => m.role !== 'system');
    const systemMsg = messages.find((m) => m.role === 'system')?.content;

    const response = await this.anthropic.messages.create({
      model: this.apiModel,
      max_tokens: 4096,
      system: systemMsg,
      messages: apiMessages as Anthropic.MessageParam[],
    });

    const latencyMs = Date.now() - startTime;
    const inputTokens = response.usage.input_tokens;
    const outputTokens = response.usage.output_tokens;
    const cost =
      inputTokens * COST_PER_INPUT_TOKEN + outputTokens * COST_PER_OUTPUT_TOKEN;
    const totalTokens = inputTokens + outputTokens;

    const content =
      response.content
        .filter((b): b is Anthropic.TextBlock => b.type === 'text')
        .map((b) => b.text)
        .join('') ?? '';

    this.recordMetrics('api', latencyMs, totalTokens, cost, characteristics?.taskType);

    return {
      content,
      provider: 'api',
      decision,
      metrics: { latencyMs, cost, tokensUsed: totalTokens },
    };
  }

  getMetrics(): Readonly<RouterMetrics> {
    return { ...this._metrics };
  }

  resetMetrics(): void {
    this._metrics = {
      totalRequests: 0,
      localRequests: 0,
      apiRequests: 0,
      localTokensSaved: 0,
      estimatedCostSaved: 0,
      avgLocalLatencyMs: 0,
      avgApiLatencyMs: 0,
      byTaskType: {},
    };
    this._localLatencySum = 0;
    this._apiLatencySum = 0;
  }

  // -------------------------------------------------------------------------
  // Routing logic (protected so subclasses can override)
  // -------------------------------------------------------------------------

  protected async route(
    messages: Message[],
    characteristics?: TaskCharacteristics
  ): Promise<RoutingDecision> {
    const c = characteristics ?? {};

    // ---- Hard API requirements ----
    if (c.requiresWebSearch) {
      return {
        provider: 'api',
        confidence: 1.0,
        reasoning: 'Task requires live web search which is only available via the API.',
      };
    }
    if (c.requiresToolUse) {
      return {
        provider: 'api',
        confidence: 1.0,
        reasoning: 'Task requires tool/function calling which is only available via the API.',
      };
    }
    if (c.requiresLatestKnowledge) {
      return {
        provider: 'api',
        confidence: 1.0,
        reasoning: 'Task requires up-to-date knowledge beyond the local model training cutoff.',
      };
    }

    // ---- Privacy-sensitive: always local ----
    if (c.privacySensitive) {
      return {
        provider: 'local',
        confidence: 1.0,
        reasoning: 'Privacy-sensitive data must not leave the device.',
      };
    }

    // ---- Counseling: always local ----
    if (c.taskType === TaskType.COUNSELING_SCENARIO) {
      return {
        provider: 'local',
        confidence: 0.95,
        reasoning: 'Counseling scenarios are handled locally for privacy (zero cost, zero data transfer).',
      };
    }

    // ---- Complexity cap ----
    const complexity = c.complexityScore ?? 5;
    if (complexity > LOCAL_MAX_COMPLEXITY) {
      return {
        provider: 'api',
        confidence: 0.8,
        reasoning: `Complexity score ${complexity} exceeds local model threshold of ${LOCAL_MAX_COMPLEXITY}.`,
      };
    }

    // ---- Token-count heuristic ----
    const estTokens = c.estimatedTokens ?? this.estimateTokensFromMessages(messages);
    const isHeavyTask = estTokens >= LOCAL_TOKEN_THRESHOLD;

    if (c.taskType && LOCAL_PREFERRED_TASKS.has(c.taskType) && isHeavyTask) {
      return {
        provider: 'local',
        confidence: 0.85,
        reasoning:
          `Task type "${c.taskType}" with ~${estTokens} estimated tokens is routed locally ` +
          `to save cost and preserve thinking blocks.`,
      };
    }

    // ---- Short tasks: favour API for speed ----
    if (estTokens < LOCAL_TOKEN_THRESHOLD) {
      return {
        provider: 'api',
        confidence: 0.7,
        reasoning: `Short task (~${estTokens} tokens) is faster via API than loading the local model.`,
      };
    }

    // ---- Default: local ----
    return {
      provider: 'local',
      confidence: 0.6,
      reasoning: 'Defaulting to local provider to minimise cost.',
    };
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  private estimateTokensFromMessages(messages: Message[]): number {
    const totalChars = messages.reduce((sum, m) => sum + m.content.length, 0);
    return Math.ceil(totalChars / 4);
  }

  private recordMetrics(
    provider: 'local' | 'api',
    latencyMs: number,
    tokens: number,
    cost: number,
    taskType?: TaskType
  ): void {
    this._metrics.totalRequests++;

    if (provider === 'local') {
      this._metrics.localRequests++;
      this._metrics.localTokensSaved += tokens;
      // Estimate what the API would have charged.
      const hypotheticalCost = tokens * 0.5 * COST_PER_INPUT_TOKEN + tokens * 0.5 * COST_PER_OUTPUT_TOKEN;
      this._metrics.estimatedCostSaved += hypotheticalCost;
      this._localLatencySum += latencyMs;
      this._metrics.avgLocalLatencyMs = this._localLatencySum / this._metrics.localRequests;
    } else {
      this._metrics.apiRequests++;
      this._apiLatencySum += latencyMs;
      this._metrics.avgApiLatencyMs = this._apiLatencySum / this._metrics.apiRequests;
    }

    // Per-task-type breakdown.
    if (taskType) {
      const existing = this._metrics.byTaskType[taskType] ?? { local: 0, api: 0 };
      existing[provider]++;
      this._metrics.byTaskType[taskType] = existing;
    }
  }
}
