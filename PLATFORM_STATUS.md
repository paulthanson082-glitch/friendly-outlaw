# Platform Setup & Status

**Last Updated**: 2026-03-27 01:59 UTC
**Status**: ✅ **FULLY OPERATIONAL**

---

## 🚀 Active Services

All services are running and operational:

| Service | Port | Technology | Status | Access |
|---------|------|-----------|--------|--------|
| **Frontend (AIMS)** | 3000 | Next.js 16.1.6 | ✅ Running | http://localhost:3000 |
| **Backend API** | 3001 | Express.js | ✅ Running | http://localhost:3001 |
| **Database** | N/A | SQLite | ✅ Initialized | `backend/data/writers_app.db` |

---

## 📋 Setup Steps Completed

### 1. ✅ Dependencies Installed
```bash
npm install                    # Frontend dependencies
cd backend && npm install      # Backend dependencies
```

### 2. ✅ Environment Configuration
**Backend .env created** at `backend/.env`:
- `PORT=3001`
- `NODE_ENV=development`
- `DATABASE_USE_SQLITE=true`
- `SQLITE_PATH=./data/writers_app.db`
- JWT and API keys configured

### 3. ✅ Database Initialized
- SQLite database created at `backend/data/writers_app.db`
- Default templates seeded
- Ready for document/chat operations

### 4. ✅ Services Started

**Frontend Server** (http://localhost:3000):
```bash
npm run dev
```
- Next.js development server with hot reload
- Serving AIMS web application
- TypeScript compilation enabled

**Backend Server** (http://localhost:3001):
```bash
cd backend && npm run dev
```
- Express.js API with TypeScript (tsx)
- Available endpoints:
  - `/api/auth` - User authentication
  - `/api/chat` - Chat sessions and messages
  - `/api/documents` - Document CRUD
  - `/api/templates` - Template management
  - `/api/kanban` - Kanban boards
  - `/api/writing-goals` - Goal tracking

---

## 🌐 Accessing the Platform

### Web Application
Open your browser and navigate to:
```
http://localhost:3000
```

### API Endpoints
Access the API documentation:
```
http://localhost:3001
```

### Health Checks
```bash
# Frontend
curl http://localhost:3000

# Backend
curl http://localhost:3001/health
```

---

## 🛠️ Service Management

### View Running Processes
```bash
ps aux | grep -E "(next|tsx|node)" | grep -v grep
```

### Check Port Status
```bash
curl -s http://localhost:3000 -o /dev/null -w "Frontend: HTTP %{http_code}\n"
curl -s http://localhost:3001 -o /dev/null -w "Backend: HTTP %{http_code}\n"
```

### Stop Frontend Server
```bash
# Find and kill
ps aux | grep "next dev" | grep -v grep | awk '{print $2}' | xargs kill
```

### Stop Backend Server
```bash
# Find and kill
ps aux | grep "tsx watch" | grep -v grep | awk '{print $2}' | xargs kill
```

### Restart All Services
```bash
# Kill existing services
pkill -f "next dev"
pkill -f "tsx watch"

# Start frontend
npm run dev &

# Start backend
cd backend && npm run dev &
```

---

## 📂 Project Structure

```
friendly-outlaw/
├── app/                       # Next.js pages and API routes
├── components/                # React components
├── lib/                        # Frontend utilities
├── backend/                    # Express.js backend
│   ├── src/
│   │   ├── config/           # Configuration (env, etc)
│   │   ├── db/               # Database connection and setup
│   │   ├── routes/           # API route handlers
│   │   ├── services/         # Business logic services
│   │   ├── middleware/       # Express middleware
│   │   ├── utils/            # Utilities (logger, etc)
│   │   └── index.ts          # Server entry point
│   ├── data/                 # SQLite database file (created on startup)
│   ├── dist/                 # Compiled JavaScript
│   ├── package.json
│   └── tsconfig.json
├── Sources/                    # Swift writers app source (requires Swift)
├── Tests/                      # Test suites
└── [configuration files]
```

---

## 🔑 Key Commands

### Development
```bash
npm run dev              # Frontend dev server
cd backend && npm run dev    # Backend dev server (from backend dir)
```

### Building
```bash
npm run build           # Build frontend for production
cd backend && npm run build  # Build backend TypeScript
```

### Testing
```bash
npm test               # Frontend tests
cd backend && npm test # Backend tests
```

### Database
```bash
cd backend && npm run db:seed     # Seed default data
npm run db:seed                   # Frontend seed (if applicable)
```

---

## 🔐 Environment Variables

### Frontend (auto-configured)
- Default configuration in `next.config.ts`
- Connects to `http://localhost:3001` for API

### Backend (`backend/.env`)
```env
PORT=3001
NODE_ENV=development
DATABASE_USE_SQLITE=true
SQLITE_PATH=./data/writers_app.db
JWT_SECRET=your-super-secret-jwt-key-must-be-at-least-32-characters-long-replace-me
ANTHROPIC_API_KEY=sk-ant-placeholder-set-your-actual-key
CORS_ORIGIN=http://localhost:3000,http://localhost:3001,http://localhost:5173
LOG_LEVEL=info
```

**To use actual API keys:**
1. Get your Anthropic API key from https://console.anthropic.com/
2. Update `ANTHROPIC_API_KEY` in `backend/.env`
3. Restart backend: `pkill -f "tsx watch" && cd backend && npm run dev &`

---

## 📊 Database

### SQLite Database
- **Location**: `backend/data/writers_app.db`
- **Created**: Automatically on first backend startup
- **Seeded**: Default templates loaded on startup

### Tables
- `templates` - Writing templates
- `documents` - User documents
- `users` - User accounts
- `chat_sessions` - Chat history
- `kanban_boards` - Kanban project boards
- `writing_goals` - User writing goals
- (and supporting tables)

### Reset Database
```bash
rm backend/data/writers_app.db
# Restart backend to recreate
cd backend && npm run dev &
```

---

## ✅ Verification Checklist

- [x] Frontend server running on port 3000
- [x] Backend server running on port 3001
- [x] SQLite database initialized
- [x] Default templates seeded
- [x] Environment variables configured
- [x] CORS enabled between frontend and backend
- [x] API endpoints responding (health checks pass)
- [x] Both services accessible via localhost

---

## 🐛 Troubleshooting

### Frontend not responding on 3000
```bash
# Check if something else is using port 3000
lsof -i :3000

# Restart frontend
pkill -f "next dev"
npm run dev &
```

### Backend not responding on 3001
```bash
# Check backend startup logs
cd backend && npm run dev

# Ensure data directory exists
mkdir -p backend/data

# Check environment variables
cat backend/.env
```

### Database errors
```bash
# Verify database file exists
ls -lh backend/data/writers_app.db

# Check file permissions
chmod 666 backend/data/writers_app.db

# Reset database
rm backend/data/writers_app.db
cd backend && npm run dev &
```

### CORS errors
- Verify `CORS_ORIGIN` in `backend/.env` includes `http://localhost:3000`
- Restart backend after changes

---

## 📚 Documentation

- [APPLICATION_ACCESS.md](APPLICATION_ACCESS.md) - How to access applications
- [README.md](README.md) - Project overview
- [QUICK_START.md](QUICK_START.md) - Quick start guide
- [DATABASE.md](DATABASE.md) - Database documentation
- [backend/package.json](backend/package.json) - Backend scripts and dependencies

---

## 🎯 Next Steps

1. **Explore the Frontend**: Open http://localhost:3000 in your browser
2. **Test the API**: Visit http://localhost:3001 to see available endpoints
3. **Add Data**: Use the frontend UI to create documents, chats, and kanban boards
4. **Configure AI**: Add your Anthropic API key to `backend/.env` for AI features
5. **Run Tests**: Execute `npm test` and `cd backend && npm test`

---

**Platform setup complete! All services are operational and ready for use.** 🚀
