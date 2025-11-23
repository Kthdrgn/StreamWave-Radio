# StreamWave Radio - Cloudflare Worker CORS Proxy

This Cloudflare Worker provides a CORS proxy for HTTP radio streams, allowing the StreamWave Radio app to play HTTP streams on an HTTPS page without mixed content warnings.

## Why Cloudflare Workers?

**Advantages over Render.com:**
- ⚡ **Faster**: Deployed globally across 300+ edge locations
- 🌍 **Better Performance**: Requests are handled at the nearest edge location to users
- 💰 **Generous Free Tier**: 100,000 requests/day (vs Render's 750 hours/month)
- 🚀 **Instant Cold Starts**: No spin-up time (vs Render's ~30 second cold starts)
- 📈 **Scalability**: Automatically scales globally
- 🔧 **Simple Deployment**: Deploy with one command

**Free Tier Includes:**
- 100,000 requests per day
- 10ms CPU time per request
- Unlimited bandwidth
- Global edge deployment
- Custom *.workers.dev subdomain

## Quick Start

### Prerequisites

1. A Cloudflare account (free): https://dash.cloudflare.com/sign-up
2. Node.js installed (v16.13 or higher)

### Installation

1. Install Wrangler (Cloudflare's CLI):
```bash
npm install
```

2. Login to Cloudflare:
```bash
npx wrangler login
```

This will open a browser window to authorize Wrangler with your Cloudflare account.

### Configuration

1. Get your Cloudflare Account ID:
   - Go to https://dash.cloudflare.com/
   - Select any website (or Workers & Pages from the sidebar)
   - Your Account ID is shown in the URL or the right sidebar

2. Update `wrangler.toml`:
```toml
# Uncomment and replace with your actual account ID
account_id = "your-account-id-here"
```

### Deployment

#### Deploy to Production

```bash
npm run deploy
```

Or with wrangler directly:
```bash
npx wrangler deploy
```

After deployment, you'll get a URL like:
```
https://streamwave-cors-proxy.your-subdomain.workers.dev
```

#### Test Locally First

```bash
npm run dev
```

This starts a local development server at `http://localhost:8787`

#### Deploy to Staging (Optional)

```bash
npm run deploy:staging
```

### Testing the Proxy

Once deployed, test it with:

```bash
# Test with a simple HTTP endpoint
curl https://streamwave-cors-proxy.your-subdomain.workers.dev/http://httpbin.org/get

# Test with an actual radio stream
curl -I https://streamwave-cors-proxy.your-subdomain.workers.dev/http://stream.example.com/radio.mp3
```

## Usage

### URL Format

```
https://your-worker.workers.dev/[TARGET_URL]
```

### Examples

```javascript
// Original HTTP stream
const httpStream = 'http://radio.example.com/stream.mp3';

// Proxied HTTPS stream
const proxiedStream = 'https://streamwave-cors-proxy.your-subdomain.workers.dev/http://radio.example.com/stream.mp3';
```

## Integrating with StreamWave

After deploying your worker, update the `index.html` file to use your Cloudflare Worker URL:

```javascript
const corsProxies = [
    // Your Cloudflare Worker (highest priority)
    {
        name: 'cloudflare-worker',
        url: (streamUrl) => `https://streamwave-cors-proxy.YOUR-SUBDOMAIN.workers.dev/${streamUrl}`
    },

    // Fallback options...
    { name: 'corsproxy.io', url: (streamUrl) => `https://corsproxy.io/?${encodeURIComponent(streamUrl)}` },
];
```

**Replace `YOUR-SUBDOMAIN` with your actual Cloudflare Workers subdomain!**

## Monitoring

### View Real-Time Logs

```bash
npm run tail
```

Or:
```bash
npx wrangler tail
```

### Cloudflare Dashboard

Monitor your worker at:
https://dash.cloudflare.com/ → Workers & Pages → streamwave-cors-proxy

You can see:
- Request count and success rate
- CPU time usage
- Error rates
- Geographic distribution

## Custom Domain (Paid Plan Only)

If you upgrade to the Workers Paid plan ($5/month), you can use a custom domain:

1. Add your domain to Cloudflare
2. Update `wrangler.toml`:

```toml
[env.production]
name = "streamwave-cors-proxy"
routes = [
  { pattern = "proxy.yourdomain.com/*", zone_name = "yourdomain.com" }
]
```

3. Deploy:
```bash
npm run deploy:production
```

Your proxy will be available at `https://proxy.yourdomain.com/`

## Security Considerations

### Current Configuration

The worker is currently **open** - it proxies any URL. This is fine for public radio streams but could be abused.

### Recommended Security Enhancements

#### 1. Whitelist Specific Domains

Edit `worker.js` to only allow specific radio stream domains:

```javascript
const ALLOWED_DOMAINS = [
  'stream.example.com',
  'radio.another-example.org',
  // Add your trusted radio stream domains
];

function isAllowedDomain(url) {
  const hostname = new URL(url).hostname;
  return ALLOWED_DOMAINS.some(domain =>
    hostname === domain || hostname.endsWith('.' + domain)
  );
}

// In the fetch handler:
if (!isAllowedDomain(targetUrl)) {
  return new Response('Domain not allowed', { status: 403 });
}
```

#### 2. Rate Limiting

Cloudflare Workers don't have built-in rate limiting on the free tier, but you can:
- Use Cloudflare's WAF (Web Application Firewall) on paid plans
- Implement custom rate limiting with Workers KV or Durable Objects (requires paid plan)

#### 3. Restrict to Your Domain

Only allow requests from your StreamWave domain:

```javascript
const ALLOWED_ORIGINS = ['https://yourdomain.com'];

function isAllowedOrigin(request) {
  const origin = request.headers.get('Origin');
  return ALLOWED_ORIGINS.includes(origin);
}

// Update CORS headers dynamically
const corsHeaders = {
  'Access-Control-Allow-Origin': request.headers.get('Origin'),
  // ... other headers
};
```

## Troubleshooting

### Issue: "Error 1101: Worker threw exception"

**Cause**: Error in the worker code or invalid URL

**Solution**: Check logs with `npm run tail` and verify the URL format

### Issue: "Error 1015: Rate limited"

**Cause**: Too many requests (exceeded free tier limits)

**Solutions**:
- Upgrade to paid plan ($5/month for 10M requests)
- Implement caching
- Use multiple workers with different names

### Issue: Stream playback stutters

**Cause**: Worker CPU time limit exceeded (10ms on free tier)

**Solution**: The worker is designed to stream efficiently, but very large files might hit limits. For radio streams this shouldn't be an issue.

### Issue: "Authentication error" when deploying

**Solution**: Re-login to Cloudflare:
```bash
npx wrangler logout
npx wrangler login
```

## Updating the Worker

1. Make changes to `worker.js`
2. Test locally:
```bash
npm run dev
```
3. Deploy:
```bash
npm run deploy
```

## Cost Comparison

| Platform | Free Tier | Cold Start | Edge Locations | Custom Domain |
|----------|-----------|------------|----------------|---------------|
| **Cloudflare Workers** | 100k req/day | None | 300+ | Paid only |
| **Render** | 750 hrs/month | ~30 seconds | Limited | Free |
| **Heroku** | 550 hrs/month | ~30 seconds | US/EU | Free |

## Additional Resources

- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)
- [Wrangler CLI Reference](https://developers.cloudflare.com/workers/wrangler/)
- [Workers Examples](https://developers.cloudflare.com/workers/examples/)
- [Pricing Details](https://developers.cloudflare.com/workers/platform/pricing/)

## Support

For issues specific to:
- **Cloudflare Workers**: https://community.cloudflare.com/
- **StreamWave Radio**: [GitHub Issues](https://github.com/Kthdrgn/StreamWave-Radio/issues)

## License

MIT License - Same as StreamWave Radio project
