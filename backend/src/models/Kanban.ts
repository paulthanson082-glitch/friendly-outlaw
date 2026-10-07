import mongoose, { Schema, Document } from 'mongoose';

export interface IKanbanBoard extends Document {
  _id: string;
  userId: string;
  name: string;
  description?: string;
  createdAt: Date;
  metadata: Record<string, unknown>;
}

const kanbanBoardSchema = new Schema<IKanbanBoard>(
  {
    _id: { type: String, required: true },
    userId: { type: String, required: true, ref: 'User' },
    name: { type: String, required: true },
    description: { type: String },
    metadata: { type: Schema.Types.Mixed, default: {} },
  },
  {
    timestamps: { createdAt: 'createdAt', updatedAt: false },
    _id: false,
  }
);

kanbanBoardSchema.index({ userId: 1 });

export interface IKanbanTask extends Document {
  _id: string;
  boardId: string;
  title: string;
  description?: string;
  column: string;
  taskOrder: number;
  createdAt: Date;
  completedAt?: Date;
  metadata: Record<string, unknown>;
}

const kanbanTaskSchema = new Schema<IKanbanTask>(
  {
    _id: { type: String, required: true },
    boardId: { type: String, required: true, ref: 'KanbanBoard' },
    title: { type: String, required: true },
    description: { type: String },
    column: { type: String, default: 'backlog' },
    taskOrder: { type: Number, default: 0 },
    completedAt: { type: Date },
    metadata: { type: Schema.Types.Mixed, default: {} },
  },
  {
    timestamps: { createdAt: 'createdAt', updatedAt: false },
    _id: false,
  }
);

kanbanTaskSchema.index({ boardId: 1 });
kanbanTaskSchema.index({ column: 1 });

export const KanbanBoard = mongoose.model<IKanbanBoard>('KanbanBoard', kanbanBoardSchema);
export const KanbanTask = mongoose.model<IKanbanTask>('KanbanTask', kanbanTaskSchema);
