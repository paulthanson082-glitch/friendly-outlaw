# API Documentation

**Base URL:** `https://your-project-functions.cloudfunctions.net/api`

All authenticated endpoints require: `Authorization: Bearer <jwt_token>`

## Authentication

### POST /auth/signup
Create new account.

```json
{
  "email": "paul@example.com",
  "password": "secure123",
  "name": "Paul"
}
```

Response: `{ userId, token, expiresIn: 3600 }`

### POST /auth/login
Login to existing account.

```json
{
  "email": "paul@example.com",
  "password": "secure123"
}
```

Response: `{ userId, token, expiresIn: 3600 }`

### POST /auth/logout
Logout (client-side token deletion).

## Jokes

### GET /jokes/random?category=work
Get random joke by category.

Categories: `general`, `work`, `relationships`, `programming`

Response: `{ text, category, source }`

### POST /jokes/request
Request joke by topic.

```json
{
  "topic": "work"
}
```

Response: `{ text, category, source }`

### POST /jokes/favorites
Save or unsave joke.

```json
{
  "jokeId": "joke-123",
  "jokeText": "Why did...",
  "category": "work",
  "action": "save|unsave"
}
```

Response: `{ isFavorited: boolean }`

### GET /jokes/my-favorites
Get user's saved jokes.

Response: `[{ jokeId, text, category, savedAt }]`

## Chat

### POST /chat
Send message, get AI response (personalized with user name).

```json
{
  "message": "Tell me more!",
  "conversationId": "optional-conv-id"
}
```

Response: `{ reply, conversationId }`

### GET /chat/history?limit=50
Get conversation history.

Response: `[{ type: "user|bot", text, timestamp }]`

## Error Format

```json
{
  "error": "error_code",
  "message": "Human-readable message",
  "statusCode": 400
}
```

Common errors:
- `unauthorized` (401): Missing or invalid token
- `invalid_request` (400): Missing required fields
- `internal_error` (500): Server error

