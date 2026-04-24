import mongoose, { Schema, Document } from 'mongoose';

export interface IUserSession extends Document {
  _id: string;
  userId: string;
  startTime: Date;
  endTime?: Date;
  durationSeconds?: number;
  wordsWritten: number;
  aiInteractions: number;
  metadata: Record<string, unknown>;
}

const userSessionSchema = new Schema<IUserSession>(
  {
    _id: { type: String, required: true },
    userId: { type: String, required: true, ref: 'User' },
    startTime: { type: Date, required: true },
    endTime: { type: Date },
    durationSeconds: { type: Number },
    wordsWritten: { type: Number, default: 0 },
    aiInteractions: { type: Number, default: 0 },
    metadata: { type: Schema.Types.Mixed, default: {} },
  },
  { _id: false }
);

userSessionSchema.index({ userId: 1 });
userSessionSchema.index({ startTime: 1 });

export const UserSession = mongoose.model<IUserSession>('UserSession', userSessionSchema);
