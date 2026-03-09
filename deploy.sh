#!/bin/bash
set -e

# Jules Complete Deployment Script
# Deploys backend, frontend, and optionally mobile to production

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
NC='\033[0m' # No Color

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
print_header "PRE-FLIGHT CHECKS"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker not installed"
    exit 1
fi
print_success "Docker found"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose not installed"
    exit 1
fi
print_success "Docker Compose found"

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js not installed"
    exit 1
fi
print_success "Node.js $(node -v) found"

# Check environment variables
print_header "ENVIRONMENT VERIFICATION"

if [ ! -f backend/.env ]; then
    print_error "backend/.env not found"
    echo "Create it from backend/.env.example"
    exit 1
fi
print_success "backend/.env exists"

# Check for required keys
if ! grep -q "ANTHROPIC_API_KEY" backend/.env; then
    print_error "ANTHROPIC_API_KEY not found in backend/.env"
    exit 1
fi
print_success "ANTHROPIC_API_KEY configured"

if ! grep -q "JWT_SECRET" backend/.env; then
    print_error "JWT_SECRET not found in backend/.env"
    exit 1
fi
print_success "JWT_SECRET configured"

# Build options
print_header "DEPLOYMENT OPTIONS"
echo "1. Local development (docker-compose)"
echo "2. Production build (Docker image only)"
echo "3. Build for AWS ECS"
echo "4. Build for DigitalOcean"
echo "5. Build for manual deployment"
echo "6. Build all (prepare for all options)"

read -p "Choose option (1-6): " DEPLOY_OPTION

# Backend build
print_header "BUILDING BACKEND"

if [ ! -d "backend/node_modules" ]; then
    print_warning "Installing backend dependencies..."
    cd backend
    npm ci
    cd ..
fi

cd backend
print_warning "Building backend..."
npm run build
print_success "Backend build complete"
cd ..

# Frontend build
print_header "BUILDING FRONTEND"

if [ ! -d "frontend/node_modules" ]; then
    print_warning "Installing frontend dependencies..."
    cd frontend
    npm ci
    cd ..
fi

cd frontend
print_warning "Building frontend..."
npm run build
print_success "Frontend build complete"
cd ..

# Option-specific deployment
case $DEPLOY_OPTION in
    1)
        # Local development
        print_header "STARTING LOCAL DEVELOPMENT"
        print_warning "Starting Docker services..."
        docker-compose up --build
        ;;
    2)
        # Production build
        print_header "BUILDING PRODUCTION DOCKER IMAGE"
        docker build -t jules-api:latest .
        docker tag jules-api:latest jules-api:$(git rev-parse --short HEAD)
        print_success "Docker image built:"
        docker images | grep jules-api
        ;;
    3)
        # AWS ECS
        print_header "PREPARING FOR AWS ECS"
        print_warning "AWS ECR URL: "
        read ECR_URL
        docker build -t jules-api:latest .
        docker tag jules-api:latest $ECR_URL/jules-api:latest
        print_success "Image tagged for ECR: $ECR_URL/jules-api:latest"
        echo ""
        echo "Next steps:"
        echo "1. Configure AWS credentials: aws configure"
        echo "2. Login to ECR: aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL"
        echo "3. Push image: docker push $ECR_URL/jules-api:latest"
        echo "4. Update ECS task definition with: $ECR_URL/jules-api:latest"
        ;;
    4)
        # DigitalOcean
        print_header "PREPARING FOR DIGITALOCEAN"
        docker build -t jules-api:latest .
        print_success "Docker image built for DigitalOcean App Platform"
        echo ""
        echo "Next steps:"
        echo "1. Commit and push: git add . && git commit -m 'Deploy to DigitalOcean'"
        echo "2. Update app.yaml with your GitHub repo"
        echo "3. Deploy: doctl apps create --spec app.yaml"
        ;;
    5)
        # Manual deployment
        print_header "PREPARING FOR MANUAL DEPLOYMENT"
        docker build -t jules-api:latest .
        print_success "Docker image built for manual deployment"
        echo ""
        echo "Next steps:"
        echo "1. Save Docker image: docker save jules-api:latest | gzip > jules-api.tar.gz"
        echo "2. Copy to server: scp jules-api.tar.gz user@server:/tmp/"
        echo "3. SSH to server and run: docker load < /tmp/jules-api.tar.gz"
        echo "4. Start container: docker run -d -p 3000:3000 --env-file .env jules-api:latest"
        ;;
    6)
        # Build all
        print_header "BUILDING ALL OPTIONS"
        docker build -t jules-api:latest .
        docker tag jules-api:latest jules-api:$(git rev-parse --short HEAD)
        print_success "All builds complete!"
        docker images | grep jules-api
        ;;
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

print_header "DEPLOYMENT PREPARATION COMPLETE"
echo ""
print_success "Backend and frontend are ready for deployment"
echo ""
echo "For detailed deployment instructions, see:"
echo "  - PHASE3_DEPLOYMENT.md (backend & infrastructure)"
echo "  - PHASE4_MOBILE.md (mobile app deployment)"
echo ""
