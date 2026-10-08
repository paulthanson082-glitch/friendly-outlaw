# Android PCD Commands & Secrets Guide

## Bengal Max - Android Development Setup

### Prerequisites
- Android SDK 30+
- Gradle 7.0+
- Java 11+
- Bengal Max device or emulator

### Essential Commands

#### Build
```bash
./gradlew build                    # Full build
./gradlew assembleDebug            # Debug APK
./gradlew assembleRelease          # Release APK
./gradlew bundleRelease            # App Bundle
```

#### Testing
```bash
./gradlew test                     # Unit tests
./gradlew connectedAndroidTest     # Instrumented tests
./gradlew testDebug                # Debug tests
```

#### Device Management
```bash
adb devices                        # List connected devices
adb shell                          # Open device shell
adb push <local> <device>          # Push files
adb pull <device> <local>          # Pull files
adb logcat                         # View device logs
```

### Secrets Management

#### Environment Variables
Never commit secrets. Use environment variables:

```bash
export ANTHROPIC_API_KEY="<your-key>"
export FIREBASE_PROJECT_ID="<project-id>"
export SIGNING_KEY_PASSWORD="<password>"
```

#### Keystore Setup
```bash
# Create keystore
keytool -genkey -v -keystore app.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias app-key

# Reference in gradle.properties (never commit)
KEYSTORE_FILE=app.keystore
KEYSTORE_PASSWORD=<password>
KEY_ALIAS=app-key
KEY_PASSWORD=<password>
```

### PCD (Platform-Specific Development) Tips

1. **Use environment-specific flavors:**
   ```groovy
   flavorDimensions "environment"
   productFlavors {
       dev { dimension "environment" }
       prod { dimension "environment" }
   }
   ```

2. **Separate secrets by build type:**
   - Debug: Use hardcoded test values in debug resources
   - Release: Load from secure storage

3. **CI/CD Integration:**
   - Never store secrets in version control
   - Use GitHub Secrets for CI pipelines
   - Reference via environment variables

### Troubleshooting

**Gradle sync failing:**
```bash
./gradlew clean
./gradlew sync
```

**Device not recognized:**
```bash
adb kill-server
adb start-server
adb devices
```

**Build signing issues:**
- Verify keystore path in gradle.properties
- Confirm key alias and password
- Check signing configuration in build.gradle

### Resources
- [Android Developer Guide](https://developer.android.com/docs)
- [Firebase Console](https://console.firebase.google.com)
- [Gradle Documentation](https://gradle.org/learn-gradle)
