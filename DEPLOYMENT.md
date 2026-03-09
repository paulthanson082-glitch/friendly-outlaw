# Jules Complete Deployment Guide

Master deployment guide for all components of Jules: backend API, web frontend, and mobile apps.

## 📋 Quick Start

### Deploy Everything (Quick)

```bash
# 1. Setup
cd friendly-outlaw
cp backend/.env.example backend/.env
# Edit backend/.env with ANTHROPIC_API_KEY and JWT_SECRET

# 2. Local testing
docker-compose up --build
# Visit http://localhost:3000

# 3. Production
./deploy.sh  # Interactive script handles all options
```

---

## 📦 What We're Deploying

| Component | Type | Version |
|-----------|------|---------|
| **Backend API** | Express + TypeScript | Node 22+ |
| **Frontend Web** | React + Vite | React 18 |
| **Mobile App** | React Native + Expo | iOS 13+, Android 8+ |

---

## 🎯 Deployment Checklist

Before deploying to production:

- [ ] Environment variables configured
- [ ] JWT_SECRET changed (never default)
- [ ] ANTHROPIC_API_KEY set (or feature disabled)
- [ ] Database backups enabled
- [ ] SSL/HTTPS configured
- [ ] Security headers set
- [ ] Rate limiting enabled
- [ ] Error logging configured
- [ ] Monitoring/alerts set up
- [ ] Rollback procedure tested

---

## 🚀 Option 1: Docker Development (Recommended for Testing)

Quick local deployment with everything pre-configured.

### Prerequisites

```bash
docker --version  # 20.10+
docker-compose --version  # 2.0+
```

### Quick Start

```bash
# Navigate to project root
cd friendly-outlaw

# Copy and configure environment
cp backend/.env.example backend/.env
# Edit backend/.env with your keys

# Start all services
docker-compose up --build

# Test
curl http://localhost:3000/health
# Visit http://localhost:3000 in browser
```

### Access Points

- **API**: http://localhost:3000
- **Frontend**: http://localhost:3000 (served from /public)
- **Health check**: http://localhost:3000/health

### Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api
docker-compose logs -f frontend
```

### Cleanup

```bash
# Stop services
docker-compose down

# Remove everything (careful!)
docker-compose down -v  # Removes volumes too
```

---

## 🌐 Option 2: AWS ECS (Production, Scalable)

Recommended for production with auto-scaling and load balancing.

### Prerequisites

- AWS account
- ECR repository created
- ECS cluster created
- Load balancer configured
- AWS CLI installed

### Step 1: Build and push Docker image

```bash
# Build
docker build -t jules-api:latest .

# Tag for ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ECR_URL>

docker tag jules-api:latest <ECR_URL>/jules-api:latest

# Push
docker push <ECR_URL>/jules-api:latest
```

### Step 2: Create ECS task definition

```bash
# Update and create
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json
```

See `PHASE3_DEPLOYMENT.md` for full `ecs-task-definition.json` template.

### Step 3: Create ECS service

```bash
aws ecs create-service \
  --cluster jules-prod \
  --service-name jules-api \
  --task-definition jules-api \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:...,containerName=jules-api,containerPort=3000"
```

### Step 4: Setup auto-scaling

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/jules-prod/jules-api \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10

# Create scaling policy
aws application-autoscaling put-scaling-policy \
  --policy-name scale-on-cpu \
  --service-namespace ecs \
  --resource-id service/jules-prod/jules-api \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration "TargetValue=70.0,PredefinedMetricSpecification={PredefinedMetricType=ECSServiceAverageCPUUtilization}"
```

### Monitoring

```bash
# View logs
aws logs tail /ecs/jules-api --follow

# View service status
aws ecs describe-services \
  --cluster jules-prod \
  --services jules-api
```

---

## 🌊 Option 3: DigitalOcean App Platform (Simple)

Easiest production deployment with GitHub integration.

### Step 1: Prepare app.yaml

```yaml
# app.yaml
name: jules
services:
  - name: api
    github:
      repo: your-username/friendly-outlaw
      branch: main
    build_command: cd backend && npm ci && npm run build
    http_port: 3000
    health_check:
      http:
        path: /health
    env:
      - key: NODE_ENV
        value: production
    envs:
      - key: ANTHROPIC_API_KEY
        value: ${ANTHROPIC_API_KEY}
      - key: JWT_SECRET
        value: ${JWT_SECRET}

static_sites:
  - name: frontend
    github:
      repo: your-username/friendly-outlaw
      branch: main
    build_command: cd frontend && npm ci && npm run build
    source_dir: frontend/dist
```

### Step 2: Deploy

```bash
# Install doctl
brew install doctl  # or download from https://github.com/digitalocean/doctl

# Authenticate
doctl auth init

# Create app
doctl apps create --spec app.yaml

# View status
doctl apps list
doctl apps get <app-id>

# View logs
doctl apps logs <app-id>
```

### Step 3: Set environment variables

Via DigitalOcean console:
1. Go to Apps > Your App > Settings
2. Add environment variables: `ANTHROPIC_API_KEY`, `JWT_SECRET`
3. Redeploy

---

## 🖥️ Option 4: Manual VPS Deployment (Linux)

Deploy to any Linux server with systemd.

### Prerequisites

- Ubuntu 22.04 LTS server
- SSH access
- Domain with DNS pointing to server
- 2GB RAM minimum (4GB recommended)

### Step 1: SSH to server

```bash
ssh user@your-server.com
```

### Step 2: Install dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Nginx
sudo apt-get install -y nginx

# Install Certbot (SSL)
sudo apt-get install -y certbot python3-certbot-nginx
```

### Step 3: Clone and setup

```bash
# Clone repository
cd /opt
sudo git clone https://github.com/your-username/friendly-outlaw.git
sudo chown -R $USER:$USER friendly-outlaw

# Setup backend
cd friendly-outlaw/backend
npm ci --production

# Build frontend
cd ../frontend
npm ci --production
npm run build

# Go back
cd /opt/friendly-outlaw
```

### Step 4: Create environment file

```bash
# Create .env in /opt/friendly-outlaw/backend
cat > backend/.env <<EOF
NODE_ENV=production
PORT=3000
DATABASE_URL=sqlite://./data/app.db
ANTHROPIC_API_KEY=sk-ant-xxxx
JWT_SECRET=your-secret-here-32-chars-min
EOF

chmod 600 backend/.env
```

### Step 5: Create systemd service

```bash
# Create service file
sudo tee /etc/systemd/system/jules-api.service > /dev/null <<EOF
[Unit]
Description=Jules API
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/friendly-outlaw/backend
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

EnvironmentFile=/opt/friendly-outlaw/backend/.env

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable jules-api
sudo systemctl start jules-api

# Check status
sudo systemctl status jules-api
```

### Step 6: Setup Nginx reverse proxy

```bash
# Create config
sudo tee /etc/nginx/sites-available/jules > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    # Serve static frontend
    location / {
        root /opt/friendly-outlaw/frontend/dist;
        try_files \$uri /index.html;
    }

    # Proxy API requests
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Proxy health check
    location /health {
        proxy_pass http://localhost:3000;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/jules /etc/nginx/sites-enabled/

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### Step 7: Setup SSL with Let's Encrypt

```bash
# Get SSL certificate (automatic Nginx config)
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Auto-renew
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Test renewal
sudo certbot renew --dry-run
```

### Step 8: Security hardening

```bash
# Add security headers
sudo tee /etc/nginx/snippets/security-headers.conf > /dev/null <<EOF
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
EOF

# Update Nginx config to include it
sudo nano /etc/nginx/sites-available/jules
# Add: include /etc/nginx/snippets/security-headers.conf;

# Reload
sudo systemctl reload nginx
```

### Monitoring

```bash
# Service logs
sudo journalctl -u jules-api -f

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# System resources
watch -n 1 'free -h; echo; ps aux | grep node'
```

---

## 📱 Mobile App Deployment

### Prerequisites

- Expo account (free)
- Apple Developer account ($99/year) - for iOS
- Google Play Developer account ($25 one-time) - for Android
- EAS CLI installed

### Quick Start

```bash
cd mobile

# Install dependencies
npm install

# Login to Expo
expo login

# Start development
npm start  # Press i for iOS, a for Android, w for web

# Build for production
npm run build:all

# Submit to stores
npm run submit:ios
npm run submit:android
```

### Detailed Instructions

See `PHASE4_MOBILE.md` for:
- Setting up app store accounts
- Creating certificates
- Building for iOS and Android
- Submitting to App Store Connect
- Submitting to Google Play Console
- Managing app updates

---

## 🔄 CI/CD with GitHub Actions

Automatically build and deploy on every push.

### GitHub Secrets to configure

Go to Settings > Secrets and add:

```
ANTHROPIC_API_KEY: your-anthropic-key
JWT_SECRET: your-jwt-secret
DOCKER_USERNAME: your-docker-username
DOCKER_PASSWORD: your-docker-password
AWS_REGION: us-east-1 (if using AWS)
AWS_ACCOUNT_ID: your-account-id (if using AWS)
DIGITALOCEAN_TOKEN: your-do-token (if using DigitalOcean)
```

The `.github/workflows/ci.yml` file will:
1. Run tests on every push
2. Build Docker image for main branch
3. Push to Docker Hub/ECR
4. Deploy to production (if configured)

---

## 📊 Monitoring & Logging

### Local development

```bash
docker-compose logs -f  # All services
docker-compose logs -f api  # Just API
```

### Production AWS

```bash
# CloudWatch logs
aws logs tail /ecs/jules-api --follow

# Metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=jules-api \
  --statistics Average \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600
```

### Production DigitalOcean

```bash
doctl apps logs <app-id> --follow
```

### Production VPS

```bash
# Application logs
sudo journalctl -u jules-api -f

# System logs
tail -f /var/log/syslog

# Error logs
sudo tail -f /var/log/nginx/error.log
```

---

## 🔐 Security Best Practices

### Secrets Management

```bash
# Never commit .env files
git add .gitignore  # Ensure .env is listed

# Use strong secrets
openssl rand -base64 32  # For JWT_SECRET
openssl rand -base64 16  # For database passwords

# Rotate secrets regularly
# Update in .env, restart service
```

### Database Security

```sql
-- Enable encryption (if using PostgreSQL)
ALTER SYSTEM SET ssl = on;

-- Create backups
pg_dump -h localhost -U user dbname > backup.sql
```

### Network Security

```bash
# Only allow HTTPS in Nginx
add_header Strict-Transport-Security "max-age=31536000" always;

# Add firewall rules
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 80/tcp  # HTTP
sudo ufw allow 443/tcp # HTTPS
sudo ufw enable
```

---

## 📈 Scaling

### Horizontal Scaling (Multiple Instances)

**Docker Compose:**
```bash
docker-compose up --scale api=3
```

**AWS ECS:**
```bash
aws ecs update-service \
  --cluster jules-prod \
  --service jules-api \
  --desired-count 5
```

### Vertical Scaling (Bigger Instances)

**AWS:**
- Update ECS task CPU/memory in task definition
- Update instance type in auto-scaling group

**DigitalOcean:**
- Change app size in Settings

**VPS:**
- Upgrade server specs with provider

### Database Scaling

```bash
# Add read replicas
aws rds create-db-instance-read-replica \
  --db-instance-identifier jules-read-1 \
  --source-db-instance-identifier jules-primary

# Update connection string in API
# DATABASE_URL=postgresql://user:pass@read-replica-url/db
```

---

## 🆘 Troubleshooting

### High CPU Usage

```bash
# Docker
docker stats  # Real-time monitoring

# AWS CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=jules-api

# VPS
top -p $(pgrep -f "node dist")
```

**Solutions:**
- Scale up (add more instances)
- Optimize slow queries
- Add caching (Redis)
- Review logs for errors

### Out of Memory

```bash
# Increase container memory
docker-compose.yml: mem_limit: 2gb

# Check memory usage
docker stats
ps aux | grep node
```

### Database Connection Errors

```bash
# Check connections
sqlite3 data/app.db "SELECT COUNT(*) FROM sqlite_master;"

# Restart service
docker-compose restart api
# or
sudo systemctl restart jules-api
```

### Deployment Failures

```bash
# Check recent logs
docker logs container-name
journalctl -u jules-api -n 50

# Rollback
git revert <commit-hash>
git push  # GitHub Actions will redeploy
```

---

## 🔄 Zero-Downtime Deployments

### Blue-Green Deployment

```bash
# Deploy new version to "green" environment
docker-compose -f docker-compose.green.yml up -d

# Test green environment
curl http://localhost:3001/health

# Switch traffic (update Nginx/load balancer)
# Point traffic to green

# Keep blue as fallback
```

### Rolling Updates

```bash
# AWS ECS (automatic)
# Service gradually replaces old tasks with new ones

# Manual
docker-compose up -d --scale api=3
# Deploy new version to 1 instance at a time
```

---

## 📝 Deployment Checklist

### Pre-deployment

- [ ] All tests pass locally
- [ ] Environment variables configured
- [ ] Database migrations complete
- [ ] Static assets optimized
- [ ] SSL certificate valid
- [ ] Backups created
- [ ] Monitoring enabled

### Deployment

- [ ] Code pushed to repository
- [ ] CI/CD pipeline succeeded
- [ ] Health checks passing
- [ ] Performance metrics normal
- [ ] Error logs clean

### Post-deployment

- [ ] Users can access application
- [ ] All features working
- [ ] API responding correctly
- [ ] Database queries fast
- [ ] No error spikes
- [ ] Monitor for 1 hour

---

## 📞 Support & Resources

- **Backend Deployment**: See `PHASE3_DEPLOYMENT.md`
- **Mobile Deployment**: See `PHASE4_MOBILE.md`
- **Project Standards**: See `CLAUDE.md`
- **Getting Started**: See `README.md`

### Helpful Commands

```bash
# Docker
docker --version
docker ps
docker logs container-id
docker exec -it container-id /bin/sh

# Node.js
node --version
npm --version
npm audit  # Check vulnerabilities

# Git
git status
git log --oneline
git revert <commit>

# System
uptime  # Server uptime
du -sh  # Disk usage
free -h  # Memory usage
```

---

**Ready to deploy Jules to production!** 🚀

Questions? Check the phase-specific guides or community documentation.
