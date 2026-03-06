# Phase 3: Production Deployment Guide - Jules API

## Overview

This guide covers deploying Jules to production with Docker, CI/CD automation, and PWA support.

## Prerequisites

- Docker & Docker Compose
- Node.js 22+
- GitHub account with repository access
- Production server (AWS, Google Cloud, DigitalOcean, etc.)
- Anthropic API key
- Optional: PostgreSQL, Redis

## Local Development with Docker

### Build and run locally

```bash
# Copy environment template
cp backend/.env.example backend/.env
# Edit with your ANTHROPIC_API_KEY

# Build and start
docker-compose up --build

# Access
# API: http://localhost:3000
# Frontend: http://localhost:3000 (served from /public)
# Health: http://localhost:3000/health
```

### Stopping services

```bash
docker-compose down
```

## Production Deployment

### Option 1: AWS ECS (Recommended for beginners)

#### Step 1: Prepare Docker image

```bash
# Build image locally
docker build -t jules-api:latest .

# Tag for AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_ECR_URL>
docker tag jules-api:latest <YOUR_ECR_URL>/jules-api:latest
docker push <YOUR_ECR_URL>/jules-api:latest
```

#### Step 2: Create ECS task definition

```json
{
  "family": "jules-api",
  "taskRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "jules-api",
      "image": "YOUR_ECR_URL/jules-api:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "3000"
        }
      ],
      "secrets": [
        {
          "name": "ANTHROPIC_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:anthropic-api-key"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:jwt-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/jules-api",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
        "interval": 30,
        "timeout": 3,
        "retries": 3,
        "startPeriod": 5
      }
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "networkMode": "awsvpc",
  "cpu": "256",
  "memory": "512"
}
```

#### Step 3: Create ECS Service

```bash
aws ecs create-service \
  --cluster jules-prod \
  --service-name jules-api \
  --task-definition jules-api \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:region:account:targetgroup/julesapi/xxx,containerName=jules-api,containerPort=3000"
```

### Option 2: DigitalOcean App Platform

```yaml
# app.yaml
name: jules-api
services:
  - name: api
    github:
      repo: your-username/friendly-outlaw
      branch: main
    build_command: npm install && npm run build
    http_port: 3000
    health_check:
      http:
        path: /health
    env:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: "3000"
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
    build_command: cd frontend && npm install && npm run build
    source_dir: frontend/dist
```

Deploy via DigitalOcean CLI:

```bash
doctl apps create --spec app.yaml
```

### Option 3: Manual deployment with systemd

#### Step 1: SSH to server

```bash
ssh user@your-server.com
```

#### Step 2: Clone repository

```bash
cd /opt
git clone https://github.com/your-username/friendly-outlaw.git
cd friendly-outlaw
```

#### Step 3: Setup environment

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install dependencies
cd backend && npm ci --production
cd ../frontend && npm ci --production && npm run build
```

#### Step 4: Create systemd service

```bash
sudo tee /etc/systemd/system/jules-api.service > /dev/null <<EOF
[Unit]
Description=Jules API
After=network.target

[Service]
Type=simple
User=nodejs
WorkingDirectory=/opt/friendly-outlaw/backend
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

Environment="NODE_ENV=production"
Environment="PORT=3000"
EnvironmentFile=/opt/friendly-outlaw/backend/.env

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable jules-api
sudo systemctl start jules-api
```

#### Step 5: Setup Nginx reverse proxy

```bash
sudo apt-get install -y nginx

sudo tee /etc/nginx/sites-available/jules > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
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
}
EOF

sudo ln -s /etc/nginx/sites-available/jules /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### Step 6: SSL with Let's Encrypt

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## CI/CD with GitHub Actions

The `.github/workflows/ci.yml` file automatically:

1. **Tests** backend and frontend on every push
2. **Builds** Docker image on main branch
3. **Pushes** to Docker Registry
4. **Deploys** to production

### GitHub Secrets to configure

```
DOCKER_USERNAME: your-docker-username
DOCKER_PASSWORD: your-docker-password (or access token)
ANTHROPIC_API_KEY: your-anthropic-api-key
JWT_SECRET: your-jwt-secret
```

## Monitoring & Logging

### CloudWatch (AWS)

```bash
# View logs
aws logs tail /ecs/jules-api --follow

# Create alarms
aws cloudwatch put-metric-alarm \
  --alarm-name jules-api-cpu \
  --alarm-description "Alert when CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

### Log aggregation (optional)

- **Datadog**: Import logs from CloudWatch or Docker logs
- **Sentry**: Automatic error tracking
- **ELK Stack**: Self-hosted logging

## Scaling

### Horizontal scaling (multiple instances)

With AWS ECS:

```bash
aws ecs update-service \
  --cluster jules-prod \
  --service jules-api \
  --desired-count 3
```

### Database scaling (PostgreSQL)

```bash
# Enable read replicas
aws rds create-db-instance-read-replica \
  --db-instance-identifier jules-read-1 \
  --source-db-instance-identifier jules-primary
```

### Caching with Redis

```bash
# Update docker-compose to enable Redis
# Add connection pool and cache middleware to Express
```

## Security Hardening

### Environment

```bash
# Generate strong secrets
openssl rand -base64 32  # For JWT_SECRET
openssl rand -base64 16  # For database passwords
```

### Network

- Enable VPC with private subnets
- Use security groups to restrict traffic
- Enable WAF on load balancer

### Application

- Keep dependencies updated: `npm audit fix`
- Use HTTPS only (enforce in Nginx)
- Set security headers:

```nginx
add_header Strict-Transport-Security "max-age=31536000" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
```

### Database

- Enable encryption at rest
- Regular automated backups
- Use parameterized queries (already done)

## Rollback procedures

### Docker rollback

```bash
# List image versions
docker images | grep jules-api

# Rollback to previous version
docker service update --image jules-api:previous-sha jules-api
```

### Git rollback

```bash
git revert <commit-hash>
git push
# GitHub Actions will automatically deploy
```

## Performance optimization

### Database indexing

Already implemented in `schema.sql` (40+ indexes)

### Caching strategy

```typescript
// Redis cache example
const cacheKey = `docs:${userId}`;
const cached = await redis.get(cacheKey);
if (cached) return JSON.parse(cached);

const documents = await documentService.getUserDocuments(userId);
await redis.setex(cacheKey, 3600, JSON.stringify(documents));
return documents;
```

### CDN for static files

- Upload frontend/dist to CloudFront or similar
- Serve from CDN instead of server

## Cost optimization

- Use Spot instances (AWS) for non-critical workloads
- Enable auto-scaling based on CPU/memory
- Archive old data to S3
- Use cheaper regions for non-critical services

## Troubleshooting

### High CPU usage

```bash
# Check running processes
docker top container-id

# Monitor in real-time
docker stats

# Scale up
docker-compose up --scale api=3
```

### Database connection errors

```bash
# Check connection pool
# Increase MAX_CONNECTIONS in database
# Monitor with: SELECT count(*) FROM pg_stat_activity;
```

### Out of memory

```bash
# Increase container memory in docker-compose
# Enable swap
# Profile with: node --prof app.js && node --prof-process app.js
```

## Next steps

1. Set up monitoring & alerting
2. Configure automated backups
3. Implement CDN for static assets
4. Set up log aggregation
5. Create runbooks for common issues
6. Document your specific infrastructure

## Support

For deployment issues, check:
- Docker logs: `docker logs container-id`
- Application logs: `/var/log/syslog` or CloudWatch
- GitHub Actions: Push to see build logs

---

**Ready to deploy!** 🚀
