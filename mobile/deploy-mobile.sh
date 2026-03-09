#!/bin/bash
set -e

# Jules Mobile App Deployment Script
# Deploys iOS and Android apps to app stores

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "${COLOR_BLUE}===================================${NC}"
    echo -e "${COLOR_BLUE}$1${NC}"
    echo -e "${COLOR_BLUE}===================================${NC}"
}

print_success() {
    echo -e "${COLOR_GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${COLOR_RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${COLOR_YELLOW}⚠ $1${NC}"
}

# Pre-flight checks
print_header "MOBILE DEPLOYMENT - PRE-FLIGHT CHECKS"

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js not installed"
    exit 1
fi
print_success "Node.js $(node -v) found"

# Check Expo CLI
if ! command -v expo &> /dev/null; then
    print_warning "Expo CLI not installed. Installing..."
    npm install -g expo-cli
fi
print_success "Expo CLI found"

# Check EAS CLI
if ! command -v eas &> /dev/null; then
    print_warning "EAS CLI not installed. Installing..."
    npm install -g eas-cli
fi
print_success "EAS CLI found"

# Check dependencies
print_header "CHECKING DEPENDENCIES"

if [ ! -d "node_modules" ]; then
    print_warning "Installing dependencies..."
    npm ci
fi
print_success "Dependencies installed"

# Deployment options
print_header "DEPLOYMENT OPTIONS"
echo "1. Development build (Expo Go)"
echo "2. Test build (iOS simulator/Android emulator)"
echo "3. Production build (App Store & Play Store)"
echo "4. Build iOS only"
echo "5. Build Android only"
echo "6. Submit to app stores"

read -p "Choose option (1-6): " DEPLOY_OPTION

case $DEPLOY_OPTION in
    1)
        # Development
        print_header "STARTING DEVELOPMENT BUILD"
        print_warning "This will start the Expo development server"
        echo ""
        echo "Choose platform:"
        echo "i = iOS Simulator (Mac only)"
        echo "a = Android Emulator"
        echo "w = Web browser"
        echo "Press Ctrl+C to stop"
        echo ""
        npm start
        ;;
    2)
        # Test build
        print_header "BUILDING TEST VERSION"
        read -p "Platform (ios/android): " PLATFORM

        if [ "$PLATFORM" = "ios" ]; then
            print_warning "Building for iOS simulator..."
            eas build --platform ios --dev-client
        elif [ "$PLATFORM" = "android" ]; then
            print_warning "Building for Android emulator..."
            eas build --platform android --dev-client
        else
            print_error "Invalid platform"
            exit 1
        fi
        ;;
    3)
        # Production
        print_header "BUILDING PRODUCTION VERSION"

        # Verify configuration
        if [ ! -f "app.json" ]; then
            print_error "app.json not found"
            exit 1
        fi

        # Check version
        print_warning "Current version in app.json:"
        grep '"version"' app.json
        read -p "Increment version? (y/n): " INCREMENT

        if [ "$INCREMENT" = "y" ]; then
            read -p "New version (e.g., 1.0.1): " NEW_VERSION
            # Update version in app.json
            sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" app.json
            print_success "Version updated to $NEW_VERSION"
        fi

        # Build both platforms
        print_warning "Building for iOS and Android..."
        eas build --platform all
        ;;
    4)
        # iOS only
        print_header "BUILDING iOS APP"
        read -p "Production build? (y/n): " IS_PROD

        if [ "$IS_PROD" = "y" ]; then
            eas build --platform ios
        else
            eas build --platform ios --dev-client
        fi
        ;;
    5)
        # Android only
        print_header "BUILDING ANDROID APP"
        read -p "Production build? (y/n): " IS_PROD

        if [ "$IS_PROD" = "y" ]; then
            eas build --platform android
        else
            eas build --platform android --dev-client
        fi
        ;;
    6)
        # Submit
        print_header "SUBMITTING TO APP STORES"

        echo "Submit to:"
        echo "1. iOS App Store only"
        echo "2. Google Play Store only"
        echo "3. Both stores"

        read -p "Choose (1-3): " SUBMIT_OPTION

        if [ "$SUBMIT_OPTION" = "1" ] || [ "$SUBMIT_OPTION" = "3" ]; then
            print_warning "Submitting to iOS App Store..."
            eas submit --platform ios
            print_success "iOS submission complete"
        fi

        if [ "$SUBMIT_OPTION" = "2" ] || [ "$SUBMIT_OPTION" = "3" ]; then
            print_warning "Submitting to Google Play Store..."
            eas submit --platform android
            print_success "Android submission complete"
        fi
        ;;
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

print_header "MOBILE DEPLOYMENT COMPLETE"
echo ""
print_success "Build/deploy initiated"
echo ""
echo "For more information, see PHASE4_MOBILE.md"
echo ""
