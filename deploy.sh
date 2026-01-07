#!/bin/bash

# FinTrack Deployment Script
# Usage: ./deploy.sh [server_ip] [deploy_method]
# deploy_method: docker | release

set -e

SERVER_IP=${1:-""}
DEPLOY_METHOD=${2:-"docker"}

if [ -z "$SERVER_IP" ]; then
    echo "Usage: ./deploy.sh [server_ip] [deploy_method]"
    echo "Example: ./deploy.sh 142.93.123.45 docker"
    exit 1
fi

echo "🚀 Deploying FinTrack to $SERVER_IP using $DEPLOY_METHOD method..."

if [ "$DEPLOY_METHOD" = "docker" ]; then
    echo "📦 Building Docker image..."
    docker build -t fintrack:latest .

    echo "💾 Saving Docker image..."
    docker save fintrack:latest | gzip > fintrack-latest.tar.gz

    echo "📤 Uploading to server..."
    scp fintrack-latest.tar.gz fintrack@$SERVER_IP:~/

    echo "🔄 Deploying on server..."
    ssh fintrack@$SERVER_IP << 'ENDSSH'
        # Load the new image
        docker load < fintrack-latest.tar.gz

        # Run migrations
        docker run --rm \
          --network fintrack-network \
          --env-file .env \
          fintrack:latest /app/bin/migrate

        # Stop and remove old container
        docker stop fintrack-app || true
        docker rm fintrack-app || true

        # Start new container
        docker run -d \
          --name fintrack-app \
          --network fintrack-network \
          --env-file .env \
          -p 4000:4000 \
          --restart unless-stopped \
          fintrack:latest

        echo "✅ Deployment complete!"
        echo "📋 Checking logs..."
        docker logs --tail 50 fintrack-app
ENDSSH

    # Clean up local tar file
    rm fintrack-latest.tar.gz

elif [ "$DEPLOY_METHOD" = "release" ]; then
    echo "🔨 Building release..."
    MIX_ENV=prod mix deps.get
    MIX_ENV=prod mix assets.deploy
    MIX_ENV=prod mix release

    echo "📦 Creating tarball..."
    cd _build/prod/rel/fintrack
    tar czf fintrack.tar.gz .

    echo "📤 Uploading to server..."
    scp fintrack.tar.gz fintrack@$SERVER_IP:~/
    cd - > /dev/null

    echo "🔄 Deploying on server..."
    ssh fintrack@$SERVER_IP << 'ENDSSH'
        # Stop the service
        sudo systemctl stop fintrack

        # Extract new release
        cd ~/app
        tar xzf ~/fintrack.tar.gz

        # Run migrations
        ./bin/migrate

        # Start the service
        sudo systemctl start fintrack

        echo "✅ Deployment complete!"
        echo "📋 Checking status..."
        sudo systemctl status fintrack --no-pager -l
ENDSSH

    # Clean up
    rm _build/prod/rel/fintrack/fintrack.tar.gz
else
    echo "❌ Invalid deploy method: $DEPLOY_METHOD"
    echo "Valid methods: docker, release"
    exit 1
fi

echo "✨ All done! Your app should be running at http://$SERVER_IP:4000"
