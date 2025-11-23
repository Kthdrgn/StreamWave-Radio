// StreamWave CORS Proxy Server
// Based on cors-anywhere for handling HTTP radio streams on HTTPS sites

const cors_proxy = require('cors-anywhere');

// Configuration
const HOST = process.env.HOST || '0.0.0.0';
const PORT = process.env.PORT || 8080;

// Create CORS Anywhere server with custom configuration
const server = cors_proxy.createServer({
    // Allow origin from any domain (adjust for security if needed)
    originWhitelist: [], // Empty = allow all origins

    // Require header to prevent abuse (optional, comment out for open proxy)
    // requireHeader: ['origin', 'x-requested-with'],

    // Remove these headers from proxied response
    removeHeaders: [
        'cookie',
        'cookie2',
        // Uncomment if you want to remove these:
        // 'x-frame-options',
        // 'x-xss-protection',
    ],

    // Redirect location header to proxied URL
    redirectSameOrigin: true,

    // Set CORS headers
    httpProxyOptions: {
        // Enable streaming for audio
        xfwd: false,
    },

    // Optional: Rate limiting (requests per minute)
    // Uncomment and adjust as needed:
    // setHeaders: {},
    // checkRateLimit: (origin) => 100, // 100 requests per minute per origin
});

// Start the server
server.listen(PORT, HOST, () => {
    console.log('╔════════════════════════════════════════════════╗');
    console.log('║   StreamWave CORS Proxy Server Running        ║');
    console.log('╚════════════════════════════════════════════════╝');
    console.log('');
    console.log(`🚀 Server listening on: http://${HOST}:${PORT}`);
    console.log('');
    console.log('📡 Usage:');
    console.log(`   http://${HOST}:${PORT}/http://radio-stream-url`);
    console.log('');
    console.log('💡 Examples:');
    console.log(`   http://${HOST}:${PORT}/http://stream.example.com:8000/radio.mp3`);
    console.log(`   http://${HOST}:${PORT}/http://ice1.somafm.com/groovesalad-128-mp3`);
    console.log('');
    console.log('⚠️  Security Notes:');
    console.log('   - For production, configure originWhitelist in server.js');
    console.log('   - Consider adding authentication or rate limiting');
    console.log('   - Use HTTPS with a reverse proxy (nginx/Caddy)');
    console.log('');
    console.log('Press Ctrl+C to stop the server');
    console.log('════════════════════════════════════════════════');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('\n🛑 Shutting down gracefully...');
    server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down gracefully...');
    server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});
