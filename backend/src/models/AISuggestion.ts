import mongoose, { Schema, Document } from 'mongoose';

export interface IAISuggestion extends Document {
  _id: string;
  userId: string;
  documentId?: string;
  toolUsed: string;
  prompt: string;
  response: string;
  timestamp: Date;
  isApplied: boolean;
  metadata: Record<string, unknown>;
}

const aiSuggestionSchema = new Schema<IAISuggestion>(
  {
    _id: { type: String, required: true },
    userId: { type: String, required: true, ref: 'User' },
    documentId: { type: String, ref: 'Document' },
    toolUsed: { type: String, required: true },
    prompt: { type: String, required: true },
    response: { type: String, required: true },
    timestamp: { type: Date, default: Date.now },
    isApplied: { type: Boolean, default: false },
    metadata: { type: Schema.Types.Mixed, default: {} },
  },
  { _id: false }
);

aiSuggestionSchema.index({ userId: 1 });
aiSuggestionSchema.index({ toolUsed: 1 });

export const AISuggestion = mongoose.model<IAISuggestion>('AISuggestion', aiSuggestionSchema);
