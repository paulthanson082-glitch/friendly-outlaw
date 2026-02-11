# Testing Guide for Friendly Outlaw OpenClaw Plugin

This document provides a comprehensive testing checklist for the OpenClaw plugin integration with the Friendly Outlaw Writers App.

## Prerequisites

- OpenClaw gateway runtime installed and running
- Friendly Outlaw Writers App service running on port 37777 (or configured port)
- Node.js 18+ and npm installed
- TypeScript compiler installed (`npm install -g typescript`)

## Unit Tests

Run the comprehensive test suite:

```bash
cd openclaw/
npm install
npm test
```

Expected output: All 17+ tests should pass.

## Manual E2E Testing Checklist

### 1. Plugin Installation

- [ ] Plugin directory structure is correct
- [ ] `openclaw.plugin.json` manifest is valid JSON
- [ ] TypeScript compiles without errors: `npm run build`
- [ ] `dist/index.js` and `dist/index.d.ts` are generated

### 2. OpenClaw Gateway Integration

- [ ] Add plugin configuration to `openclaw.json`:
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

- [ ] Start OpenClaw gateway with plugin loaded
- [ ] Verify plugin logs: `[friendly-outlaw] OpenClaw plugin loaded — v1.0.0`

### 3. Writers App Service

- [ ] Start the Friendly Outlaw Writers App service
- [ ] Verify service is listening on configured port (default: 37777)
- [ ] Verify `/stream` SSE endpoint is accessible
- [ ] Service emits `new_observation` events when writing activities occur

### 4. Observation Feed

- [ ] Plugin connects to SSE stream on startup
- [ ] Connection logs appear: `[friendly-outlaw] Connected to SSE stream`
- [ ] Create a new document in Writers App
- [ ] Verify observation appears in configured messaging channel
- [ ] Verify message format includes title, subtitle (if present), and timestamp

### 5. Reconnection and Error Handling

- [ ] Stop the Writers App service
- [ ] Verify plugin logs reconnection attempts with exponential backoff
- [ ] Restart Writers App service
- [ ] Verify plugin reconnects successfully
- [ ] Verify observations continue to stream after reconnection

### 6. Status Command

- [ ] Run `/friendly-outlaw-feed` command in OpenClaw
- [ ] Verify status output shows:
  - Feed status (Connected/Connecting/Disconnected)
  - Configured channel
  - Target chat/channel ID
  - Worker port
  - Reconnection attempt count

### 7. Multiple Channels

Test with different messaging channels:

- [ ] Telegram: Set `channel: "telegram"`, `to: "YOUR_CHAT_ID"`
- [ ] Discord: Set `channel: "discord"`, `to: "YOUR_CHANNEL_ID"`
- [ ] Signal: Set `channel: "signal"`, `to: "YOUR_PHONE_NUMBER"`
- [ ] Slack: Set `channel: "slack"`, `to: "YOUR_CHANNEL_ID"`
- [ ] WhatsApp: Set `channel: "whatsapp"`, `to: "YOUR_PHONE_NUMBER"`
- [ ] Line: Set `channel: "line"`, `to: "YOUR_USER_ID"`

### 8. Configuration Changes

- [ ] Disable feed: Set `enabled: false`
- [ ] Verify service logs: `[friendly-outlaw] Observation feed disabled`
- [ ] Verify no SSE connection attempts are made
- [ ] Re-enable feed and verify it starts

### 9. Error Scenarios

- [ ] Missing `channel` configuration
- [ ] Missing `to` configuration
- [ ] Invalid worker port (service not running)
- [ ] Unsupported channel name
- [ ] Channel integration not available in OpenClaw

Verify appropriate error messages and graceful degradation in all cases.

## Automated E2E Testing

Use the provided E2E test script:

```bash
cd openclaw/
./test-e2e.sh
```

This will:
1. Build the plugin
2. Start a mock Writers App service
3. Start OpenClaw gateway with plugin
4. Verify plugin discovery and registration
5. Test SSE connectivity
6. Clean up all resources

## Performance Testing

- [ ] Monitor memory usage during long-running SSE connections
- [ ] Verify SSE buffer doesn't exceed 1MB limit
- [ ] Test with rapid observation events (high-frequency writing)
- [ ] Verify exponential backoff doesn't cause delays in stable connections

## Security Testing

- [ ] Verify plugin doesn't log sensitive information (API keys, tokens)
- [ ] Verify channel credentials are handled securely
- [ ] Test with malformed SSE data
- [ ] Test with malicious JSON payloads

## Troubleshooting

### Plugin Not Loading

- Check `openclaw.json` syntax
- Verify plugin directory path
- Check OpenClaw logs for loading errors

### SSE Connection Fails

- Verify Writers App service is running
- Check firewall settings
- Verify port configuration matches service

### Messages Not Appearing

- Verify channel integration is configured in OpenClaw
- Check channel credentials (chat IDs, tokens)
- Verify observation events are being emitted by Writers App

### High Reconnection Attempts

- Check Writers App service stability
- Verify network connectivity
- Monitor service logs for crashes or restarts

## Integration Testing with Writers App

1. **Document Creation**: Create new documents and verify observations
2. **Document Updates**: Update existing documents and verify observations
3. **Writing Sessions**: Start/end writing sessions and verify events
4. **Word Count Goals**: Reach word count milestones and verify celebrations
5. **AI Assistance**: Use AI features and verify context observations

## Reporting Issues

When reporting issues, include:
- OpenClaw version
- Plugin version
- Writers App version
- Configuration (redact sensitive data)
- Relevant logs
- Steps to reproduce

## Success Criteria

✅ All unit tests pass
✅ Plugin loads successfully in OpenClaw
✅ SSE connection established to Writers App
✅ Observations delivered to at least one messaging channel
✅ Reconnection works after service interruption
✅ Status command returns accurate information
✅ No memory leaks during extended operation
✅ Error messages are clear and actionable
