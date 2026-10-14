# Deployment Guide

## Backend (Firebase Cloud Functions)

```bash
cd backend/functions
npm install
firebase init
firebase deploy --only functions
```

Set environment variables in Firebase Console:
- CLAUDE_API_KEY (your Anthropic API key)
- OLLAMA_URL (optional, for self-hosted Ollama)

## Web (Next.js on Vercel)

1. Push code to GitHub
2. Connect to Vercel at vercel.com
3. Set environment variables in Vercel dashboard:
   - NEXT_PUBLIC_API_BASE_URL=https://your-project-functions.cloudfunctions.net/api
   - NEXT_PUBLIC_FIREBASE_API_KEY
   - NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN
   - NEXT_PUBLIC_FIREBASE_PROJECT_ID
4. Auto-deploys on push to main

## Mobile (React Native)

### iOS
```bash
cd frontend/mobile
eas build --platform ios
eas submit --platform ios
```

### Android
```bash
eas build --platform android
eas submit --platform android
```

## Costs Estimate

- **Development:** $0/month (free tier)
- **Production at 1K users:** ~$30-40/month
  - Firebase Firestore: $25/month (read/write overage)
  - Ollama VPS (DigitalOcean): $5-10/month
  - Vercel: free tier covers typical usage

## Monitoring

- Firebase Console: backend logs and metrics
- Vercel Analytics: web performance and usage
- Expo Dashboard: mobile app analytics

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Firebase auth fails | Check CORS settings in Firebase Console |
| Jokes not loading | Verify JokeAPI.dev status (v2.jokeapi.dev) |
| AI responses slow | Check Claude API rate limits and quota |
| Mobile won't install | Verify signing certificates and provisioning profiles |

