import { LocalReasoningProvider } from './LocalReasoningProvider';

async function main() {
  const provider = new LocalReasoningProvider();

  console.log('Checking server...');
  const available = await provider.isAvailable();
  console.log('Server available:', available);

  if (!available) {
    console.error('Server not running. Start it first:');
    console.error('  $HOME/start-llama-server.sh');
    process.exit(1);
  }

  console.log('\nTesting generation...');
  const result = await provider.generate([
    {
      role: 'user',
      content: 'What is 2+2? Think step by step.',
    },
  ]);

  console.log('\nResult:');
  console.log('Time:', result.timeMs, 'ms');
  console.log('Tokens:', result.tokensUsed);

  if (result.thinkingBlock) {
    console.log('\nThinking:');
    console.log(result.thinkingBlock);
  }

  console.log('\nAnswer:');
  console.log(result.finalAnswer);
}

main().catch(console.error);
