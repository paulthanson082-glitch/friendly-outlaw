/**
 * examples.ts
 *
 * 10 integration examples demonstrating how to use LocalReasoningProvider and
 * SmartRouter within the WritersApp ecosystem.
 *
 * Usage:
 *   ANTHROPIC_API_KEY=sk-... ts-node examples.ts
 *
 * Each example is self-contained and can be copy-pasted into your own code.
 */

import { SmartRouter, TaskType } from './SmartRouter';
import { LocalReasoningProvider } from './LocalReasoningProvider';
import type { TaskCharacteristics } from './SmartRouter';
import type { Message } from './LocalReasoningProvider';

const API_KEY = process.env.ANTHROPIC_API_KEY ?? '';

// ---------------------------------------------------------------------------
// Helper: run a named example and pretty-print the result
// ---------------------------------------------------------------------------
async function run(
  label: string,
  fn: () => Promise<void>
): Promise<void> {
  console.log('\n' + '='.repeat(60));
  console.log(`Example: ${label}`);
  console.log('='.repeat(60));
  try {
    await fn();
  } catch (err) {
    console.error('  ERROR:', err instanceof Error ? err.message : err);
  }
}

// ---------------------------------------------------------------------------
// Example 1 – Basic automatic routing
// ---------------------------------------------------------------------------
async function example1BasicRouting(): Promise<void> {
  const router = new SmartRouter(API_KEY);

  const result = await router.execute([
    {
      role: 'user',
      content:
        'Review the following Python snippet for any bugs:\n\n```python\nfor i in range(10)\n    print(i)\n```',
    },
  ]);

  console.log('Provider :', result.provider);
  console.log('Routing  :', result.decision.reasoning);
  console.log('Response :', result.content.slice(0, 300));
}

// ---------------------------------------------------------------------------
// Example 2 – Security audit (prefers local, thinking preserved)
// ---------------------------------------------------------------------------
async function example2SecurityAudit(): Promise<void> {
  const router = new SmartRouter(API_KEY);

  const result = await router.execute(
    [
      {
        role: 'user',
        content: `Audit this Express.js route for security issues:

app.post('/login', (req, res) => {
  const { user, pass } = req.body;
  db.query(\`SELECT * FROM accounts WHERE user='\${user}' AND pass='\${pass}'\`, (err, rows) => {
    if (rows.length) res.json({ token: sign({ user }) });
    else res.status(401).send('Unauthorized');
  });
});`,
      },
    ],
    { taskType: TaskType.SECURITY_AUDIT, estimatedTokens: 4000 }
  );

  console.log('Provider      :', result.provider);
  console.log('Has thinking  :', !!result.thinkingBlock);
  if (result.thinkingBlock) {
    console.log('Thinking (snippet):', result.thinkingBlock.slice(0, 200));
  }
  console.log('Answer (snippet)  :', result.content.slice(0, 300));
}

// ---------------------------------------------------------------------------
// Example 3 – Counseling scenario (privacy-sensitive, always local)
// ---------------------------------------------------------------------------
async function example3Counseling(): Promise<void> {
  const router = new SmartRouter(API_KEY);

  const result = await router.execute(
    [
      {
        role: 'system',
        content: 'You are a compassionate writing coach with expertise in creative wellbeing.',
      },
      {
        role: 'user',
        content:
          "I haven't written anything in six months. My inner critic is so loud I can't even open my document. Any advice?",
      },
    ],
    {
      taskType: TaskType.COUNSELING_SCENARIO,
      privacySensitive: true,
    }
  );

  console.log('Provider :', result.provider, '(data never left device)');
  console.log('Cost     : $0.00');
  console.log('Response :', result.content.slice(0, 400));
}

// ---------------------------------------------------------------------------
// Example 4 – Web research (always API)
// ---------------------------------------------------------------------------
async function example4WebResearch(): Promise<void> {
  const router = new SmartRouter(API_KEY);

  const result = await router.execute(
    [
      {
        role: 'user',
        content: 'What are the most important new features in Swift 6 released in 2024?',
      },
    ],
    {
      requiresLatestKnowledge: true,
      requiresWebSearch: false, // No actual web search, but knowledge is recent
    }
  );

  console.log('Provider :', result.provider, '(API required for recent knowledge)');
  console.log('Cost     : $' + result.metrics.cost.toFixed(6));
  console.log('Response :', result.content.slice(0, 300));
}

// ---------------------------------------------------------------------------
// Example 5 – Direct local provider (no routing)
// ---------------------------------------------------------------------------
async function example5DirectLocal(): Promise<void> {
  const provider = new LocalReasoningProvider({
    enableThinking: true,
    stripThinkingTags: false,
    maxTokens: 2048,
  });

  const result = await provider.generate([
    {
      role: 'user',
      content: 'Explain the difference between value types and reference types in Swift in two paragraphs.',
    },
  ]);

  console.log('Model     :', result.metrics.modelPath);
  console.log('Latency   :', result.metrics.latencyMs + 'ms');
  console.log('Tokens    :', result.metrics.tokensGenerated);
  console.log('Thinking  :', result.thinkingBlock ? result.thinkingBlock.slice(0, 150) : '(none)');
  console.log('Answer    :', result.finalAnswer.slice(0, 300));
}

// ---------------------------------------------------------------------------
// Example 6 – Template generation with cost tracking
// ---------------------------------------------------------------------------
async function example6TemplateGeneration(): Promise<void> {
  const router = new SmartRouter(API_KEY);

  const result = await router.execute(
    [
      {
        role: 'user',
        content: `Create a short story opening template with these placeholders:
- {{protagonist_name}}
- {{setting_location}}
- {{inciting_incident}}
- {{protagonist_emotion}}

Output just the template, formatted with clear section headings.`,
      },
    ],
    {
      taskType: TaskType.TEMPLATE_GENERATION,
      estimatedTokens: 800,
    }
  );

  const metrics = router.getMetrics();
  console.log('Provider         :', result.provider);
  console.log('Tokens saved so far:', metrics.localTokensSaved);
  console.log('Cost saved so far: $' + metrics.estimatedCostSaved.toFixed(6));
  console.log('Template:\n', result.content.slice(0, 500));
}

// ---------------------------------------------------------------------------
// Example 7 – Custom router subclass (force local for all counseling)
// ---------------------------------------------------------------------------
class PrivacyFirstRouter extends SmartRouter {
  protected override async route(
    messages: Message[],
    characteristics?: TaskCharacteristics
  ) {
    // Always local for counseling regardless of other settings.
    if (characteristics?.taskType === TaskType.COUNSELING_SCENARIO) {
      return {
        provider: 'local' as const,
        confidence: 1.0,
        reasoning: 'PrivacyFirstRouter: counseling always local.',
      };
    }
    return super['route'](messages, characteristics);
  }
}

async function example7CustomRouter(): Promise<void> {
  const router = new PrivacyFirstRouter(API_KEY);

  const result = await router.execute(
    [{ role: 'user', content: 'I need help coping with writer\'s block stemming from burnout.' }],
    { taskType: TaskType.COUNSELING_SCENARIO }
  );

  console.log('Provider :', result.provider, '(always local via PrivacyFirstRouter)');
  console.log('Decision :', result.decision.reasoning);
  console.log('Response :', result.content.slice(0, 300));
}

// ---------------------------------------------------------------------------
// Example 8 – AgentOrchestrator pattern
// ---------------------------------------------------------------------------
class AgentOrchestrator {
  private router: SmartRouter;

  constructor(apiKey: string) {
    this.router = new SmartRouter(apiKey);
  }

  async runSecurityAudit(code: string): Promise<string> {
    const result = await this.router.execute(
      [{ role: 'user', content: `Security audit:\n\n${code}` }],
      { taskType: TaskType.SECURITY_AUDIT, estimatedTokens: 5000 }
    );
    return result.content;
  }

  async generateTemplate(description: string): Promise<string> {
    const result = await this.router.execute(
      [{ role: 'user', content: `Generate a writing template: ${description}` }],
      { taskType: TaskType.TEMPLATE_GENERATION, estimatedTokens: 2000 }
    );
    return result.content;
  }

  async counselingSupport(situation: string): Promise<string> {
    const result = await this.router.execute(
      [{ role: 'user', content: situation }],
      { taskType: TaskType.COUNSELING_SCENARIO, privacySensitive: true }
    );
    return result.content;
  }

  getMetrics() {
    return this.router.getMetrics();
  }
}

async function example8AgentOrchestrator(): Promise<void> {
  const agent = new AgentOrchestrator(API_KEY);

  const auditResult = await agent.runSecurityAudit(
    'let token = jwt.sign(user, "secret")'
  );
  console.log('Audit result (snippet):', auditResult.slice(0, 200));

  const metrics = agent.getMetrics();
  console.log(`\nMetrics after 1 audit:`);
  console.log(`  Local: ${metrics.localRequests}`);
  console.log(`  API  : ${metrics.apiRequests}`);
  console.log(`  Saved: $${metrics.estimatedCostSaved.toFixed(6)}`);
}

// ---------------------------------------------------------------------------
// Example 9 – Metrics dashboard
// ---------------------------------------------------------------------------
async function example9MetricsDashboard(): Promise<void> {
  const router = new SmartRouter(API_KEY);

  // Simulate a few requests.
  const tasks: Array<[string, TaskCharacteristics]> = [
    ['Improve my opening paragraph.', { taskType: TaskType.DOCUMENTATION, estimatedTokens: 300 }],
    ['Audit this code for XSS.', { taskType: TaskType.SECURITY_AUDIT, estimatedTokens: 3000 }],
    ['I feel stuck creatively.', { taskType: TaskType.COUNSELING_SCENARIO, privacySensitive: true }],
  ];

  for (const [content, characteristics] of tasks) {
    await router.execute([{ role: 'user', content }], characteristics);
  }

  const m = router.getMetrics();

  console.log(`
┌─────────────────────────────────────┐
│       SmartRouter Metrics           │
├─────────────────────────────────────┤
│ Total requests  : ${String(m.totalRequests).padEnd(17)}│
│ Local           : ${String(m.localRequests).padEnd(17)}│
│ API             : ${String(m.apiRequests).padEnd(17)}│
│ Tokens saved    : ${String(m.localTokensSaved.toLocaleString()).padEnd(17)}│
│ Cost saved      : $${m.estimatedCostSaved.toFixed(6).padEnd(16)}│
│ Avg local (ms)  : ${m.avgLocalLatencyMs.toFixed(0).padEnd(17)}│
│ Avg API (ms)    : ${m.avgApiLatencyMs.toFixed(0).padEnd(17)}│
└─────────────────────────────────────┘
  `.trim());
}

// ---------------------------------------------------------------------------
// Example 10 – Thinking block audit trail
// ---------------------------------------------------------------------------
async function example10ThinkingAuditTrail(): Promise<void> {
  const router = new SmartRouter(API_KEY);

  const result = await router.execute(
    [
      {
        role: 'user',
        content:
          'Think carefully, then explain why the CAP theorem matters for a distributed document versioning system.',
      },
    ],
    { taskType: TaskType.REASONING_CHAIN, estimatedTokens: 3500, complexityScore: 7 }
  );

  console.log('Provider    :', result.provider);
  console.log('Has thinking:', !!result.thinkingBlock);

  if (result.thinkingBlock) {
    console.log('\n--- THINKING BLOCK (audit trail) ---');
    console.log(result.thinkingBlock.slice(0, 500));
    console.log('...\n--- END THINKING BLOCK ---');
  }

  console.log('\n--- FINAL ANSWER ---');
  console.log(result.content.slice(0, 500));
}

// ---------------------------------------------------------------------------
// Run all examples
// ---------------------------------------------------------------------------
(async () => {
  if (!API_KEY) {
    console.warn(
      'Warning: ANTHROPIC_API_KEY is not set. ' +
        'Examples that require the API will fail gracefully.\n'
    );
  }

  await run('1 – Basic automatic routing', example1BasicRouting);
  await run('2 – Security audit (local + thinking)', example2SecurityAudit);
  await run('3 – Counseling scenario (always local)', example3Counseling);
  await run('4 – Web research (always API)', example4WebResearch);
  await run('5 – Direct local provider', example5DirectLocal);
  await run('6 – Template generation + cost tracking', example6TemplateGeneration);
  await run('7 – Custom PrivacyFirstRouter subclass', example7CustomRouter);
  await run('8 – AgentOrchestrator pattern', example8AgentOrchestrator);
  await run('9 – Metrics dashboard', example9MetricsDashboard);
  await run('10 – Thinking block audit trail', example10ThinkingAuditTrail);

  console.log('\n' + '='.repeat(60));
  console.log('All examples complete.');
})();
