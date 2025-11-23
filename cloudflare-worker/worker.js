/**
 * StreamWave Radio - Cloudflare Worker CORS Proxy
 *
 * This worker proxies HTTP radio streams through HTTPS to avoid
 * mixed content issues when the app is served over HTTPS.
 */

// CORS headers configuration
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Range, Icy-MetaData',
  'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Content-Type, Icy-Name, Icy-Genre, Icy-Br, Icy-Sr, Icy-Url, Icy-MetaInt',
  'Access-Control-Max-Age': '86400',
};

/**
 * Handle incoming requests
 */
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Handle CORS preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: corsHeaders
      });
    }

    // Extract the target URL from the path
    // Format: https://worker.example.com/http://radio-stream-url.com/stream.mp3
    const targetUrl = url.pathname.slice(1); // Remove leading slash

    // Validate the target URL
    if (!targetUrl || (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://'))) {
      return new Response(
        JSON.stringify({
          error: 'Invalid request',
          message: 'Please provide a valid URL to proxy',
          usage: 'https://your-worker.workers.dev/http://example.com/stream.mp3'
        }),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders
          }
        }
      );
    }

    try {
      // Fetch the target stream
      const targetRequest = new Request(targetUrl, {
        method: request.method,
        headers: filterHeaders(request.headers),
        redirect: 'follow'
      });

      const response = await fetch(targetRequest);

      // Create a new response with CORS headers
      const modifiedResponse = new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: buildResponseHeaders(response.headers)
      });

      return modifiedResponse;

    } catch (error) {
      return new Response(
        JSON.stringify({
          error: 'Proxy error',
          message: error.message,
          target: targetUrl
        }),
        {
          status: 502,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders
          }
        }
      );
    }
  }
};

/**
 * Filter request headers - remove sensitive headers
 */
function filterHeaders(headers) {
  const filtered = new Headers();

  // Headers to forward
  const allowedHeaders = [
    'accept',
    'accept-encoding',
    'accept-language',
    'range',
    'user-agent',
    'icy-metadata'
  ];

  for (const [key, value] of headers.entries()) {
    if (allowedHeaders.includes(key.toLowerCase())) {
      filtered.set(key, value);
    }
  }

  return filtered;
}

/**
 * Build response headers with CORS support
 */
function buildResponseHeaders(originalHeaders) {
  const headers = new Headers(corsHeaders);

  // Headers to forward from the original response
  const allowedResponseHeaders = [
    'content-type',
    'content-length',
    'content-range',
    'accept-ranges',
    'cache-control',
    'icy-name',
    'icy-genre',
    'icy-br',
    'icy-sr',
    'icy-url',
    'icy-metaint'
  ];

  for (const [key, value] of originalHeaders.entries()) {
    if (allowedResponseHeaders.includes(key.toLowerCase())) {
      headers.set(key, value);
    }
  }

  return headers;
}
