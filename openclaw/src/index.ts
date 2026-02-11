/**
 * OpenClaw Plugin for Friendly Outlaw Writers App
 * 
 * This plugin integrates the Writers App with OpenClaw gateway runtime,
 * enabling live observation streaming to messaging channels (Telegram, Discord, etc.)
 * and providing writer context synchronization.
 */

// MARK: - Types

interface PluginLogger {
  info(message: string): void;
  warn(message: string): void;
  error(message: string): void;
}

interface PluginConfig {
  workerPort?: number;
  project?: string;
  observationFeed?: {
    enabled?: boolean;
    channel?: string;
    to?: string;
  };
}

interface ServiceContext {
  signal?: AbortSignal;
}

interface CommandContext {
  args: string;
}

interface ChannelAPI {
  telegram: {
    sendMessageTelegram(to: string, text: string): Promise<any>;
  };
  discord: {
    sendMessageDiscord(to: string, text: string): Promise<any>;
  };
  signal: {
    sendMessageSignal(to: string, text: string): Promise<any>;
  };
  slack: {
    sendMessageSlack(to: string, text: string): Promise<any>;
  };
  whatsapp: {
    sendMessageWhatsApp(to: string, text: string): Promise<any>;
  };
  line: {
    sendMessageLine(to: string, text: string): Promise<any>;
  };
}

interface RuntimeAPI {
  channel: ChannelAPI;
}

interface OpenClawPluginApi {
  logger: PluginLogger;
  pluginConfig: PluginConfig;
  runtime: RuntimeAPI;
  registerService(name: string, service: {
    start: (ctx: ServiceContext) => Promise<void>;
    stop?: (ctx: ServiceContext) => Promise<void>;
  }): void;
  registerCommand(name: string, handler: (ctx: CommandContext) => Promise<string>): void;
}

interface ObservationEvent {
  title: string;
  subtitle?: string;
  timestamp?: string;
}

// MARK: - Constants

const MAX_SSE_BUFFER_SIZE = 1024 * 1024; // 1MB
const RECONNECT_BASE_DELAY = 1000; // 1 second
const RECONNECT_MAX_DELAY = 30000; // 30 seconds

// MARK: - Module State

let sseAbortController: AbortController | null = null;
let connectionState: 'disconnected' | 'connecting' | 'connected' = 'disconnected';
let connectionPromise: Promise<void> | null = null;
let reconnectAttempts = 0;

// MARK: - Helper Functions

/**
 * Send a message to the configured messaging channel
 */
async function sendToChannel(
  api: OpenClawPluginApi,
  channel: string,
  to: string,
  text: string
): Promise<void> {
  const channelSendFunctions: Record<string, (to: string, text: string) => Promise<any>> = {
    telegram: api.runtime.channel.telegram.sendMessageTelegram,
    discord: api.runtime.channel.discord.sendMessageDiscord,
    signal: api.runtime.channel.signal.sendMessageSignal,
    slack: api.runtime.channel.slack.sendMessageSlack,
    whatsapp: api.runtime.channel.whatsapp.sendMessageWhatsApp,
    line: api.runtime.channel.line.sendMessageLine,
  };

  const sendFn = channelSendFunctions[channel];
  if (!sendFn) {
    throw new Error(`Unsupported channel: ${channel}`);
  }

  // Guard against missing channel integration
  try {
    await sendFn.call(api.runtime.channel[channel as keyof ChannelAPI], to, text);
  } catch (error) {
    if (error instanceof Error && error.message.includes('not available')) {
      api.logger.warn(`[friendly-outlaw] Channel ${channel} integration not available`);
      throw error;
    }
    throw error;
  }
}

/**
 * Format an observation event for display
 */
function formatObservation(event: ObservationEvent): string {
  let message = `📝 ${event.title}`;
  if (event.subtitle) {
    message += `\n${event.subtitle}`;
  }
  if (event.timestamp) {
    message += `\n🕐 ${event.timestamp}`;
  }
  return message;
}

/**
 * Calculate exponential backoff delay for reconnection
 */
function getReconnectDelay(): number {
  const delay = Math.min(
    RECONNECT_BASE_DELAY * Math.pow(2, reconnectAttempts),
    RECONNECT_MAX_DELAY
  );
  reconnectAttempts++;
  return delay;
}

/**
 * Connect to the Writers App SSE stream
 */
async function connectToSSEStream(
  api: OpenClawPluginApi,
  workerPort: number,
  channel: string,
  to: string
): Promise<void> {
  if (!sseAbortController) {
    api.logger.error('[friendly-outlaw] No abort controller available');
    return;
  }

  connectionState = 'connecting';
  const streamUrl = `http://localhost:${workerPort}/stream`;

  api.logger.info(`[friendly-outlaw] Connecting to SSE stream at ${streamUrl}`);

  try {
    const response = await fetch(streamUrl, {
      signal: sseAbortController.signal,
      headers: {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    if (!response.body) {
      throw new Error('No response body');
    }

    connectionState = 'connected';
    reconnectAttempts = 0; // Reset on successful connection
    api.logger.info('[friendly-outlaw] Connected to SSE stream');

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();

      if (done) {
        api.logger.info('[friendly-outlaw] SSE stream ended');
        break;
      }

      buffer += decoder.decode(value, { stream: true });

      // Prevent unbounded buffer growth
      if (buffer.length > MAX_SSE_BUFFER_SIZE) {
        api.logger.warn('[friendly-outlaw] SSE buffer size exceeded, truncating');
        buffer = buffer.slice(-MAX_SSE_BUFFER_SIZE / 2);
      }

      // Process complete SSE frames
      const frames = buffer.split('\n\n');
      buffer = frames.pop() || '';

      for (const frame of frames) {
        const dataLine = frame
          .split('\n')
          .find((line) => line.startsWith('data:'));
        
        if (!dataLine) continue;

        const data = dataLine.substring(5).trim();
        
        try {
          const event = JSON.parse(data);
          
          if (event.type === 'new_observation') {
            const observation: ObservationEvent = {
              title: event.title || 'New Writing Observation',
              subtitle: event.subtitle,
              timestamp: event.timestamp || new Date().toISOString(),
            };

            const message = formatObservation(observation);
            
            try {
              await sendToChannel(api, channel, to, message);
              api.logger.info(`[friendly-outlaw] Observation sent to ${channel}`);
            } catch (error) {
              if (error instanceof Error) {
                api.logger.error(`[friendly-outlaw] Failed to send observation: ${error.message}`);
              } else {
                api.logger.error('[friendly-outlaw] Failed to send observation: Unknown error');
              }
            }
          }
        } catch (error) {
          if (error instanceof Error) {
            api.logger.warn(`[friendly-outlaw] Failed to parse SSE data: ${error.message}`);
          } else {
            api.logger.warn('[friendly-outlaw] Failed to parse SSE data: Unknown error');
          }
        }
      }
    }
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      api.logger.info('[friendly-outlaw] SSE connection aborted');
      connectionState = 'disconnected';
      return;
    }

    if (error instanceof Error) {
      api.logger.error(`[friendly-outlaw] SSE connection error: ${error.message}`);
    } else {
      api.logger.error('[friendly-outlaw] SSE connection error: Unknown error');
    }

    connectionState = 'disconnected';

    // Reconnect with exponential backoff
    if (!sseAbortController?.signal.aborted) {
      const delay = getReconnectDelay();
      api.logger.info(`[friendly-outlaw] Reconnecting in ${delay}ms (attempt ${reconnectAttempts})`);

      await new Promise((resolve) => setTimeout(resolve, delay));

      if (!sseAbortController?.signal.aborted) {
        await connectToSSEStream(api, workerPort, channel, to);
      }
    }
  }
}

// MARK: - Plugin Entry Point

/**
 * Initialize the OpenClaw plugin
 */
export default function init(api: OpenClawPluginApi): void {
  api.logger.info('[friendly-outlaw] OpenClaw plugin loaded — v1.0.0');

  // Register the observation feed service
  api.registerService('friendly-outlaw-observation-feed', {
    start: async (_ctx: ServiceContext) => {
      // Abort any existing connection before starting a new one (idempotent start)
      if (sseAbortController) {
        sseAbortController.abort();
        if (connectionPromise) {
          await connectionPromise;
          connectionPromise = null;
        }
      }

      const config = api.pluginConfig;
      const workerPort = (config.workerPort as number) || 37777;
      const feedConfig = config.observationFeed as
        | { enabled?: boolean; channel?: string; to?: string }
        | undefined;

      if (!feedConfig?.enabled) {
        api.logger.info('[friendly-outlaw] Observation feed disabled');
        return;
      }

      if (!feedConfig.channel || !feedConfig.to) {
        api.logger.warn('[friendly-outlaw] Observation feed misconfigured — channel or target missing');
        return;
      }

      api.logger.info(`[friendly-outlaw] Observation feed starting — channel: ${feedConfig.channel}, target: ${feedConfig.to}`);

      sseAbortController = new AbortController();
      connectionPromise = connectToSSEStream(api, workerPort, feedConfig.channel, feedConfig.to);
    },

    stop: async (_ctx: ServiceContext) => {
      api.logger.info('[friendly-outlaw] Stopping observation feed');

      if (sseAbortController) {
        sseAbortController.abort();
        sseAbortController = null;
      }

      if (connectionPromise) {
        await connectionPromise;
        connectionPromise = null;
      }

      connectionState = 'disconnected';
      reconnectAttempts = 0;

      api.logger.info('[friendly-outlaw] Observation feed stopped');
    },
  });

  // Register the status command
  api.registerCommand('/friendly-outlaw-feed', async (_ctx: CommandContext) => {
    const config = api.pluginConfig;
    const feedConfig = config.observationFeed;

    if (!feedConfig?.enabled) {
      return '❌ Observation feed is disabled\n\nEnable it in your openclaw.json configuration.';
    }

    const status = connectionState === 'connected' ? '✅ Connected' :
                   connectionState === 'connecting' ? '🔄 Connecting...' :
                   '❌ Disconnected';

    return [
      '📊 Friendly Outlaw Writers App Status',
      '',
      `Feed Status: ${status}`,
      `Channel: ${feedConfig.channel || 'Not configured'}`,
      `Target: ${feedConfig.to || 'Not configured'}`,
      `Worker Port: ${config.workerPort || 37777}`,
      `Reconnect Attempts: ${reconnectAttempts}`,
    ].join('\n');
  });
}
