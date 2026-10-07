import mongoose, { Schema, Document } from 'mongoose';

export interface IWritingGoal extends Document {
  _id: string;
  userId: string;
  title: string;
  description?: string;
  goalType: string;
  unit: string;
  targetValue: number;
  currentValue: number;
  deadline?: Date;
  achievedAt?: Date;
  createdAt: Date;
  metadata: Record<string, unknown>;
}

const writingGoalSchema = new Schema<IWritingGoal>(
  {
    _id: { type: String, required: true },
    userId: { type: String, required: true, ref: 'User' },
    title: { type: String, required: true },
    description: { type: String },
    goalType: { type: String, required: true },
    unit: { type: String, required: true },
    targetValue: { type: Number, required: true },
    currentValue: { type: Number, default: 0 },
    deadline: { type: Date },
    achievedAt: { type: Date },
    metadata: { type: Schema.Types.Mixed, default: {} },
  },
  {
    timestamps: { createdAt: 'createdAt', updatedAt: false },
    _id: false,
  }
);

writingGoalSchema.index({ userId: 1 });

export const WritingGoal = mongoose.model<IWritingGoal>('WritingGoal', writingGoalSchema);
