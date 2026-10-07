import mongoose, { Schema, Document } from 'mongoose';

export interface ITemplate extends Document {
  _id: string;
  userId?: string;
  name: string;
  category: string;
  description?: string;
  content: string;
  placeholders: Array<{ key: string; description: string; defaultValue?: string }>;
  metadata: Record<string, unknown>;
  isDefault: boolean;
  createdAt: Date;
  modifiedAt: Date;
}

const templateSchema = new Schema<ITemplate>(
  {
    _id: { type: String, required: true },
    userId: { type: String, ref: 'User' },
    name: { type: String, required: true },
    category: { type: String, required: true },
    description: { type: String },
    content: { type: String, required: true },
    placeholders: { type: Schema.Types.Mixed, default: [] },
    metadata: { type: Schema.Types.Mixed, default: {} },
    isDefault: { type: Boolean, default: false },
    modifiedAt: { type: Date, default: Date.now },
  },
  {
    timestamps: { createdAt: 'createdAt', updatedAt: false },
    _id: false,
  }
);

templateSchema.index({ category: 1 });
templateSchema.index({ userId: 1 }, { sparse: true });

export const Template = mongoose.model<ITemplate>('Template', templateSchema);
