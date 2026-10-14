# Adult Joke Bot — Design Specification

**Date:** October 11, 2026  
**Author:** Claude  
**Status:** Design Complete (Awaiting Implementation)

---

## 1. Overview

**Adult Joke Bot** is a text-based conversational application that generates and delivers adult-oriented jokes across web and mobile platforms. Users can request jokes by topic, engage in comedic banter with an AI, and save favorite jokes to their account.

**Core features:**
- Request jokes by category (relationships, work, tech, general, etc.)
- Conversational banter (joke follow-ups, related humor)
- User accounts with saved favorites
- Text-based interface (no voice initially)

**Platforms:**
- Web: React/Next.js (desktop & tablet)
- Mobile: React Native (iOS & Android, shared codebase)

**Cost target:** $0/month (free tier + self-hosted components)

---

## 2. System Architecture

### 2.1 High-Level Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERFACES                           │
│  ┌──────────────────┐        ┌──────────────────┐           │
│  │   Web (Next.js)  │        │  Mobile (React   │           │
│  │   (Vercel)       │        │   Native)        │           │
│  └────────┬─────────┘        └────────┬─────────┘           │
└───────────┼──────────────────────────┼────────────────────────┘
            │                          │
            └──────────────┬───────────┘
                           │ REST API
┌──────────────────────────┼──────────────────────────┐
│                          ▼                          │
│        Node.js REST API (Firebase Cloud            │
│              Functions)                             │
│                                                     │
│  Endpoints:                                         │
│  - POST /auth/signup, /auth/login                  │
│  - POST /jokes/random, /jokes/request              │
│  - POST /jokes/favorites, GET /jokes/my-favorites  │
│  - POST /chat, GET /chat/history                   │
└──────┬──────────────────────┬──────────────────────┘
       │                      │
       ▼                      ▼
┌─────────────────┐   ┌──────────────────┐
│   Firestore     │   │  External APIs   │
│   Database      │   │                  │
│                 │   │ - JokeAPI.dev    │
│ - users         │   │ - Claude API     │
│ - jokes         │   │ - Ollama (self)  │
│ - favorites     │   │                  │
│ - conversations │   └──────────────────┘
└─────────────────┘
```

### 2.2 Data Flow

**Joke Request:**
1. User requests joke (e.g., "Tell me a work joke")
2. Frontend sends POST `/jokes/request` with topic
3. Backend queries JokeAPI.dev by category
4. Returns joke text + metadata
5. Frontend displays joke with "Save" button
6. User can save to favorites → stored in Firestore

**Conversational Banter:**
1. User types follow-up (e.g., "Tell me more about that")
2. Frontend sends POST `/chat` with message + history
3. Backend sends to Claude API (or Ollama) for response
4. Claude generates witty follow-up
5. Response returned and displayed
6. Conversation logged in Firestore for persistence

---

## 3. Backend (Node.js + Firebase)

### 3.1 Technology Stack
- **Runtime:** Node.js 18+
- **Framework:** Express.js or Fastify (lightweight for Cloud Functions)
- **Deployment:** Firebase Cloud Functions
- **Database:** Firestore (NoSQL, real-time)
- **Authentication:** Firebase Auth (JWT-based)

### 3.2 API Endpoints

#### Authentication
```
POST /auth/signup
  Body: { email, password, username }
  Response: { userId, token, expiresIn }

POST /auth/login
  Body: { email, password }
  Response: { userId, token, expiresIn }

POST /auth/logout
  Response: { success: true }
```

#### Jokes
```
POST /jokes/random
  Query: ?category=work|relationships|general
  Response: { jokeId, text, category }

POST /jokes/request
  Body: { topic: string }
  Response: { jokeId, text, category }

POST /jokes/favorites
  Body: { jokeId, action: "save" | "unsave" }
  Response: { isFavorited: boolean }

GET /jokes/my-favorites
  Response: [{ jokeId, text, category, savedAt }]
```

#### Chat
```
POST /chat
  Body: { message: string, conversationId?: string }
  Response: { reply: string, conversationId: string }
  Note: Bot addresses user by their name (e.g., "Paul") in responses

GET /chat/history
  Query: ?conversationId=<id>&limit=50
  Response: [{ type: "user"|"bot", text: string, timestamp }]
```

### 3.3 Error Handling
- **400 Bad Request:** Invalid input (missing fields, malformed data)
- **401 Unauthorized:** Missing or invalid JWT token
- **404 Not Found:** Joke/user not found
- **429 Too Many Requests:** Rate limit exceeded
- **500 Internal Server Error:** Server error (Claude API down, etc.)

All errors return consistent JSON:
```json
{
  "error": "error_code",
  "message": "Human-readable message",
  "statusCode": 400
}
```

### 3.4 Rate Limiting
- **Claude API:** 100 requests/minute (wrapped calls)
- **JokeAPI:** No limits (public API)
- **User endpoints:** 10 requests/second per user (prevent spam)

---

## 4. Frontend Architecture

### 4.1 Web (React/Next.js)

**Framework:** Next.js 14+ (App Router)

**Pages:**
- `/` — Home (request jokes)
- `/chat` — Conversational chat
- `/favorites` — Saved jokes
- `/login`, `/signup` — Authentication
- `/profile` — User settings

**Key components:**
- `JokeCard` — Display joke with Save button
- `ChatInput` — Text input + send
- `ChatMessage` — Display chat bubbles
- `FavoritesList` — Grid/list of saved jokes
- `AuthForm` — Login/signup form

**State management:** React Context + hooks (no Redux needed for MVP)

**Styling:** Tailwind CSS (utility-first, fast to build)

**Build:** `npm run build` → Static + API routes → Deploy to Vercel

### 4.2 Mobile (React Native)

**Framework:** React Native + Expo

**Screens:**
- Home — Request jokes
- Chat — Conversational chat
- Favorites — Saved jokes
- Profile — User settings + logout

**Shared logic:**
- API client (same fetch wrapper as web)
- State/Context (reuse from web)
- Type definitions (TypeScript)

**Platform-specific:**
- iOS: Built with Xcode, TestFlight beta
- Android: Built with Android Studio, Google Play Console

**Dev environment:** Expo Go (run on device or simulator)

### 4.3 Shared Code

```
/frontend
  /web (Next.js)
  /mobile (React Native)
  /shared
    - api-client.ts (fetch wrapper)
    - types.ts (TypeScript definitions)
    - hooks/ (useAuth, useJokes, useChat)
    - context/ (AuthContext, JokesContext)
```

---

## 5. Database Schema (Firestore)

### 5.1 Collections

**`users/{userId}`**
```json
{
  "email": "user@example.com",
  "name": "Paul",
  "username": "joke_lover",
  "createdAt": "2026-10-11T00:00:00Z",
  "updatedAt": "2026-10-11T00:00:00Z",
  "preferences": {
    "favoriteCategories": ["work", "relationships"],
    "notificationsEnabled": true
  }
}
```

**`jokes/{jokeId}`** (pre-loaded from JokeAPI)
```json
{
  "text": "Why did the employee get fired from the calendar factory?...",
  "category": "work",
  "type": "single|twopart",
  "createdAt": "2026-10-11T00:00:00Z",
  "rating": 4.5,
  "timesJoked": 42
}
```

**`favorites/{userId}/{jokeId}`**
```json
{
  "jokeId": "abc123",
  "text": "Why did the employee...",
  "category": "work",
  "savedAt": "2026-10-11T00:00:00Z"
}
```

**`conversations/{userId}/{conversationId}`**
```json
{
  "conversationId": "conv-xyz",
  "messages": [
    {
      "type": "user",
      "text": "Tell me a work joke",
      "timestamp": "2026-10-11T00:00:00Z"
    },
    {
      "type": "bot",
      "text": "Why did the employee...",
      "timestamp": "2026-10-11T00:00:05Z"
    }
  ],
  "createdAt": "2026-10-11T00:00:00Z",
  "updatedAt": "2026-10-11T00:00:05Z"
}
```

### 5.2 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Jokes are public read-only
    match /jokes/{jokeId} {
      allow read: if true;
      allow write: if false;
    }

    // Favorites are user-scoped
    match /favorites/{userId}/{jokeId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Conversations are user-scoped
    match /conversations/{userId}/{messageId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## 6. External Services

### 6.1 Joke Generation

**JokeAPI.dev** (Free)
- No authentication required
- Categories: general, programming, knock-knock, etc.
- Response: `{ id, text, type }` or `{ setup, delivery }`
- Rate limit: Generous (casual use)
- Cost: **$0**
- Fallback: Pre-load 50-100 jokes in Firestore if API is down

### 6.2 Conversational AI

**Phase 1: Claude API (with free trial credits)**
- Endpoint: `https://api.anthropic.com/v1/messages`
- Model: `claude-3-5-sonnet`
- Rate limit: 100 requests/minute (default)
- Prompt: Conversational jokes + follow-ups
- **Personalization:** System prompt includes user's name (e.g., "Paul") for natural conversation
- Cost: **$5 free credits** (initial, ~$0.003 per request)

**Phase 2: Self-hosted Ollama + Llama 2 (after credits exhaust)**
- Local or VPS-hosted open-source model
- No API costs, just infrastructure
- Trade-off: Response quality lower than Claude, but acceptable for jokes
- Hosting: DigitalOcean ($4/month) or Render (free tier with limits)
- **Personalization:** Bot addresses user by name in all responses
- Cost: **$0-5/month**

**Fallback:** Canned joke responses if both APIs unavailable

### 6.3 Firebase Services

**Authentication:**
- Email/password signup & login
- JWT tokens for API auth
- Cost: **$0** (free tier)

**Firestore Database:**
- 1GB storage (plenty for MVP)
- Real-time sync
- Automatic indexing
- Cost: **$0** (free tier: 50K reads/day)

**Cloud Functions:**
- Auto-scaling serverless backend
- Cost: **$0** (free tier: 125K invocations/month)

---

## 7. Authentication & Security

### 7.1 Flow

1. User signs up with email + password
2. Firebase Auth hashes password, creates user record
3. Auth service returns JWT token + `userId`
4. Frontend stores token in secure storage:
   - **Web:** localStorage (or secure cookie)
   - **Mobile:** Keychain (iOS) / Keystore (Android)
5. All API requests include `Authorization: Bearer <token>` header
6. Backend validates token on every request
7. Firestore rules enforce user data isolation

### 7.2 Token Management

- **Access token:** 1 hour validity
- **Refresh token:** 7 days validity
- On expiry: Frontend silently refreshes using refresh token
- On logout: Both tokens cleared, session ended

### 7.3 Data Privacy

- Passwords never sent in plaintext (HTTPS enforced)
- Conversation history scoped to user (Firestore rules)
- No personal data sold or shared
- Users can delete account + all data anytime

---

## 8. Deployment

### 8.1 Development

```bash
# Setup
git clone <repo>
cd adult-joke-bot
npm install
firebase init

# Local development
npm run dev          # Starts Next.js + Firebase emulator
# Test at http://localhost:3000
```

### 8.2 Web Deployment (Vercel)

1. Push code to GitHub
2. Connect repo to Vercel dashboard
3. Vercel auto-builds & deploys on each push
4. Environment variables: Firebase config, API keys
5. Cost: **$0** (free tier)

### 8.3 Mobile Deployment

**iOS:**
- Build with `eas build --platform ios` (Expo)
- Submit to TestFlight for beta testing
- Eventually: Apple App Store (requires $99/year developer account)

**Android:**
- Build with `eas build --platform android`
- Submit to Google Play Console (one-time $25 fee)

### 8.4 Backend (Firebase Cloud Functions)

```bash
firebase deploy --only functions
# Deploys to us-central1 by default
```

---

## 9. Scaling & Future

### 9.1 Current Limits (Free Tier)

| Resource | Limit | Notes |
|----------|-------|-------|
| Firestore reads/day | 50K | ~560 daily active users @ 10 reads/user |
| Cloud Functions | 125K invokes/month | ~4K invokes/day |
| Vercel bandwidth | 100GB/month | Plenty for MVP |

### 9.2 Scaling Path (If Popular)

1. Upgrade Firebase plan: $25/month (much higher limits)
2. Move Ollama to dedicated VPS: $5-10/month
3. Add CDN (Cloudflare free): $0 (free tier)
4. Total: ~$30-40/month at 10K+ users

### 9.3 Future Features (Post-MVP)

- Voice synthesis (upgrade to Elevenlabs after revenue)
- Voice input (speech-to-text)
- Social features (share jokes, follow comedians)
- Ratings & recommendations
- Admin panel to manage jokes
- Analytics (most-loved jokes, user stats)

---

## 10. Testing Strategy

### 10.1 Unit Tests
- API endpoints (request/response format)
- API error handling (invalid input, missing auth)
- Firestore queries (security rules)
- Frontend hooks (useAuth, useJokes)

### 10.2 Integration Tests
- End-to-end: Sign up → Request joke → Save → View favorites
- Chat: Send message → Get response → View history
- Auth: Login → Token refresh → Logout

### 10.3 Manual Testing
- Web browser (Chrome, Safari, Firefox)
- Mobile simulators (iOS Simulator, Android Emulator)
- Real devices before App Store submission

---

## 11. Success Metrics

- Users can sign up & login in <30 seconds
- Joke delivery <2 seconds (JokeAPI is fast)
- Chat response <5 seconds (Claude API latency)
- 95%+ API uptime
- Zero unhandled errors in production

---

## 12. Timeline (Estimate)

- **Week 1:** Backend setup (API endpoints, Firebase)
- **Week 2:** Frontend (web + mobile UI)
- **Week 3:** Integration + testing
- **Week 4:** Deploy to Vercel, TestFlight, Google Play
- **Week 5+:** Marketing, user feedback

---

## Appendix: File Structure

```
adult-joke-bot/
├── backend/
│   ├── functions/
│   │   ├── auth.js
│   │   ├── jokes.js
│   │   ├── chat.js
│   │   └── utils.js
│   ├── firestore.rules
│   └── firebase.json
├── frontend/
│   ├── web/
│   │   ├── pages/
│   │   ├── components/
│   │   └── styles/
│   ├── mobile/
│   │   ├── screens/
│   │   ├── components/
│   │   └── App.js
│   ├── shared/
│   │   ├── api-client.ts
│   │   ├── types.ts
│   │   ├── hooks/
│   │   └── context/
├── docs/
│   ├── API.md
│   ├── DEPLOYMENT.md
│   └── CONTRIBUTING.md
├── .env.example
└── README.md
```

---

**Design complete. Ready for implementation planning.**
