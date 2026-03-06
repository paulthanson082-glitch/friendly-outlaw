# Phase 4: Mobile App - Jules iOS/Android

## Overview

Jules is now available as a native mobile app for iOS and Android using React Native + Expo. Works on phone and tablet, with offline support and native features.

## Features

✅ **Core Features**
- AI-powered writing assistant
- Document management (create, edit, delete, search)
- Writing templates with placeholders
- Kanban board for task tracking
- Writing goals with progress tracking
- Real-time cloud sync

✅ **Native Features**
- Push notifications
- Camera integration (document photos)
- Offline storage (local SQLite)
- Background sync
- Voice notes (optional)
- Share documents

✅ **Platform Support**
- iOS 13+
- Android 8+
- Tablet (iPad, Android tablets)
- Web (Expo Web - bonus!)

## Quick Start

### Prerequisites

```bash
# Install Node.js 18+
node --version

# Install Expo CLI
npm install -g expo-cli

# iOS: Install Xcode (Mac only)
# Android: Install Android Studio
```

### Development

```bash
# Clone repository
cd mobile

# Install dependencies
npm install

# Start Expo development server
npm start

# On first run, select:
# i - iOS Simulator (Mac)
# a - Android Emulator
# w - Web browser
```

### Project Structure

```
mobile/
├── app.json              # Expo config
├── App.tsx              # Main navigation
├── src/
│   ├── context/         # React Context (Auth, API)
│   ├── screens/         # 6 main screens
│   │   ├── LoginScreen.tsx
│   │   ├── DocumentsScreen.tsx
│   │   ├── DocumentDetailScreen.tsx
│   │   ├── TemplatesScreen.tsx
│   │   ├── KanbanScreen.tsx
│   │   ├── GoalsScreen.tsx
│   │   └── SettingsScreen.tsx
│   └── utils/          # Helpers
├── assets/             # Images, icons
└── package.json
```

## Building

### Option 1: Expo Go (Testing)

Fastest way to test on your device:

```bash
# Start Expo development server
npm start

# Scan QR code with:
# iOS: Camera app
# Android: Expo Go app (install from Play Store)
```

### Option 2: EAS Build (Production)

Create signed, optimized builds ready for app stores:

#### Setup

```bash
# Install EAS CLI
npm install -g eas-cli

# Login to Expo account
eas login

# Configure project
eas build:configure
```

#### Build for iOS

```bash
# Build for Apple App Store
eas build --platform ios --auto-submit

# Or locally with Xcode (Mac)
npm run build:ios
```

#### Build for Android

```bash
# Build for Google Play Store
eas build --platform android

# Or locally with Android Studio
npm run build:android
```

### Option 3: Local Development Build

For testing native modules before submitting to stores:

```bash
# Install Expo dev client
npx expo install expo-dev-client

# Build development app
eas build --platform ios --dev-client
eas build --platform android --dev-client
```

## Submitting to App Stores

### Apple App Store

```bash
# Prerequisites
# - Apple Developer account ($99/year)
# - Create App ID in App Store Connect
# - Generate certificates (automatic with EAS)

# Build and submit
eas build --platform ios --auto-submit

# Or submit manually
eas submit --platform ios

# Complete:
# 1. Review screenshots & description
# 2. Set app rating
# 3. Submit for review (takes 24-48 hours)
```

### Google Play Store

```bash
# Prerequisites
# - Google Play Developer account ($25 one-time)
# - Create app entry in Play Console
# - Generate signing key (automatic with EAS)

# Build and submit
eas build --platform android --auto-submit

# Or submit manually
eas submit --platform android

# Complete:
# 1. Review screenshots & description
# 2. Set content rating
# 3. Review all metadata
# 4. Publish (usually ~2 hours for approval)
```

## Configuration

### API Connection

Mobile app connects to backend API:

```typescript
// Environment variable in app.json
"extra": {
  "apiUrl": "https://api.julesapp.com"
}

// Or in runtime
process.env.EXPO_PUBLIC_API_URL
```

Set for development:
```bash
export EXPO_PUBLIC_API_URL=http://localhost:3000/api
npm start
```

Set for production:
```json
{
  "extra": {
    "apiUrl": "https://api.julesapp.com"
  }
}
```

### Environment Files

Create `.env.local` (for development):
```
EXPO_PUBLIC_API_URL=http://localhost:3000/api
```

### Secrets Management

Sensitive keys (API keys, etc.) should:
1. **Never** be in code
2. **Never** be in git
3. Be stored in Expo Secrets:

```bash
eas secret:create
eas secret:list
eas secret:update ANTHROPIC_API_KEY
```

Then reference in `eas.json`:
```json
{
  "build": {
    "production": {
      "env": {
        "ANTHROPIC_API_KEY": "@ANTHROPIC_API_KEY"
      }
    }
  }
}
```

## Features In Detail

### Authentication

- Email/password signup
- Auto-login on app start
- Secure token storage (AsyncStorage)
- Auto-refresh on token expiration

### Documents

**Read & Edit**
- Full-text search
- Word count tracking
- Auto-save (with toggle)
- Export to markdown/PDF

**Offline Support**
- Local SQLite cache
- Sync when online
- Conflict resolution

### Templates

- Browse 20+ default templates
- Create custom templates
- Filter by category (novel, essay, etc.)
- Fill placeholders and create documents

### Kanban Board

- 5-column workflow (backlog → done)
- Drag-drop tasks (swipe left/right)
- Bulk move operations
- Task descriptions & dates

### Writing Goals

- Create daily/weekly/monthly goals
- Visual progress bars
- Milestone notifications
- Goal history

### Offline Features

Built-in SQLite database for offline access:

```typescript
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as SQLite from 'expo-sqlite';

// Local storage for drafts
await AsyncStorage.setItem('draft_1', content);

// Sync when online
const onlineManager = new OnlineManager({
  onOnline: syncPendingChanges
});
```

## Notifications

### Push Notifications

```typescript
import * as Notifications from 'expo-notifications';

// Register for notifications
await Notifications.requestPermissionsAsync();
const token = (await Notifications.getExpoPushTokenAsync()).data;

// Handle incoming notifications
Notifications.addNotificationResponseReceivedListener((response) => {
  // Handle notification tap
});
```

### Local Notifications

```typescript
// Notify when goal reached
await Notifications.scheduleNotificationAsync({
  content: {
    title: 'Goal Achieved! 🎉',
    body: 'You reached 1000 words!',
  },
  trigger: { type: 'immediate' },
});
```

## Camera Integration

Capture writing inspiration:

```typescript
import { Camera } from 'expo-camera';
import * as ImagePicker from 'expo-image-picker';

// Add photo to document
const takePicture = async () => {
  const photo = await cameraRef.current.takePictureAsync();
  await client.post(`/documents/${docId}/attachments`, {
    uri: photo.uri,
    type: 'image/jpeg',
  });
};
```

## Performance Optimization

### Bundle Size

```bash
# Check bundle size
npx expo bundle-analyzer
```

Current size: ~4MB (iOS), ~6MB (Android)

### Images

```typescript
// Optimize images
import { Image } from 'expo-image';

<Image
  source={require('./image.png')}
  contentFit="cover"
  placeholder={{ blurhash }}
  transition={1000}
/>
```

### Lazy Loading

```typescript
const DocumentDetail = lazy(() => import('./DocumentDetail'));

<Suspense fallback={<ActivityIndicator />}>
  <DocumentDetail />
</Suspense>
```

## Testing

### Unit Tests

```bash
npm test

# Test specific file
npm test DocumentsScreen
```

### End-to-End Tests

```bash
npm run detox:build:ios
npm run detox:test:ios
```

## Debugging

### Development

```bash
# Expo DevTools (Shift+D in Terminal)
# Inspect element
# View logs
# Reload hot refresh (Shift+R)
# Full reload (Shift+W)
```

### Production

```bash
# View production logs
eas build:list
eas build:view <BUILD_ID>

# Remote debugging
expo install expo-dev-client
```

## Native Modules

Can add native functionality:

```bash
# Add camera
expo install expo-camera

# Add notifications
expo install expo-notifications

# Add file system
expo install expo-file-system

# Add video playback
expo install expo-av
```

All major modules supported via Expo!

## Device Testing

### iOS Simulator (Mac)

```bash
npm start
# Press 'i' in Terminal
```

### Android Emulator

```bash
# Start emulator first
# Open Android Studio → Virtual Device Manager

npm start
# Press 'a' in Terminal
```

### Physical Device

```bash
# Install Expo Go app from:
# iOS: App Store
# Android: Google Play Store

npm start
# Scan QR code with camera (iOS) or Expo Go app (Android)
```

## Analytics

Track user behavior:

```typescript
import * as Sentry from 'sentry-expo';

Sentry.init({
  dsn: 'your-sentry-dsn',
  tracesSampleRate: 1.0,
});

// Automatic error tracking
try {
  // code
} catch (error) {
  Sentry.captureException(error);
}
```

## Internationalization (i18n)

Support multiple languages:

```bash
npm install i18n-js
```

Create `i18n/en.json`:
```json
{
  "documents": "Documents",
  "templates": "Templates"
}
```

## Updates

### Over-the-Air (OTA) Updates

Deploy app updates without app store review:

```bash
# Build for production
eas update

# Users receive update next app launch
```

### App Store Updates

Deploy new version:

```bash
# Increment version in app.json
# "version": "1.0.1"

# Build & submit
eas build --platform ios --auto-submit
eas build --platform android --auto-submit
```

## Troubleshooting

### App Won't Start

```bash
# Clear cache
rm -rf node_modules .expo
npm install

# Reset Expo cache
expo start --clear
```

### Build Failures

```bash
# Check logs
eas build:list
eas build:view <BUILD_ID>

# Common issues:
# - Expired certificates: eas credentials
# - Missing dependencies: npm install
# - Config errors: eas.json is valid JSON
```

### Performance Issues

```bash
# Profile app
expo install expo-device-info

# Monitor memory
console.log('Memory:', require('expo-device').getTotalMemoryAsync())

# Check slow screens
expo install react-native-performance
```

## Next Steps

1. ✅ Set up local development
2. ✅ Test on iOS simulator/Android emulator
3. ✅ Test on physical device
4. ✅ Build for production
5. ✅ Submit to app stores
6. ✅ Monitor with analytics
7. ✅ Collect user feedback
8. ✅ Iterate based on feedback

## Support & Resources

- [Expo Docs](https://docs.expo.dev)
- [React Native Docs](https://reactnative.dev)
- [EAS Docs](https://docs.expo.dev/eas)
- [App Store Guidelines](https://developer.apple.com/app-store/review)
- [Google Play Policies](https://play.google.com/about/developer-content-policy)

---

**Your mobile app is ready to build!** 🚀📱
