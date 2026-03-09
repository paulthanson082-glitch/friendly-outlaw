-- Users
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT,
  settings JSONB DEFAULT '{}',
  api_key_encrypted TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Documents
CREATE TABLE IF NOT EXISTS documents (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  category TEXT DEFAULT 'other',
  template_id TEXT,
  metadata JSONB DEFAULT '{}',
  word_count INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  modified_at TEXT DEFAULT CURRENT_TIMESTAMP,
  last_opened_at TEXT,
  tags TEXT,
  deleted_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_documents_user ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category);
CREATE INDEX IF NOT EXISTS idx_documents_created ON documents(created_at);

-- Templates
CREATE TABLE IF NOT EXISTS templates (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  content TEXT NOT NULL,
  placeholders JSONB NOT NULL DEFAULT '[]',
  metadata JSONB DEFAULT '{}',
  is_default BOOLEAN DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  modified_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_templates_category ON templates(category);
CREATE INDEX IF NOT EXISTS idx_templates_user ON templates(user_id) WHERE user_id IS NOT NULL;

-- Chat Sessions
CREATE TABLE IF NOT EXISTS chat_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  started_at TEXT DEFAULT CURRENT_TIMESTAMP,
  last_message_at TEXT DEFAULT CURRENT_TIMESTAMP,
  context JSONB DEFAULT '{}',
  deleted_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user ON chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_started ON chat_sessions(started_at);

-- Chat Messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB DEFAULT '{}',
  FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_timestamp ON chat_messages(timestamp);

-- Kanban Boards
CREATE TABLE IF NOT EXISTS kanban_boards (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB DEFAULT '{}',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_kanban_boards_user ON kanban_boards(user_id);

-- Kanban Tasks
CREATE TABLE IF NOT EXISTS kanban_tasks (
  id TEXT PRIMARY KEY,
  board_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  column TEXT DEFAULT 'backlog',
  task_order INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT,
  metadata JSONB DEFAULT '{}',
  FOREIGN KEY (board_id) REFERENCES kanban_boards(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_kanban_tasks_board ON kanban_tasks(board_id);
CREATE INDEX IF NOT EXISTS idx_kanban_tasks_column ON kanban_tasks(column);

-- Writing Goals
CREATE TABLE IF NOT EXISTS writing_goals (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  goal_type TEXT NOT NULL,
  unit TEXT NOT NULL,
  target_value INTEGER NOT NULL,
  current_value INTEGER DEFAULT 0,
  deadline TEXT,
  achieved_at TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB DEFAULT '{}',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_writing_goals_user ON writing_goals(user_id);

-- AI Suggestions
CREATE TABLE IF NOT EXISTS ai_suggestions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  document_id TEXT,
  tool_used TEXT NOT NULL,
  prompt TEXT NOT NULL,
  response TEXT NOT NULL,
  timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
  is_applied BOOLEAN DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_user ON ai_suggestions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_tool ON ai_suggestions(tool_used);

-- User Sessions (analytics)
CREATE TABLE IF NOT EXISTS user_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  duration_seconds INTEGER,
  words_written INTEGER DEFAULT 0,
  ai_interactions INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_start ON user_sessions(start_time);
