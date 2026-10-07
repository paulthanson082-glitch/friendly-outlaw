import mongoose, { Schema, Document } from 'mongoose';

export interface IDocument extends Document {
  _id: string;
  userId: string;
  title: string;
  content?: string;
  category: string;
  templateId?: string;
  metadata: Record<string, unknown>;
  wordCount: number;
  createdAt: Date;
  modifiedAt: Date;
  lastOpenedAt?: Date;
  tags?: string;
  deletedAt?: Date;
}

const documentSchema = new Schema<IDocument>(
  {
    _id: { type: String, required: true },
    userId: { type: String, required: true, ref: 'User' },
    title: { type: String, required: true },
    content: { type: String },
    category: { type: String, default: 'other' },
    templateId: { type: String },
    metadata: { type: Schema.Types.Mixed, default: {} },
    wordCount: { type: Number, default: 0 },
    modifiedAt: { type: Date, default: Date.now },
    lastOpenedAt: { type: Date },
    tags: { type: String },
    deletedAt: { type: Date },
  },
  {
    timestamps: { createdAt: 'createdAt', updatedAt: false },
    _id: false,
  }
);

documentSchema.index({ userId: 1 });
documentSchema.index({ category: 1 });
documentSchema.index({ createdAt: 1 });

export const DocumentModel = mongoose.model<IDocument>('Document', documentSchema);
