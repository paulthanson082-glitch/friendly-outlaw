#!/usr/bin/env node
/**
 * Smoke Test for Friendly Outlaw OpenClaw Plugin
 * 
 * This script validates that the plugin can be loaded and registered
 * with a mock OpenClaw API.
 */

const fs = require('fs');
const path = require('path');

console.log('🧪 Friendly Outlaw OpenClaw Plugin Smoke Test\n');

// Check if compiled plugin exists
const pluginPath = path.join(__dirname, 'dist', 'index.js');
if (!fs.existsSync(pluginPath)) {
  console.error('❌ Plugin not built. Run: npm run build');
  process.exit(1);
}

console.log('✅ Plugin build found at:', pluginPath);

// Create mock OpenClaw API
const mockApi = {
  logger: {
    info: (msg) => console.log(`  [INFO] ${msg}`),
    warn: (msg) => console.log(`  [WARN] ${msg}`),
    error: (msg) => console.error(`  [ERROR] ${msg}`),
  },
  pluginConfig: {
    workerPort: 37777,
    project: 'test-project',
    observationFeed: {
      enabled: false, // Disabled for smoke test
      channel: 'telegram',
      to: '123456789',
    },
  },
  runtime: {
    channel: {
      telegram: {
        sendMessageTelegram: async (to, text) => {
          console.log(`  [TELEGRAM] To: ${to}, Message: ${text}`);
          return { ok: true };
        },
      },
      discord: {
        sendMessageDiscord: async (to, text) => {
          console.log(`  [DISCORD] To: ${to}, Message: ${text}`);
          return { ok: true };
        },
      },
      signal: {
        sendMessageSignal: async (to, text) => {
          console.log(`  [SIGNAL] To: ${to}, Message: ${text}`);
          return { ok: true };
        },
      },
      slack: {
        sendMessageSlack: async (to, text) => {
          console.log(`  [SLACK] To: ${to}, Message: ${text}`);
          return { ok: true };
        },
      },
      whatsapp: {
        sendMessageWhatsApp: async (to, text) => {
          console.log(`  [WHATSAPP] To: ${to}, Message: ${text}`);
          return { ok: true };
        },
      },
      line: {
        sendMessageLine: async (to, text) => {
          console.log(`  [LINE] To: ${to}, Message: ${text}`);
          return { ok: true };
        },
      },
    },
  },
  registerService: (name, service) => {
    console.log(`✅ Service registered: ${name}`);
    console.log(`   - Has start method: ${typeof service.start === 'function'}`);
    console.log(`   - Has stop method: ${typeof service.stop === 'function'}`);
  },
  registerCommand: (name, handler) => {
    console.log(`✅ Command registered: ${name}`);
    console.log(`   - Handler type: ${typeof handler}`);
  },
};

// Load and initialize plugin
try {
  console.log('\n📦 Loading plugin...\n');
  const plugin = require(pluginPath);
  
  if (typeof plugin.default === 'function') {
    plugin.default(mockApi);
    console.log('\n✅ Plugin initialization successful!');
  } else {
    console.error('❌ Plugin does not export a default function');
    process.exit(1);
  }
} catch (error) {
  console.error('❌ Plugin initialization failed:', error.message);
  console.error(error.stack);
  process.exit(1);
}

console.log('\n🎉 Smoke test passed!\n');
