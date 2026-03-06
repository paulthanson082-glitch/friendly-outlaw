# Jules - Phase 1: Core Chat & Documents

## Overview

Phase 1 implements the core Jules chatbot experience on the web with:
- **Backend**: Node.js + Express API with real-time streaming
- **Frontend**: React SPA with authentication
- **Streaming**: Server-Sent Events (SSE) for real-time Claude responses
- **Database**: In-memory (Phase 2 will add PostgreSQL/SQLite)

## Architecture

```
┌─────────────────┐         ┌──────────────────┐
│  React SPA      │         │  Node.js + Express│
│  (frontend/)    │────────▶│  (backend/)       │
│                 │         │                  │
│ - Login/Register │        │ - Auth routes    │
│ - Chat UI       │        │ - Chat routes    │
│ - SSE streaming │        │ - AI Service     │
└─────────────────┘         └──────────────────┘
                                      │
                                      ▼
                            ┌──────────────────┐
                            │  Anthropic API   │
                            │  Claude 3.5      │
                            │  Sonnet          │
                            └──────────────────┘
```

## Quick Start

### Prerequisites
- Node.js 18+ and npm
- Anthropic API key: https://console.anthropic.com

### 1. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env with your Anthropic API key
# ANTHROPIC_API_KEY=sk-ant-your-key-here

# Start development server
npm run dev
```

Server will run on `http://localhost:3000`

Test the API:
```bash
curl http://localhost:3000/health
# Should return: {"status": "ok", "timestamp": "..."}
```

### 2. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Start development server
npm run dev
```

App will run on `http://localhost:5173`

### 3. Access Jules

1. Open http://localhost:5173 in your browser
2. Click "Sign up" to create an account
3. Start chatting with Jules!

## API Endpoints

### Authentication
```
POST   /api/auth/register        Create account
POST   /api/auth/login           Login
GET    /api/auth/me              Get current user
PUT    /api/auth/profile         Update profile
```

### Chat
```
POST   /api/chat/sessions               Create session
GET    /api/chat/sessions               List sessions
GET    /api/chat/sessions/:sessionId    Get session
GET    /api/chat/sessions/:sessionId/history  Get history
POST   /api/chat/send (SSE stream)      Send message
POST   /api/chat/sessions/:sessionId/clear    Clear history
DELETE /api/chat/sessions/:sessionId    Delete session
```

## Project Structure

```
backend/
├── src/
│   ├── services/
│   │   ├── aiService.ts      # Anthropic API + streaming
│   │   └── chatService.ts    # Jules conversation logic
│   ├── routes/
│   │   ├── auth.ts           # Auth endpoints
│   │   └── chat.ts           # Chat endpoints
│   ├── middleware/
│   │   ├── auth.ts           # JWT authentication
│   │   └── errorHandler.ts   # Error handling
│   ├── utils/
│   │   ├── logger.ts         # Logging
│   │   ├── jwt.ts            # Token generation
│   │   └── errors.ts         # Custom errors
│   └── index.ts              # Express app
├── package.json
├── tsconfig.json
└── .env.example

frontend/
├── src/
│   ├── pages/
│   │   └── ChatPage.tsx      # Main chat interface
│   ├── components/
│   ├── services/
│   │   └── api.ts            # API client
│   ├── hooks/
│   │   └── useChat.ts        # Chat state management
│   ├── context/
│   │   └── AuthContext.tsx   # Global auth state
│   ├── App.tsx               # Main app + routing
│   └── main.tsx              # React entry point
├── public/
│   └── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
└── .env.example
```

## Development Workflow

### Backend

```bash
cd backend

# Start with hot reload
npm run dev

# Run tests
npm test

# Build for production
npm run build

# Run in production
npm start
```

### Frontend

```bash
cd frontend

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Features Implemented

✅ **Authentication**
- User registration with email/password
- JWT-based login
- Token stored in localStorage
- Auto-logout on 401

✅ **Chat**
- Real-time SSE streaming from Claude
- Session management (create, load, delete)
- Message history persistence
- Clear conversation history

✅ **UI/UX**
- Responsive design (mobile, tablet, desktop)
- Dark-friendly gradient UI
- Typing indicators
- Example prompts for new sessions
- Error messages and loading states

✅ **AI Integration**
- Anthropic API streaming
- Claude 3.5 Sonnet model
- Configurable system prompts
- Token limit configuration (default 4096)
- Temperature control (default 0.7)

## Troubleshooting

### Backend won't start
```bash
# Check if port 3000 is in use
lsof -i :3000

# Restart with a different port
PORT=3001 npm run dev
```

### Frontend can't reach backend
```bash
# Update VITE_API_URL in frontend/.env
VITE_API_URL=http://localhost:3000/api
```

### API key errors
```bash
# Check your Anthropic API key
# Make sure it's set in backend/.env
echo $ANTHROPIC_API_KEY
```

### CORS errors
```bash
# Backend CORS is configured for localhost:3001 and :5173
# Update CORS_ORIGIN in backend/.env if using different ports
CORS_ORIGIN=http://localhost:3001,http://localhost:5173
```

## Next Steps (Phase 2)

Phase 2 will add:
- Document management (create, edit, export)
- Template browser and filling
- Kanban boards with drag-and-drop
- Writing goal tracking
- Database persistence (PostgreSQL/SQLite)
- Full-text search
- AI suggestion history

## Testing on iPad

To test Jules on iPad:

1. **Local Network**
   ```bash
   # Find your Mac's IP
   ifconfig | grep "inet "

   # On iPad, navigate to http://<YOUR_MAC_IP>:5173
   ```

2. **Production Deployment** (coming Phase 3)
   - PWA installation to home screen
   - Works offline (coming Phase 3)
   - Full native app experience

## Contributing

- Backend code is TypeScript in `backend/src/`
- Frontend code is React + TypeScript in `frontend/src/`
- Follow existing patterns for new features
- Run tests before committing
- Update this README for significant changes

## License

MIT
