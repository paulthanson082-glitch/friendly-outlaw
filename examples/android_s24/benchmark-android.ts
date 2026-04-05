import { LocalReasoningProvider } from './LocalReasoningProvider';

async function runBenchmark() {
  const provider = new LocalReasoningProvider();

  const available = await provider.isAvailable();
  if (!available) {
    console.error('Server not running. Start it first:');
    console.error('  $HOME/start-llama-server.sh');
    process.exit(1);
  }

  const tests = [
    {
      name: 'Simple Math',
      prompt: 'What is 2+2?',
    },
    {
      name: 'Code Review',
      prompt: 'Review this code: const sql = `SELECT * FROM users WHERE id = ${id}`;',
    },
    {
      name: 'Reasoning',
      prompt: 'Explain why the sky is blue using physics.',
    },
  ];

  console.log('Samsung S24 Benchmark');
  console.log('='.repeat(60));

  for (const test of tests) {
    console.log(`\nTest: ${test.name}`);

    const result = await provider.generate([
      { role: 'user', content: test.prompt },
    ]);

    console.log(`  Time: ${result.timeMs}ms`);
    console.log(`  Tokens: ${result.tokensUsed}`);
    console.log(`  Has thinking: ${!!result.thinkingBlock}`);
  }
}

runBenchmark().catch(console.error);
