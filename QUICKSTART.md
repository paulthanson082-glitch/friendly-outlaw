# Jules - Quick Start Guide 🚀

**A complete, production-ready writing assistant with web, mobile, and AI.**

---

## ⚡ 5-Minute Quick Start

### Prerequisites (1 minute)

```bash
# Install if you don't have them
- Node.js 18+ (https://nodejs.org)
- Docker (https://docker.com)
- Git (https://git-scm.com)
```

### Local Development (4 minutes)

```bash
# 1. Clone repository
git clone https://github.com/your-username/friendly-outlaw.git
cd friendly-outlaw

# 2. Setup environment
cp backend/.env.example backend/.env
# Edit backend/.env and add your ANTHROPIC_API_KEY

# 3. Start everything!
docker compose up --build

# 4. Open browser
# http://localhost:3000
```

**That's it!** Your app is now running. 🎉

---

## 📦 What's Running

| Component | Port | URL |
|-----------|------|-----|
| **Web App** | 3000 | http://localhost:3000 |
| **API** | 3000 | http://localhost:3000/api |
| **Health Check** | 3000 | http://localhost:3000/health |

---

## 🛑 Stop Everything

```bash
docker compose down
```

---

## 👨‍💻 Development Setup (Without Docker)

If you prefer to run directly:

### Backend

```bash
cd backend
npm install
npm run dev
# API runs on http://localhost:3000
```

### Frontend

```bash
cd frontend
npm install
npm run dev
# Web app runs on http://localhost:5173
```

### Mobile (Optional)

```bash
cd mobile
npm install
npm start
# Choose: i (iOS), a (Android), w (Web)
```

---

## 🧪 Testing

### Backend tests

```bash
cd backend
npm test
```

### Frontend tests

```bash
cd frontend
npm test
```

---

## 📚 Documentation

| Guide | Purpose |
|-------|---------|
| `README.md` | Project overview |
| `CLAUDE.md` | Code standards |
| `DEPLOYMENT.md` | Deploy to production |
| `PHASE3_DEPLOYMENT.md` | Backend details |
| `PHASE4_MOBILE.md` | Mobile deployment |
| `QUICKSTART.md` | This file! |

---

## 🔑 Environment Setup

### Get API Key

1. Visit https://console.anthropic.com
2. Create account and get API key
3. Copy to `backend/.env`:

```env
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxx
JWT_SECRET=your-secret-32-chars-minimum
```

### Optional: Custom Database

Default uses SQLite in `backend/data/app.db`

To use PostgreSQL:

```env
DATABASE_URL=postgresql://user:password@localhost:5432/jules
```

---

## 🌐 Web App Features

- 📄 **Documents** - Create, edit, search documents
- 📚 **Templates** - 20+ templates with placeholders
- 📊 **Kanban** - 5-column workflow board
- 🎯 **Goals** - Track writing progress
- ✨ **AI Chat** - Powered by Claude API

---

## 📱 Mobile App

Ready to deploy to iOS and Android:

```bash
cd mobile

# Development preview
npm start

# Build for production
npm run build:all

# Submit to stores
npm run submit:ios
npm run submit:android
```

See `PHASE4_MOBILE.md` for detailed steps.

---

## 🚀 Deploy to Production

Three options:

### Option 1: AWS ECS (Recommended)

```bash
./deploy.sh
# Choose option 3 or 2
```

### Option 2: DigitalOcean (Easiest)

```bash
./deploy.sh
# Choose option 4
# Then: doctl apps create --spec app.yaml
```

### Option 3: Manual VPS

```bash
./deploy.sh
# Choose option 5
# Follow DEPLOYMENT.md steps
```

See `DEPLOYMENT.md` for complete guide.

---

## 🆘 Troubleshooting

### Docker daemon not running

**macOS:**
```bash
open -a Docker  # Start Docker Desktop
```

**Linux:**
```bash
sudo systemctl start docker
```

### Port 3000 already in use

```bash
# Kill process using port 3000
sudo lsof -i :3000 | grep LISTEN | awk '{print $2}' | xargs kill -9

# Or use different port
PORT=3001 docker compose up
```

### Database locked

```bash
# Remove old database
rm backend/data/app.db

# Restart
docker compose restart app
```

### Node modules issues

```bash
# Clean and reinstall
rm -rf node_modules package-lock.json
npm install
```

---

## 📋 Project Structure

```
friendly-outlaw/
├── backend/              # Express API
│   ├── src/
│   │   ├── routes/      # 40+ endpoints
│   │   ├── services/    # Business logic
│   │   └── db/          # Database
│   ├── package.json
│   └── .env
│
├── frontend/             # React web app
│   ├── src/
│   │   ├── pages/       # 4 main pages
│   │   ├── components/
│   │   └── App.tsx
│   └── package.json
│
├── mobile/               # React Native
│   ├── src/
│   │   ├── screens/     # 6 screens
│   │   └── context/
│   └── package.json
│
├── Dockerfile            # Docker setup
├── docker-compose.yml    # Local dev
├── DEPLOYMENT.md         # Deploy guide
└── README.md            # Overview
```

---

## 🎯 Next Steps

1. **Local Testing** ✅
   ```bash
   docker compose up --build
   # Visit http://localhost:3000
   ```

2. **Add Features** (Optional)
   - Edit backend routes: `backend/src/routes/`
   - Edit frontend pages: `frontend/src/pages/`
   - Edit mobile screens: `mobile/src/screens/`

3. **Deploy** (When ready)
   ```bash
   ./pre-deploy-check.sh
   ./deploy.sh
   # Choose deployment option
   ```

4. **Mobile** (Optional)
   ```bash
   cd mobile
   ./deploy-mobile.sh
   # Build for iOS/Android
   ```

---

## 📞 Support

- **Issues?** Check `DEPLOYMENT.md` troubleshooting section
- **Questions?** See `README.md` and `CLAUDE.md`
- **Deploy help?** See phase-specific guides

---

## ✨ What You Get

✅ **Web App** - Full-featured writing assistant
✅ **Mobile Apps** - iOS & Android ready
✅ **REST API** - 40+ endpoints documented
✅ **AI Integration** - Claude API ready
✅ **Database** - SQLite or PostgreSQL
✅ **Deployment** - 4 production options
✅ **Security** - JWT, HTTPS, input validation
✅ **Documentation** - Complete guides

---

## 🚀 Ready to Launch!

```bash
docker compose up --build
```

Then visit: **http://localhost:3000**

Happy writing! ✍️
