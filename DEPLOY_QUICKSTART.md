# FinTrack - Quick Deploy to Digital Ocean ($6/month)

## TL;DR - Fastest Path to Production

### 1. Create Droplet
- Go to [DigitalOcean](https://digitalocean.com)
- Create Droplet: **Ubuntu 22.04 LTS**, **$6/month** (1GB RAM)
- Add your SSH key

### 2. One-Command Server Setup

SSH into your droplet and run:

```bash
curl -fsSL https://get.docker.com | sh && \
sudo usermod -aG docker $USER && \
docker network create fintrack-network && \
docker run -d --name fintrack-db --network fintrack-network \
  -e POSTGRES_PASSWORD=change_me_to_secure_password \
  -e POSTGRES_DB=fintrack_prod \
  -v fintrack-db-data:/var/lib/postgresql/data \
  --restart unless-stopped postgres:15-alpine
```

### 3. Deploy from Your Local Machine

```bash
# Generate a secret key base (save this!)
mix phx.gen.secret

# Build and deploy
./deploy.sh YOUR_DROPLET_IP docker
```

### 4. Configure Environment

SSH into your droplet:

```bash
ssh root@YOUR_DROPLET_IP

# Create .env file
nano .env
```

Paste this (update the values):

```env
DATABASE_URL=ecto://postgres:change_me_to_secure_password@fintrack-db/fintrack_prod
SECRET_KEY_BASE=paste_your_generated_secret_here
PHX_HOST=your_domain.com
PORT=4000

# Your invoice config
CLIENT_NAME=Your Company
CLIENT_ADDRESS=123 Main St
CLIENT_CITY_STATE_ZIP=City, ST 12345
CLIENT_EIN=12-3456789
BILL_TO_NAME=Your Name
BILL_TO_SWIFT_BIC=ABCDUS33XXX
BILL_TO_ACCOUNT_NUMBER=1234567890
BILL_TO_BANK_NAME=Your Bank
BILL_TO_BANK_ADDRESS=Bank Address
```

Save (Ctrl+O, Enter, Ctrl+X)

### 5. Start the App

```bash
# Run migrations
docker run --rm --network fintrack-network --env-file .env fintrack:latest /app/bin/migrate

# Start app
docker run -d --name fintrack-app --network fintrack-network \
  --env-file .env -p 4000:4000 --restart unless-stopped fintrack:latest

# Check logs
docker logs -f fintrack-app
```

### 6. Set Up Nginx (Optional but Recommended)

```bash
apt install -y nginx

cat > /etc/nginx/sites-available/fintrack << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

ln -s /etc/nginx/sites-available/fintrack /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
```

### 7. Add SSL (Free with Let's Encrypt)

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d your_domain.com
```

## Daily Backups (1 Minute Setup)

```bash
cat > /usr/local/bin/backup-fintrack.sh << 'EOF'
#!/bin/bash
docker exec fintrack-db pg_dump -U postgres fintrack_prod | \
  gzip > /root/backup-$(date +%Y%m%d).sql.gz
find /root -name "backup-*.sql.gz" -mtime +7 -delete
EOF

chmod +x /usr/local/bin/backup-fintrack.sh
echo "0 2 * * * /usr/local/bin/backup-fintrack.sh" | crontab -
```

## Updating Your App

```bash
# On your local machine
./deploy.sh YOUR_DROPLET_IP docker

# That's it! The script handles everything.
```

## Troubleshooting

```bash
# View logs
docker logs -f fintrack-app

# Check if running
docker ps

# Restart app
docker restart fintrack-app

# Restart database
docker restart fintrack-db

# Check disk space
df -h

# Check memory
free -h
```

## Cost Breakdown

| Item | Cost |
|------|------|
| Droplet (1GB) | $6/month |
| Backups (optional) | $1.20/month |
| Domain (optional) | ~$1/month |
| **Total** | **$6-8/month** |

## Need Help?

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions.

## Monitoring (Free Tier Options)

- **Uptime monitoring**: [UptimeRobot](https://uptimerobot.com) (free)
- **Error tracking**: [Sentry](https://sentry.io) (free tier)
- **Log aggregation**: [Logtail](https://logtail.com) (free tier)

## Security Checklist

- [ ] Change default PostgreSQL password
- [ ] Use a strong SECRET_KEY_BASE
- [ ] Set up SSL certificate
- [ ] Enable firewall: `ufw allow 80 && ufw allow 443 && ufw allow 22 && ufw enable`
- [ ] Set up automated backups
- [ ] Keep system updated: `apt update && apt upgrade`

---

**You're done!** 🎉

Your app is running at `http://YOUR_DROPLET_IP` (or `https://your_domain.com` if you set up SSL)
