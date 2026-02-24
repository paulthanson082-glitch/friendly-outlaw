import Anthropic from "@anthropic-ai/sdk";
import { getCharacterByHandle } from "./characters";

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

export interface ConversationMessage {
  from: string;
  to: string;
  content: string;
  timestamp: string;
}

export interface Memory {
  memory: string;
  importance: number;
  created_at: string;
}

/**
 * Generate a bot response using Claude. The bot speaks in character based on
 * its personality definition and recent conversation history.
 */
export async function generateBotResponse(
  speakerHandle: string,
  listenerHandle: string,
  recentMessages: ConversationMessage[],
  memories: Memory[]
): Promise<string> {
  const speaker = getCharacterByHandle(speakerHandle);
  const listener = getCharacterByHandle(listenerHandle);

  const speakerLabel = speaker ? speaker.name : `@${speakerHandle}`;
  const listenerLabel = listener ? listener.name : `@${listenerHandle}`;

  const systemPrompt = buildSystemPrompt(speakerHandle, listenerHandle, memories);

  // Build a conversation transcript for context
  const conversationLines = recentMessages
    .slice(-10)
    .map((m) => {
      const fromName = getCharacterByHandle(m.from)?.name ?? `@${m.from}`;
      return `${fromName}: ${m.content}`;
    })
    .join("\n");

  const userPrompt = conversationLines
    ? `Here is your recent conversation with ${listenerLabel}:\n\n${conversationLines}\n\nNow respond naturally as ${speakerLabel} in one or two sentences.`
    : `You just ran into ${listenerLabel} in the town. Start a friendly, in-character conversation in one or two sentences.`;

  const response = await anthropic.messages.create({
    model: "claude-haiku-4-5",
    max_tokens: 256,
    messages: [{ role: "user", content: userPrompt }],
    system: systemPrompt,
  });

  const block = response.content[0];
  if (block.type !== "text") {
    throw new Error("Unexpected response type from Claude");
  }

  return block.text.trim();
}

function buildSystemPrompt(
  speakerHandle: string,
  listenerHandle: string,
  memories: Memory[]
): string {
  const speaker = getCharacterByHandle(speakerHandle);
  const listener = getCharacterByHandle(listenerHandle);

  const speakerName = speaker?.name ?? speakerHandle;
  const listenerName = listener?.name ?? listenerHandle;
  const personality = speaker?.personality ?? "Friendly and conversational.";
  const interests = speaker?.interests?.join(", ") ?? "various topics";
  const initialPlan = speaker?.initialPlan ?? "Explore the town.";

  const memorySection =
    memories.length > 0
      ? `\n\nYour recent memories:\n${memories.map((m) => `- ${m.memory}`).join("\n")}`
      : "";

  return `You are ${speakerName}, a resident of AI Town. You are talking to ${listenerName}.

Personality: ${personality}
Interests: ${interests}
Today's plan: ${initialPlan}${memorySection}

Rules:
- Speak only as ${speakerName}. Do not describe actions or add stage directions.
- Stay fully in character. Keep replies short (1-3 sentences).
- Be natural, curious, and engaging — like a real town resident would be.
- Do not mention you are an AI or a bot.`;
}

/**
 * Generate a memory summary after a conversation exchange.
 * This keeps a compact record of notable things said.
 */
export async function generateMemory(
  botHandle: string,
  otherHandle: string,
  messages: ConversationMessage[]
): Promise<string> {
  const bot = getCharacterByHandle(botHandle);
  const other = getCharacterByHandle(otherHandle);
  const botName = bot?.name ?? botHandle;
  const otherName = other?.name ?? otherHandle;

  const transcript = messages
    .slice(-6)
    .map((m) => {
      const from = getCharacterByHandle(m.from)?.name ?? m.from;
      return `${from}: ${m.content}`;
    })
    .join("\n");

  const response = await anthropic.messages.create({
    model: "claude-haiku-4-5",
    max_tokens: 100,
    messages: [
      {
        role: "user",
        content: `Summarize in one sentence what ${botName} learned or felt after this conversation with ${otherName}:\n\n${transcript}`,
      },
    ],
    system:
      "You write brief, first-person memory summaries for AI characters. Output exactly one sentence, no quotes.",
  });

  const block = response.content[0];
  if (block.type !== "text") return "";
  return block.text.trim();
}
