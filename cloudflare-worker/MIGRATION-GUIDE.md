# Migration Guide: Render.com → Cloudflare Workers

This guide will help you migrate your StreamWave Radio CORS proxy from Render.com to Cloudflare Workers.

## What's Been Set Up

✅ **New Cloudflare Worker implementation** (`worker.js`)
✅ **Configuration files** (`wrangler.toml`, `package.json`)
✅ **Deployment documentation** (`README.md`)
✅ **Updated index.html** with Cloudflare Worker option (commented out)

## Migration Steps

### Step 1: Set Up Cloudflare Account (5 minutes)

1. Create a free Cloudflare account: https://dash.cloudflare.com/sign-up
2. Note your **Account ID**:
   - Go to https://dash.cloudflare.com/
   - Click on "Workers & Pages" in the sidebar
   - Your Account ID is shown in the right sidebar or in the URL

### Step 2: Install and Configure (2 minutes)

```bash
cd cloudflare-worker

# Install dependencies
npm install

# Login to Cloudflare (opens browser)
npx wrangler login
```

### Step 3: Update Configuration (1 minute)

Edit `wrangler.toml` and uncomment/update your Account ID:

```toml
# Replace with your actual account ID
account_id = "abc123def456..."
```

### Step 4: Test Locally (Optional but Recommended)

```bash
# Start local dev server
npm run dev
```

Visit http://localhost:8787/http://httpbin.org/get to test

### Step 5: Deploy to Cloudflare

```bash
# Deploy to production
npm run deploy
```

You'll get output like:
```
✨ Deployment complete!
URL: https://streamwave-cors-proxy.YOUR-SUBDOMAIN.workers.dev
```

**Copy this URL!** You'll need it for the next step.

### Step 6: Update index.html

1. Open `index.html`
2. Find line ~6120 (the Cloudflare Worker comment)
3. Uncomment the line and replace `YOUR-SUBDOMAIN` with your actual subdomain:

```javascript
const corsProxies = [
    // 👇 Self-hosted CORS proxies (highest priority):

    // Cloudflare Worker (recommended - fastest, global edge deployment)
    { name: 'cloudflare-worker', url: (streamUrl) => `https://streamwave-cors-proxy.YOUR-SUBDOMAIN.workers.dev/${streamUrl}` },

    // Render.com (fallback)
    { name: 'streamwave-render', url: (streamUrl) => `https://streamwave-radio.onrender.com/${streamUrl}` },
    // ... rest
];
```

### Step 7: Test Your Deployment

1. Open your StreamWave Radio app
2. Try playing an HTTP stream on an HTTPS page
3. Open browser DevTools → Network tab
4. Look for requests to your Cloudflare Worker URL
5. Verify the stream plays successfully

### Step 8: Monitor Performance

```bash
# View real-time logs
npm run tail
```

Or visit: https://dash.cloudflare.com/ → Workers & Pages → streamwave-cors-proxy

## Comparison: Before & After

| Feature | Render.com | Cloudflare Workers |
|---------|------------|-------------------|
| **Cold Start** | ~30 seconds | None (instant) |
| **Locations** | Single region | 300+ edge locations |
| **Free Tier** | 750 hours/month | 100,000 requests/day |
| **Speed** | Good | Excellent (edge) |
| **Reliability** | Good | Excellent |

## Keeping Both (Recommended)

You can keep both proxies active for redundancy:

1. Cloudflare Worker as **primary** (fastest, most reliable)
2. Render.com as **fallback** (if Cloudflare has issues)

This is already set up in the updated `index.html`!

## Optional: Remove Render Deployment

Once you've confirmed Cloudflare Workers is working well, you can:

1. Delete the Render.com service (saves your free tier hours)
2. Remove the Render proxy from `index.html` (keep it for now as fallback)

## Troubleshooting

### "Error: No account_id found"

**Solution**: Update `wrangler.toml` with your Account ID

### "Error 10000: Authentication error"

**Solution**: Re-run `npx wrangler login`

### "Worker not receiving requests"

**Solution**: Verify the URL in `index.html` matches your deployed worker URL exactly

### Stream still not playing

**Solution**:
1. Check browser console for errors
2. Verify the worker is deployed: visit `https://your-worker.workers.dev/` directly
3. Test with `npm run tail` to see real-time logs

## Getting Help

- **Cloudflare Workers Docs**: https://developers.cloudflare.com/workers/
- **Cloudflare Community**: https://community.cloudflare.com/
- **StreamWave Issues**: https://github.com/Kthdrgn/StreamWave-Radio/issues

## Next Steps

After successful migration, consider:

1. ✅ **Monitor Usage**: Check Cloudflare dashboard weekly
2. ✅ **Set Up Alerts**: Get notified if you approach free tier limits
3. 🔒 **Add Security**: Implement domain whitelisting (see README.md)
4. 🚀 **Custom Domain**: Upgrade to Workers Paid ($5/mo) for custom domain

## Rollback Plan

If you encounter issues and need to rollback:

1. Comment out the Cloudflare Worker line in `index.html`
2. Keep using Render.com (already configured as fallback)
3. No other changes needed!

---

**Time Required**: ~15 minutes total
**Difficulty**: Easy
**Cost**: Free (Cloudflare Workers free tier)
