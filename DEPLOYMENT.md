# FinTrack Deployment Guide - Digital Ocean

This guide covers deploying FinTrack to a **$6/month Digital Ocean Droplet** with self-hosted PostgreSQL.

## Prerequisites

- Digital Ocean account
- Domain name (optional, but recommended)
- SSH access to your server

## Option 1: Docker Deployment (Recommended)

### 1. Create a Digital Ocean Droplet

```bash
# Create a $6/month droplet (1GB RAM, 1 vCPU, 25GB SSD)
# - Choose Ubuntu 22.04 LTS
# - Select the $6/month Basic plan
# - Choose a datacenter region close to you
# - Add your SSH key
```

### 2. Initial Server Setup

SSH into your droplet:

```bash
ssh root@your_droplet_ip
```

Update the system and install Docker:

```bash
# Update system
apt-get update && apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt-get install -y docker-compose

# Create a non-root user
adduser fintrack
usermod -aG sudo fintrack
usermod -aG docker fintrack

# Switch to the new user
su - fintrack
```

### 3. Set Up PostgreSQL

```bash
# Create a Docker network
docker network create fintrack-network

# Run PostgreSQL container
docker run -d \
  --name fintrack-db \
  --network fintrack-network \
  -e POSTGRES_PASSWORD=your_secure_password \
  -e POSTGRES_DB=fintrack_prod \
  -v fintrack-db-data:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:15-alpine

# Test connection
docker exec -it fintrack-db psql -U postgres -d fintrack_prod -c "SELECT version();"
```

### 4. Deploy the Application

On your local machine, build and push the Docker image:

```bash
# Build the Docker image
docker build -t fintrack:latest .

# Save the image to a tar file
docker save fintrack:latest | gzip > fintrack-latest.tar.gz

# Copy to your droplet
scp fintrack-latest.tar.gz fintrack@your_droplet_ip:~/
```

On your droplet:

```bash
# Load the image
docker load < fintrack-latest.tar.gz

# Create environment file
nano .env
```

Add your environment variables:

```env
# Database
DATABASE_URL=ecto://postgres:your_secure_password@fintrack-db/fintrack_prod
POSTGRES_PORT=5432

# Phoenix
SECRET_KEY_BASE=generate_with_mix_phx_gen_secret
PHX_HOST=your_domain.com
PORT=4000

# Client Information
CLIENT_NAME=Your Company Name
CLIENT_ADDRESS=Your Company Address
CLIENT_CITY_STATE_ZIP=City, State ZIP
CLIENT_EIN=Your-EIN-Number

# Bill To Information
BILL_TO_NAME=Your Name
BILL_TO_SWIFT_BIC=SWIFT-BIC-CODE
BILL_TO_ACCOUNT_NUMBER=Account-Number
BILL_TO_BANK_NAME=Bank Name
BILL_TO_BANK_ADDRESS=Bank Address
```

Generate a secret key base:

```bash
# On your local machine
mix phx.gen.secret
```

Run migrations and start the app:

```bash
# Run database migrations
docker run --rm \
  --network fintrack-network \
  --env-file .env \
  fintrack:latest /app/bin/migrate

# Start the application
docker run -d \
  --name fintrack-app \
  --network fintrack-network \
  --env-file .env \
  -p 4000:4000 \
  --restart unless-stopped \
  fintrack:latest

# Check logs
docker logs -f fintrack-app
```

### 5. Set Up Nginx Reverse Proxy

```bash
# Install Nginx
sudo apt-get install -y nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/fintrack
```

Add this configuration:

```nginx
upstream phoenix {
    server localhost:4000;
}

server {
    listen 80;
    server_name your_domain.com;

    location / {
        proxy_pass http://phoenix;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site and restart Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/fintrack /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 6. Set Up SSL with Let's Encrypt (Optional but Recommended)

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your_domain.com
```

## Option 2: Release Build Deployment (Without Docker)

### 1. Server Setup

```bash
# SSH into your droplet
ssh root@your_droplet_ip

# Update system
apt-get update && apt-get upgrade -y

# Install required packages
apt-get install -y \
  build-essential \
  git \
  postgresql \
  postgresql-contrib \
  nginx \
  curl \
  gnupg

# Install Erlang and Elixir
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
dpkg -i erlang-solutions_2.0_all.deb
apt-get update
apt-get install -y esl-erlang elixir

# Create application user
adduser --disabled-password --gecos "" fintrack
```

### 2. Set Up PostgreSQL

```bash
# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL console:
CREATE DATABASE fintrack_prod;
CREATE USER fintrack WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE fintrack_prod TO fintrack;
\q
```

### 3. Deploy Application

On your local machine:

```bash
# Build the release
MIX_ENV=prod mix deps.get
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release

# Create a tarball
cd _build/prod/rel/fintrack
tar czf fintrack.tar.gz .

# Copy to server
scp fintrack.tar.gz fintrack@your_droplet_ip:~/
```

On your server:

```bash
# Switch to fintrack user
su - fintrack

# Create app directory
mkdir -p ~/app
cd ~/app
tar xzf ~/fintrack.tar.gz

# Create .env file
nano .env
```

Add environment variables (same as Docker option above).

### 4. Set Up Systemd Service

```bash
# Copy the service file
sudo cp fintrack.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable fintrack
sudo systemctl start fintrack

# Check status
sudo systemctl status fintrack
```

### 5. Set Up Nginx (same as Docker option)

## Database Backups

Set up automated backups:

```bash
# Create backup script
sudo nano /usr/local/bin/backup-fintrack-db.sh
```

Add this script:

```bash
#!/bin/bash
BACKUP_DIR="/home/fintrack/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/fintrack_backup_$DATE.sql.gz"

mkdir -p $BACKUP_DIR

# For Docker
docker exec fintrack-db pg_dump -U postgres fintrack_prod | gzip > $BACKUP_FILE

# For local PostgreSQL
# pg_dump -U fintrack fintrack_prod | gzip > $BACKUP_FILE

# Keep only last 30 days
find $BACKUP_DIR -name "fintrack_backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_FILE"
```

Make it executable and set up cron:

```bash
sudo chmod +x /usr/local/bin/backup-fintrack-db.sh
sudo crontab -e
```

Add this line to run daily at 2 AM:

```
0 2 * * * /usr/local/bin/backup-fintrack-db.sh
```

## Updating the Application

### Docker Deployment

```bash
# Build new image locally
docker build -t fintrack:latest .
docker save fintrack:latest | gzip > fintrack-latest.tar.gz
scp fintrack-latest.tar.gz fintrack@your_droplet_ip:~/

# On server
docker load < fintrack-latest.tar.gz
docker stop fintrack-app
docker rm fintrack-app
docker run -d \
  --name fintrack-app \
  --network fintrack-network \
  --env-file .env \
  -p 4000:4000 \
  --restart unless-stopped \
  fintrack:latest
```

### Release Build Deployment

```bash
# Build and deploy new release
MIX_ENV=prod mix release
cd _build/prod/rel/fintrack
tar czf fintrack.tar.gz .
scp fintrack.tar.gz fintrack@your_droplet_ip:~/

# On server
sudo systemctl stop fintrack
cd ~/app
tar xzf ~/fintrack.tar.gz
sudo systemctl start fintrack
```

## Monitoring

Check application logs:

```bash
# Docker
docker logs -f fintrack-app

# Systemd
sudo journalctl -u fintrack -f
```

Check resource usage:

```bash
# Overall system
htop

# Docker containers
docker stats
```

## Troubleshooting

### Application won't start

```bash
# Check logs
docker logs fintrack-app
# or
sudo journalctl -u fintrack -n 100

# Check if database is accessible
docker exec -it fintrack-db psql -U postgres -d fintrack_prod
```

### Out of memory

The $6/month droplet has 1GB RAM. If you need more, upgrade to:
- $12/month (2GB RAM)
- $18/month (4GB RAM)

### Database connection issues

```bash
# Check PostgreSQL is running
docker ps | grep fintrack-db
# or
sudo systemctl status postgresql

# Test connection
docker exec -it fintrack-db psql -U postgres
```

## Cost Breakdown

- **Droplet**: $6/month (1GB RAM, 1 vCPU, 25GB SSD)
- **Backups** (optional): $1.20/month (20% of droplet cost)
- **Domain** (optional): ~$12/year (~$1/month)

**Total**: ~$6-8/month

## Security Recommendations

1. **Enable UFW Firewall**:
```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

2. **Change SSH Port** (optional):
```bash
sudo nano /etc/ssh/sshd_config
# Change Port 22 to Port 2222
sudo systemctl restart sshd
```

3. **Set up fail2ban**:
```bash
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

4. **Keep system updated**:
```bash
sudo apt-get update && sudo apt-get upgrade -y
```

5. **Use strong passwords** for database and environment variables

## Next Steps

- Set up monitoring (e.g., with UptimeRobot - free tier)
- Configure email sending with your preferred provider
- Set up off-site backups (e.g., to Backblaze B2 - free 10GB)
- Consider adding a CDN for static assets (CloudFlare - free tier)
