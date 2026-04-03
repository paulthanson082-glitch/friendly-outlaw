import type { Attachment } from '../utils/attachments.js'

// ─── Message union ────────────────────────────────────────────────────────────

export interface AttachmentMessage {
  type: 'attachment'
  attachment: Attachment
}

export interface UserMessage {
  type: 'user'
  content: string
}

export interface AssistantMessage {
  type: 'assistant'
  content: string
}

export interface ToolUseMessage {
  type: 'tool_use'
  name: string
  input: unknown
}

export interface ToolResultMessage {
  type: 'tool_result'
  content: string
}

export type Message =
  | AttachmentMessage
  | UserMessage
  | AssistantMessage
  | ToolUseMessage
  | ToolResultMessage
