/**
 * Shared types for the friendly-outlaw monorepo
 * Exported by all packages: frontend, backend, mobile
 */

// API Response types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: string;
}

// Document types
export interface Document {
  id: string;
  title: string;
  content: string;
  category?: string;
  createdAt: Date;
  updatedAt: Date;
  wordCount: number;
}

// Template types
export interface Template {
  id: string;
  name: string;
  description?: string;
  category: string;
  content: string;
  placeholders: Placeholder[];
}

export interface Placeholder {
  id: string;
  name: string;
  defaultValue?: string;
  type: 'text' | 'number' | 'date' | 'select';
  options?: string[];
}

// User types
export interface User {
  id: string;
  email: string;
  name?: string;
  createdAt: Date;
  updatedAt: Date;
}

// AI Configuration types
export interface AIConfig {
  apiKey?: string;
  model: 'claude-3-opus' | 'claude-3-sonnet' | 'claude-3-haiku';
  maxTokens: number;
  temperature: number;
}

// Export all types as namespace for convenience
export namespace FriendlyOutlaw {
  export type Document = Document;
  export type Template = Template;
  export type User = User;
  export type AIConfig = AIConfig;
}
