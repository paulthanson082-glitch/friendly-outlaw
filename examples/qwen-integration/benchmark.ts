/**
 * benchmark.ts
 *
 * Runs 6 representative WritersApp tasks through the SmartRouter and records
 * latency, cost, and provider selection.  Results are saved as:
 *   - benchmark-<timestamp>.json    (raw data)
 *   - benchmark-report-<timestamp>.html  (visual report)
 *
 * Usage:
 *   ANTHROPIC_API_KEY=sk-... ts-node benchmark.ts
 */

import * as fs from 'fs';
import * as path from 'path';
import { SmartRouter, TaskType } from './SmartRouter';
import type { TaskCharacteristics } from './SmartRouter';
import type { Message } from './LocalReasoningProvider';

// ---------------------------------------------------------------------------
// Benchmark scenarios
// ---------------------------------------------------------------------------

interface Scenario {
  name: string;
  messages: Message[];
  characteristics: TaskCharacteristics;
  description: string;
}

const SCENARIOS: Scenario[] = [
  {
    name: 'Code Review – SQL Injection',
    description: 'Detects SQL injection vulnerability in raw string interpolation.',
    characteristics: {
      taskType: TaskType.CODE_REVIEW,
      estimatedTokens: 2000,
      complexityScore: 6,
    },
    messages: [
      {
        role: 'user',
        content: `Review this Swift code for security issues and explain any problems:

\`\`\`swift
func fetchUser(id: String) -> User? {
    let query = "SELECT * FROM users WHERE id = '\\(id)'"
    return db.execute(query).first.map(User.init)
}
\`\`\`

Focus on SQL injection risks, how an attacker would exploit this, and the recommended fix.`,
      },
    ],
  },
  {
    name: 'Security Audit – Auth Flow',
    description: 'Audits a JWT authentication flow for common vulnerabilities.',
    characteristics: {
      taskType: TaskType.SECURITY_AUDIT,
      estimatedTokens: 5000,
      complexityScore: 7,
    },
    messages: [
      {
        role: 'user',
        content: `Perform a thorough security audit of the following authentication flow:

1. User submits email + password via HTTPS POST /login
2. Server looks up user by email (raw query: SELECT * FROM users WHERE email='<input>')
3. Server compares bcrypt hash – if match, signs a JWT with HS256 and a 5-char secret
4. JWT payload: { userId, email, role, exp: now+7days }
5. Client stores JWT in localStorage
6. Every API request sends the JWT in the Authorization header
7. Server verifies signature and checks exp – no refresh token mechanism

List every vulnerability with severity (Critical/High/Medium/Low) and remediation.`,
      },
    ],
  },
  {
    name: 'Counseling Scenario – Family Pressure',
    description: 'Empathetic counseling response for a writer under family pressure.',
    characteristics: {
      taskType: TaskType.COUNSELING_SCENARIO,
      estimatedTokens: 1500,
      privacySensitive: true,
    },
    messages: [
      {
        role: 'system',
        content: 'You are a supportive writing coach with a background in mindfulness and creative wellbeing.',
      },
      {
        role: 'user',
        content: `I've been working on my novel for three years but my family keeps telling me I'm wasting my time and should focus on my "real job". I come home exhausted and can barely write 200 words. I feel like giving up. What should I do?`,
      },
    ],
  },
  {
    name: 'Template Generation – Housing Intake',
    description: 'Generates a social-work housing intake assessment template.',
    characteristics: {
      taskType: TaskType.TEMPLATE_GENERATION,
      estimatedTokens: 3000,
      complexityScore: 5,
    },
    messages: [
      {
        role: 'user',
        content: `Create a comprehensive housing intake assessment document template for a social work organisation.

Requirements:
- Must cover: client demographics, current housing situation, income & benefits, support network, immediate needs, risk assessment
- Use {{placeholder}} syntax for fillable fields
- Include structured sections with clear headings
- Add guidance notes in [brackets] for workers
- Suitable for iOS app rendering

Output the full template document.`,
      },
    ],
  },
  {
    name: 'Reasoning Chain – Architecture Design',
    description: 'Deep architectural reasoning for a multi-tenant versioning system.',
    characteristics: {
      taskType: TaskType.REASONING_CHAIN,
      estimatedTokens: 4000,
      complexityScore: 8,
    },
    messages: [
      {
        role: 'user',
        content: `Design a multi-tenant document versioning system for WritersApp that:

1. Supports thousands of concurrent users
2. Allows branching (like Git) per document
3. Stores snapshots efficiently (delta compression)
4. Enables time-travel queries ("show me this doc as of last Tuesday")
5. Works offline-first with eventual consistency sync
6. Fits within the existing SQLite + Swift architecture

Walk me through your reasoning step-by-step before giving the final architecture.`,
      },
    ],
  },
  {
    name: 'Documentation – MCP Integration',
    description: 'Generates developer docs for the MCP client integration.',
    characteristics: {
      taskType: TaskType.DOCUMENTATION,
      estimatedTokens: 3500,
      complexityScore: 4,
    },
    messages: [
      {
        role: 'user',
        content: `Write complete developer documentation for integrating the Model Context Protocol (MCP) client in WritersApp.

Cover:
- What MCP is and why it's useful for a writing app
- Supported transports (stdio, http, websocket)
- Code examples for registering an MCP server
- How to expose tools via MCP to Claude
- Error handling and timeouts
- Security considerations

Format as Markdown suitable for inclusion in a README.`,
      },
    ],
  },
];

// ---------------------------------------------------------------------------
// Benchmark runner
// ---------------------------------------------------------------------------

interface BenchmarkResult {
  scenario: string;
  description: string;
  provider: 'local' | 'api';
  latencyMs: number;
  cost: number;
  tokensUsed: number;
  routingConfidence: number;
  routingReason: string;
  hasThinkingBlock: boolean;
  responsePreview: string;
  error?: string;
}

async function runBenchmark(apiKey: string): Promise<void> {
  console.log('WritersApp × Qwen Opus Integration Benchmark');
  console.log('='.repeat(60));
  console.log(`Scenarios : ${SCENARIOS.length}`);
  console.log(`Timestamp : ${new Date().toISOString()}`);
  console.log('='.repeat(60) + '\n');

  const router = new SmartRouter(apiKey);
  const results: BenchmarkResult[] = [];

  for (let i = 0; i < SCENARIOS.length; i++) {
    const scenario = SCENARIOS[i];
    console.log(`[${i + 1}/${SCENARIOS.length}] ${scenario.name}`);
    console.log(`  Description : ${scenario.description}`);

    let result: BenchmarkResult;

    try {
      const routerResult = await router.execute(scenario.messages, scenario.characteristics);

      result = {
        scenario: scenario.name,
        description: scenario.description,
        provider: routerResult.provider,
        latencyMs: routerResult.metrics.latencyMs,
        cost: routerResult.metrics.cost,
        tokensUsed: routerResult.metrics.tokensUsed,
        routingConfidence: routerResult.decision.confidence,
        routingReason: routerResult.decision.reasoning,
        hasThinkingBlock: !!routerResult.thinkingBlock,
        responsePreview: routerResult.content.slice(0, 200).replace(/\n/g, ' '),
      };

      console.log(`  Provider    : ${result.provider.toUpperCase()}`);
      console.log(`  Latency     : ${result.latencyMs}ms`);
      console.log(`  Cost        : $${result.cost.toFixed(6)}`);
      console.log(`  Tokens      : ${result.tokensUsed}`);
      console.log(`  Confidence  : ${(result.routingConfidence * 100).toFixed(0)}%`);
      console.log(`  Thinking    : ${result.hasThinkingBlock ? 'yes' : 'no'}`);
      console.log(`  Reason      : ${result.routingReason}`);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      console.log(`  ERROR: ${message}`);
      result = {
        scenario: scenario.name,
        description: scenario.description,
        provider: 'api',
        latencyMs: 0,
        cost: 0,
        tokensUsed: 0,
        routingConfidence: 0,
        routingReason: '',
        hasThinkingBlock: false,
        responsePreview: '',
        error: message,
      };
    }

    results.push(result);
    console.log();
  }

  // -------------------------------------------------------------------------
  // Summary
  // -------------------------------------------------------------------------
  const metrics = router.getMetrics();
  const localCount = results.filter((r) => r.provider === 'local').length;
  const apiCount = results.filter((r) => r.provider === 'api').length;
  const totalCost = results.reduce((s, r) => s + r.cost, 0);

  console.log('='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total scenarios  : ${results.length}`);
  console.log(`Local provider   : ${localCount}`);
  console.log(`API provider     : ${apiCount}`);
  console.log(`Total API cost   : $${totalCost.toFixed(6)}`);
  console.log(`Estimated saved  : $${metrics.estimatedCostSaved.toFixed(6)}`);
  console.log(`Avg local latency: ${metrics.avgLocalLatencyMs.toFixed(0)}ms`);
  console.log(`Avg API latency  : ${metrics.avgApiLatencyMs.toFixed(0)}ms`);

  // -------------------------------------------------------------------------
  // Save files
  // -------------------------------------------------------------------------
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const jsonPath = path.join(__dirname, `benchmark-${timestamp}.json`);
  const htmlPath = path.join(__dirname, `benchmark-report-${timestamp}.html`);

  const jsonPayload = { timestamp: new Date().toISOString(), results, metrics };
  fs.writeFileSync(jsonPath, JSON.stringify(jsonPayload, null, 2));
  console.log(`\nSaved JSON : ${jsonPath}`);

  fs.writeFileSync(htmlPath, buildHtmlReport(results, metrics));
  console.log(`Saved HTML : ${htmlPath}`);
}

// ---------------------------------------------------------------------------
// HTML report builder
// ---------------------------------------------------------------------------

function buildHtmlReport(
  results: BenchmarkResult[],
  metrics: ReturnType<SmartRouter['getMetrics']>
): string {
  const rows = results
    .map((r) => {
      const providerBadge =
        r.provider === 'local'
          ? '<span style="color:#2ecc71;font-weight:bold">LOCAL</span>'
          : '<span style="color:#3498db;font-weight:bold">API</span>';
      const errorNote = r.error ? `<br><em style="color:red">Error: ${escapeHtml(r.error)}</em>` : '';
      return `
      <tr>
        <td>${escapeHtml(r.scenario)}</td>
        <td>${providerBadge}</td>
        <td>${r.latencyMs}ms</td>
        <td>$${r.cost.toFixed(6)}</td>
        <td>${r.tokensUsed.toLocaleString()}</td>
        <td>${(r.routingConfidence * 100).toFixed(0)}%</td>
        <td>${r.hasThinkingBlock ? '✓' : ''}</td>
        <td style="max-width:300px;word-break:break-word;font-size:12px">
          ${escapeHtml(r.responsePreview)}${errorNote}
        </td>
      </tr>`;
    })
    .join('');

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<title>Qwen Opus Benchmark Report</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 32px; background: #1a1a2e; color: #e0e0e0; }
  h1 { color: #a78bfa; }
  h2 { color: #7dd3fc; margin-top: 2rem; }
  .summary { display: flex; gap: 24px; flex-wrap: wrap; margin: 1.5rem 0; }
  .card { background: #16213e; border-radius: 10px; padding: 16px 24px; min-width: 150px; }
  .card .label { font-size: 12px; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
  .card .value { font-size: 28px; font-weight: bold; color: #a78bfa; }
  table { border-collapse: collapse; width: 100%; margin-top: 1rem; }
  th { background: #0f3460; color: #7dd3fc; padding: 10px 14px; text-align: left; font-size: 13px; }
  td { background: #16213e; padding: 8px 14px; border-bottom: 1px solid #0f3460; font-size: 13px; vertical-align: top; }
  tr:hover td { background: #1a2a50; }
  footer { margin-top: 3rem; color: #64748b; font-size: 12px; }
</style>
</head>
<body>
<h1>Qwen Opus Integration – Benchmark Report</h1>
<p style="color:#94a3b8">Generated: ${new Date().toLocaleString()}</p>

<h2>Summary</h2>
<div class="summary">
  <div class="card"><div class="label">Total Requests</div><div class="value">${metrics.totalRequests}</div></div>
  <div class="card"><div class="label">Local</div><div class="value" style="color:#2ecc71">${metrics.localRequests}</div></div>
  <div class="card"><div class="label">API</div><div class="value" style="color:#3498db">${metrics.apiRequests}</div></div>
  <div class="card"><div class="label">Cost Saved</div><div class="value">$${metrics.estimatedCostSaved.toFixed(4)}</div></div>
  <div class="card"><div class="label">Avg Local (ms)</div><div class="value">${metrics.avgLocalLatencyMs.toFixed(0)}</div></div>
  <div class="card"><div class="label">Avg API (ms)</div><div class="value">${metrics.avgApiLatencyMs.toFixed(0)}</div></div>
</div>

<h2>Scenario Results</h2>
<table>
  <thead>
    <tr>
      <th>Scenario</th>
      <th>Provider</th>
      <th>Latency</th>
      <th>Cost</th>
      <th>Tokens</th>
      <th>Confidence</th>
      <th>Thinking</th>
      <th>Preview</th>
    </tr>
  </thead>
  <tbody>
    ${rows}
  </tbody>
</table>

<footer>
  WritersApp × Qwen3.5-27B-Claude-4.6-Opus-Distilled integration benchmark
</footer>
</body>
</html>`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) {
  console.error('Error: ANTHROPIC_API_KEY environment variable is not set.');
  process.exit(1);
}

runBenchmark(apiKey).catch((err) => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
