# StreamWave CORS Proxy

A self-hosted CORS proxy server for StreamWave Radio to handle HTTP radio streams on HTTPS sites.

## Why Do You Need This?

When StreamWave Radio is served over HTTPS, browsers block HTTP radio streams due to "mixed content" security policies. This CORS proxy solves that by:

- ✅ Proxying HTTP streams through HTTPS
- ✅ Adding proper CORS headers
- ✅ Enabling metadata extraction from streams
- ✅ Providing reliable streaming without public proxy limitations

## Quick Start (Local Testing)

```bash
# Install dependencies
npm install

# Start the server
npm start

# Server will run on http://localhost:8080
```

Test it:
```bash
# In your browser or curl:
http://localhost:8080/http://ice1.somafm.com/groovesalad-128-mp3
```

## Deployment Options

### Option 1: Deploy to Heroku (Free Tier Available)

1. **Install Heroku CLI:**
   ```bash
   # macOS
   brew tap heroku/brew && brew install heroku

   # Or download from https://devcenter.heroku.com/articles/heroku-cli
   ```

2. **Login and create app:**
   ```bash
   heroku login
   heroku create my-streamwave-proxy
   ```

3. **Deploy:**
   ```bash
   cd cors-proxy
   git init
   git add .
   git commit -m "Initial CORS proxy setup"
   heroku git:remote -a my-streamwave-proxy
   git push heroku main
   ```

4. **Your proxy URL:** `https://my-streamwave-proxy.herokuapp.com`

### Option 2: Deploy to Railway.app (Easy & Modern)

1. Go to [railway.app](https://railway.app)
2. Click "Start a New Project" → "Deploy from GitHub repo"
3. Select this repository and the `cors-proxy` directory
4. Railway will auto-detect Node.js and deploy
5. Get your URL from the deployment settings

### Option 3: Deploy to Render.com (Free Tier)

1. Go to [render.com](https://render.com)
2. Create a new "Web Service"
3. Connect your repository
4. Configure:
   - **Root Directory:** `cors-proxy`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
5. Deploy and get your URL

### Option 4: Self-Hosted VPS (DigitalOcean, AWS, etc.)

1. **SSH into your server:**
   ```bash
   ssh user@your-server.com
   ```

2. **Install Node.js:**
   ```bash
   # Ubuntu/Debian
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

3. **Clone and setup:**
   ```bash
   cd /opt
   git clone https://github.com/yourusername/StreamWave-Radio.git
   cd StreamWave-Radio/cors-proxy
   npm install
   ```

4. **Run with PM2 (process manager):**
   ```bash
   # Install PM2
   sudo npm install -g pm2

   # Start the proxy
   pm2 start server.js --name streamwave-proxy

   # Make it start on boot
   pm2 startup
   pm2 save
   ```

5. **Setup Nginx reverse proxy with SSL:**
   ```nginx
   # /etc/nginx/sites-available/cors-proxy
   server {
       listen 80;
       server_name proxy.yourdomain.com;

       location / {
           proxy_pass http://localhost:8080;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

6. **Get free SSL with Let's Encrypt:**
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d proxy.yourdomain.com
   ```

### Option 5: Docker Deployment

1. **Create Dockerfile:**
   ```dockerfile
   FROM node:18-alpine
   WORKDIR /app
   COPY package*.json ./
   RUN npm install --production
   COPY . .
   EXPOSE 8080
   CMD ["node", "server.js"]
   ```

2. **Build and run:**
   ```bash
   docker build -t streamwave-proxy .
   docker run -d -p 8080:8080 --name streamwave-proxy streamwave-proxy
   ```

3. **Or use Docker Compose:**
   ```yaml
   version: '3'
   services:
     cors-proxy:
       build: .
       ports:
         - "8080:8080"
       restart: unless-stopped
   ```

## Configuration

### Environment Variables

```bash
# Set custom host and port
HOST=0.0.0.0
PORT=8080

# Example for production
HOST=0.0.0.0
PORT=3000
```

### Security Configuration (server.js)

**Restrict allowed origins:**
```javascript
originWhitelist: [
    'https://yourdomain.com',
    'https://www.yourdomain.com'
],
```

**Add rate limiting:**
```javascript
checkRateLimit: (origin) => 100, // 100 requests per minute
```

**Require authentication header:**
```javascript
requireHeader: ['x-proxy-auth'],
// Then add header in your client requests
```

## Add Proxy to StreamWave Radio

Once deployed, edit `index.html` around line 6145:

```javascript
const corsProxies = [
    // Add your proxy as the FIRST item (highest priority)
    {
        name: 'my-proxy',
        url: (streamUrl) => `https://my-proxy.herokuapp.com/${streamUrl}`
    },

    // Existing public proxies as fallbacks
    { name: 'corsproxy.io', url: (streamUrl) => `https://corsproxy.io/?${encodeURIComponent(streamUrl)}` },
    { name: 'cors.eu.org', url: (streamUrl) => `https://cors.eu.org/${streamUrl}` },
];
```

## Testing Your Proxy

```bash
# Test with curl
curl -I "http://localhost:8080/http://ice1.somafm.com/groovesalad-128-mp3"

# Should return headers with:
# Access-Control-Allow-Origin: *
# Content-Type: audio/mpeg (or similar)
```

## Troubleshooting

### Port already in use
```bash
# Change port in server.js or use environment variable
PORT=3000 npm start
```

### Proxy not working
1. Check server logs for errors
2. Verify the proxy URL is accessible
3. Test with curl first before browser
4. Check firewall settings on your server

### SSL/HTTPS issues
- Use a reverse proxy (nginx/Caddy) with SSL certificate
- Or deploy to a platform that provides SSL (Heroku, Render, etc.)

## Performance Tips

1. **Use CDN:** Put Cloudflare in front of your proxy
2. **Caching:** Enable caching for static stream metadata
3. **Multiple instances:** Deploy to multiple regions for redundancy
4. **Monitoring:** Use tools like UptimeRobot to monitor proxy health

## Security Best Practices

⚠️ **Important:** An open CORS proxy can be abused!

1. ✅ Restrict origins to your domain only
2. ✅ Add rate limiting
3. ✅ Use authentication headers
4. ✅ Monitor usage and logs
5. ✅ Use HTTPS only in production
6. ✅ Keep dependencies updated

## Cost Comparison

| Platform | Free Tier | Cost After Free |
|----------|-----------|-----------------|
| Heroku | 550-1000 hrs/month | $7/month |
| Render | 750 hrs/month | $7/month |
| Railway | $5 credit/month | Pay as you go |
| DigitalOcean | $200 credit (60 days) | $4-6/month |
| Cloudflare Workers | 100k requests/day | $5/month |

## Support

For issues or questions:
- Check server logs: `pm2 logs streamwave-proxy`
- Verify proxy is running: `curl http://your-proxy-url`
- Test with a known working stream first

## License

MIT - Feel free to use and modify for your needs!
