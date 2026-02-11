# Friendly Outlaw OpenClaw Plugin

OpenClaw plugin for the Friendly Outlaw Writers App, enabling live observation streaming to messaging channels and providing writer context synchronization.

## Features

- **Live Observation Feed**: Streams writing observations from the Writers App to messaging channels in real-time via Server-Sent Events (SSE)
- **Channel-Agnostic Architecture**: Supports multiple messaging platforms through OpenClaw's unified channel API
- **Automatic Reconnection**: Handles connection interruptions with exponential backoff (1s → 30s max)
- **Status Monitoring**: `/friendly-outlaw-feed` command for checking connection state and configuration

## Supported Messaging Channels

- **Telegram** - Chat ID
- **Discord** - Channel ID
- **Signal** - Phone number or group ID
- **Slack** - Channel ID
- **WhatsApp** - Phone number
- **Line** - User/Group ID

## Architecture

```
Friendly Outlaw Writers App (localhost:37777/stream)
    ↓ SSE (Server-Sent Events)
OpenClaw Plugin (friendly-outlaw-observation-feed service)
    ↓ channel.sendMessage*()
OpenClaw Runtime → Telegram / Discord / Signal / Slack / WhatsApp / Line
```

## Installation

### 1. Build the Plugin

```bash
cd openclaw/
npm install
npm run build
```

This will compile TypeScript to JavaScript in the `dist/` directory.

### 2. Configure OpenClaw

Add to your `openclaw.json` (or `~/.openclaw/openclaw.json`):

```json
{
  "plugins": {
    "friendly-outlaw": {
      "workerPort": 37777,
      "project": "my-writing-project",
      "observationFeed": {
        "enabled": true,
        "channel": "telegram",
        "to": "YOUR_CHAT_ID"
      }
    }
  }
}
```

### 3. Install in OpenClaw

```bash
openclaw plugins install /path/to/friendly-outlaw/openclaw
```

Or add the plugin directory to OpenClaw's plugin path.

## Configuration Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `workerPort` | number | No | 37777 | Port for the Writers App service |
| `project` | string | No | "default" | Project identifier for workspace |
| `observationFeed.enabled` | boolean | No | false | Enable live observation streaming |
| `observationFeed.channel` | string | Yes* | - | Messaging channel (telegram, discord, etc.) |
| `observationFeed.to` | string | Yes* | - | Target chat/channel ID or phone number |

\* Required when `observationFeed.enabled` is `true`

## Usage

### Start the Writers App Service

Ensure the Friendly Outlaw Writers App service is running and listening on the configured port (default: 37777).

### Start OpenClaw Gateway

```bash
openclaw start
```

The plugin will automatically:
1. Load and initialize
2. Connect to the Writers App SSE stream
3. Begin streaming observations to your configured channel

### Monitor Status

Use the status command to check connection state:

```bash
/friendly-outlaw-feed
```

Output example:
```
📊 Friendly Outlaw Writers App Status

Feed Status: ✅ Connected
Channel: telegram
Target: 123456789
Worker Port: 37777
Reconnect Attempts: 0
```

## Observation Events

The plugin listens for `new_observation` events from the Writers App and formats them as:

```
📝 [Title]
[Subtitle]
🕐 [Timestamp]
```

Examples:
- New document created
- Writing session completed
- Word count milestone reached
- AI assistance used
- Document exported

## Development

### Prerequisites

- Node.js 18+
- TypeScript 5.0+
- npm or yarn

### Build

```bash
npm run build
```

### Test

```bash
npm test
```

Runs the comprehensive test suite with 17+ tests covering:
- Plugin initialization
- SSE connection and reconnection
- Message formatting
- Channel routing
- Command handling
- Error scenarios

### Smoke Test

```bash
node test-sse-consumer.js
```

Validates plugin can be loaded with a mock OpenClaw API.

### E2E Testing

```bash
./test-e2e.sh
```

Runs automated end-to-end tests in Docker, verifying:
- Plugin discovery
- Build artifacts
- File structure
- Smoke test execution

See [TESTING.md](TESTING.md) for comprehensive testing guide.

## Troubleshooting

### Plugin Not Loading

- Verify `openclaw.json` syntax is valid
- Check OpenClaw logs for errors
- Ensure plugin directory path is correct

### SSE Connection Fails

- Verify Writers App service is running
- Check port configuration matches service
- Ensure firewall allows connections on the port

### Messages Not Appearing

- Verify channel integration is configured in OpenClaw
- Check channel credentials (chat IDs, API keys)
- Confirm observation events are being emitted by Writers App
- Check OpenClaw logs for delivery errors

### Reconnection Issues

- Monitor Writers App service stability
- Check network connectivity
- Review reconnection logs for patterns

## Security

- Never commit API keys or tokens to source control
- Store channel credentials securely in OpenClaw configuration
- The plugin only logs non-sensitive information
- SSE buffer is limited to 1MB to prevent memory issues

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues and questions:
- Check [TESTING.md](TESTING.md) for troubleshooting
- Review OpenClaw documentation
- Open an issue on GitHub

## Version History

### 1.0.0 (2024)
- Initial release
- SSE observation streaming
- Multi-channel support
- Automatic reconnection
- Status command
