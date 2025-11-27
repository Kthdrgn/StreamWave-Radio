// Web Worker for fetching metadata in the background
// This worker is not throttled by the browser like setInterval in the main thread

let intervalId = null;
let currentConfig = null;

// Listen for messages from the main thread
self.addEventListener('message', (event) => {
    const { type, config } = event.data;

    if (type === 'START') {
        // Start periodic metadata fetching
        currentConfig = config;

        // Clear any existing interval
        if (intervalId) {
            clearInterval(intervalId);
        }

        // Fetch immediately
        fetchMetadata();

        // Start periodic fetching
        intervalId = setInterval(() => {
            fetchMetadata();
        }, config.interval || 10000);

        self.postMessage({ type: 'STARTED' });
    } else if (type === 'STOP') {
        // Stop periodic fetching
        if (intervalId) {
            clearInterval(intervalId);
            intervalId = null;
        }
        currentConfig = null;
        self.postMessage({ type: 'STOPPED' });
    } else if (type === 'FETCH_NOW') {
        // Fetch metadata immediately
        fetchMetadata();
    }
});

async function fetchMetadata() {
    if (!currentConfig || !currentConfig.stationUrl) {
        self.postMessage({
            type: 'DEBUG',
            message: 'No config or station URL'
        });
        return;
    }

    try {
        // Try to fetch metadata using the configured proxies
        const proxies = currentConfig.proxies || [];
        self.postMessage({
            type: 'DEBUG',
            message: `Fetching metadata for: ${currentConfig.stationUrl}, proxies: ${proxies.length}`
        });

        for (let i = 0; i < proxies.length; i++) {
            try {
                // Replace {STREAM_URL} placeholder with actual stream URL
                // Note: URL encoding is already handled in the proxy template where needed
                const proxyUrl = proxies[i].urlTemplate.replace('{STREAM_URL}', currentConfig.stationUrl);
                self.postMessage({
                    type: 'DEBUG',
                    message: `Trying proxy ${i + 1}/${proxies.length} (${proxies[i].name}): ${proxyUrl}`
                });

                const response = await fetch(proxyUrl, {
                    method: 'GET',
                    headers: {
                        'Range': 'bytes=0-16384', // Request small amount of data
                        'Icy-MetaData': '1' // Request metadata from Icecast servers
                    }
                });

                if (!response.ok) {
                    self.postMessage({
                        type: 'DEBUG',
                        message: `Proxy ${proxies[i].name} returned status: ${response.status}`
                    });
                    continue;
                }

                self.postMessage({
                    type: 'DEBUG',
                    message: `Successfully fetched from ${proxies[i].name}, extracting metadata...`
                });

                // Try to extract metadata from ICY headers
                const icyName = response.headers.get('icy-name');
                const icyDescription = response.headers.get('icy-description');
                const icyUrl = response.headers.get('icy-url');
                const icyGenre = response.headers.get('icy-genre');
                const icyBr = response.headers.get('icy-br');
                const icyMetaint = response.headers.get('icy-metaint');

                let metadata = {
                    title: null,
                    artist: null,
                    album: null
                };

                // If we have icy-metaint, try to read the metadata
                if (icyMetaint && response.body) {
                    const metaint = parseInt(icyMetaint);
                    if (!isNaN(metaint) && metaint > 0) {
                        try {
                            const reader = response.body.getReader();
                            const chunks = [];
                            let totalBytes = 0;
                            const targetBytes = metaint + 4096; // Read audio data + some metadata

                            while (totalBytes < targetBytes) {
                                const { done, value } = await reader.read();
                                if (done) break;
                                chunks.push(value);
                                totalBytes += value.length;
                            }

                            // Combine chunks
                            const buffer = new Uint8Array(totalBytes);
                            let offset = 0;
                            for (const chunk of chunks) {
                                buffer.set(chunk, offset);
                                offset += chunk.length;
                            }

                            // Skip audio data and read metadata length
                            if (totalBytes > metaint) {
                                const metadataLengthByte = buffer[metaint];
                                const metadataLength = metadataLengthByte * 16;

                                if (metadataLength > 0 && totalBytes >= metaint + 1 + metadataLength) {
                                    // Extract metadata
                                    const metadataBytes = buffer.slice(metaint + 1, metaint + 1 + metadataLength);
                                    const metadataString = new TextDecoder('utf-8').decode(metadataBytes);

                                    // Parse StreamTitle='Artist - Title';
                                    const streamTitleMatch = metadataString.match(/StreamTitle='([^']*)'/);
                                    if (streamTitleMatch && streamTitleMatch[1]) {
                                        const streamTitle = streamTitleMatch[1];

                                        // Try to split into artist and title
                                        const separators = [' - ', ' – ', ' — ', ': '];
                                        let parsed = false;

                                        for (const sep of separators) {
                                            if (streamTitle.includes(sep)) {
                                                const parts = streamTitle.split(sep);
                                                if (parts.length >= 2) {
                                                    metadata.artist = parts[0].trim();
                                                    metadata.title = parts.slice(1).join(sep).trim();
                                                    parsed = true;
                                                    break;
                                                }
                                            }
                                        }

                                        if (!parsed) {
                                            metadata.title = streamTitle.trim();
                                        }
                                    }
                                }
                            }

                            reader.cancel();
                        } catch (error) {
                            console.error('Error reading metadata from stream:', error);
                        }
                    }
                }

                // Send metadata back to main thread
                if (metadata.title || metadata.artist) {
                    self.postMessage({
                        type: 'DEBUG',
                        message: `Metadata found: ${metadata.artist} - ${metadata.title}`
                    });
                    self.postMessage({
                        type: 'METADATA',
                        metadata: metadata,
                        timestamp: Date.now()
                    });
                    return; // Success, don't try other proxies
                } else {
                    self.postMessage({
                        type: 'DEBUG',
                        message: `No metadata found from ${proxies[i].name}, trying next proxy...`
                    });
                }

                // If we got here but no metadata, try next proxy
                continue;

            } catch (error) {
                // Try next proxy
                self.postMessage({
                    type: 'DEBUG',
                    message: `Proxy ${proxies[i].name} failed with error: ${error.message}`
                });
                continue;
            }
        }

        // If we got here, all proxies failed
        self.postMessage({
            type: 'ERROR',
            error: 'Failed to fetch metadata from all proxies',
            timestamp: Date.now()
        });

    } catch (error) {
        self.postMessage({
            type: 'ERROR',
            error: error.message,
            timestamp: Date.now()
        });
    }
}
