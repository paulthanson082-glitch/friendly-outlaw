import mongoose, { Schema, Document } from 'mongoose';

export interface IChatSession extends Document {
  _id: string;
  userId: string;
  startedAt: Date;
  lastMessageAt: Date;
  context: Record<string, unknown>;
  deletedAt?: Date;
}

const chatSessionSchema = new Schema<IChatSession>(
  {
    _id: { type: String, required: true },
    userId: { type: String, required: true, ref: 'User' },
    startedAt: { type: Date, default: Date.now },
    lastMessageAt: { type: Date, default: Date.now },
    context: { type: Schema.Types.Mixed, default: {} },
    deletedAt: { type: Date },
  },
  { _id: false }
);

chatSessionSchema.index({ userId: 1 });
chatSessionSchema.index({ startedAt: 1 });

export interface IChatMessage extends Document {
  _id: string;
  sessionId: string;
  role: string;
  content: string;
  timestamp: Date;
  metadata: Record<string, unknown>;
}

const chatMessageSchema = new Schema<IChatMessage>(
  {
    _id: { type: String, required: true },
    sessionId: { type: String, required: true, ref: 'ChatSession' },
    role: { type: String, required: true },
    content: { type: String, required: true },
    timestamp: { type: Date, default: Date.now },
    metadata: { type: Schema.Types.Mixed, default: {} },
  },
  { _id: false }
);

chatMessageSchema.index({ sessionId: 1 });
chatMessageSchema.index({ timestamp: 1 });

export const ChatSession = mongoose.model<IChatSession>('ChatSession', chatSessionSchema);
export const ChatMessage = mongoose.model<IChatMessage>('ChatMessage', chatMessageSchema);
