// ==============================================
// RADIO APP - AUTHENTICATION & DATA SYNC MODULE
// ==============================================
// This file handles Supabase authentication and data synchronization
// Include this file AFTER the Supabase CDN and BEFORE your main script

// ==============================================
// CONFIGURATION
// ==============================================

// IMPORTANT: Replace these with your actual Supabase credentials
const SUPABASE_URL = 'https://zwrunupvlkhnwbylzizj.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3cnVudXB2bGtobndieWx6aXpqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExMTIxNzEsImV4cCI6MjA3NjY4ODE3MX0.WBTLcTNWgGZ-I6o_Dd7ObfS2avmJc_iiIEpDp8-VuQ4';

// Initialize Supabase client
const { createClient } = supabase;
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Authentication state (exposed globally)
window.currentUser = null;
window.isAuthenticated = false;
window.isGuestMode = true;

// ==============================================
// AUTHENTICATION FUNCTIONS
// ==============================================

// Check authentication status
async function checkAuth() {
    const { data: { session } } = await supabaseClient.auth.getSession();
    
    if (session) {
        window.currentUser = session.user;
        window.isAuthenticated = true;
        window.isGuestMode = false;
        console.log('✅ User authenticated:', window.currentUser.email);
        
        // Check if we need to migrate guest data
        if (sessionStorage.getItem('needsMigration') === 'true') {
            await migrateGuestData();
            sessionStorage.removeItem('needsMigration');
        }
        
        // Update UI to show user info
        updateAuthUI();
    } else {
        // Guest mode - use localStorage
        window.isGuestMode = true;
        window.isAuthenticated = false;
        console.log('👤 Running in guest mode');
        updateAuthUI();
    }
}

// Listen for auth state changes
supabaseClient.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_IN') {
        checkAuth();
    } else if (event === 'SIGNED_OUT') {
        window.currentUser = null;
        window.isAuthenticated = false;
        window.isGuestMode = true;
        updateAuthUI();
        location.reload();
    }
});

// Update UI based on auth state
function updateAuthUI() {
    // Update auth button with user info
    updateAuthButton();

    // Show/hide Add Station button based on admin status
    updateAddStationButton();
}

// Update auth button text
function updateAuthButton() {
    const authBtnText = document.getElementById('authBtnText');
    if (authBtnText) {
        if (window.isAuthenticated && window.currentUser) {
            const userEmail = window.currentUser.email;
            const displayName = userEmail.split('@')[0];
            authBtnText.textContent = `Signed in as ${displayName}`;
        } else {
            authBtnText.textContent = 'Sign In';
        }
    }
}

// Update Add Station button visibility based on admin status
function updateAddStationButton() {
    const addStationBtn = document.getElementById('addStationBtn');
    if (addStationBtn) {
        // Check if current user is admin
        const isAdmin = window.currentUser && window.currentUser.email === 'keith.e.dragon@gmail.com';

        // Show button only if user is admin
        if (isAdmin) {
            addStationBtn.style.display = '';
        } else {
            addStationBtn.style.display = 'none';
        }
    }
}

// Sign out function
async function signOut() {
    if (confirm('Are you sure you want to sign out? Your data will remain saved in your account.')) {
        await supabaseClient.auth.signOut();
        window.location.href = 'login.html';
    }
}

// Migrate guest data to authenticated user
async function migrateGuestData() {
    console.log('🔄 Migrating guest data to user account...');

    try {
        let migratedCount = 0;
        let stationHistoryCount = 0;

        // Migrate liked tracks
        const guestLikedTracks = localStorage.getItem('likedTracks');
        if (guestLikedTracks) {
            const tracks = JSON.parse(guestLikedTracks);
            for (const track of tracks) {
                await supabaseClient
                    .from('liked_tracks')
                    .insert([{
                        user_id: window.currentUser.id,
                        title: track.title,
                        artist: track.artist,
                        album: track.album || '',
                        artwork_url: track.artworkUrl || '',
                        station_name: track.station || 'Unknown Station'
                    }]);
            }
            migratedCount += tracks.length;
            console.log(`✅ Migrated ${tracks.length} liked tracks`);
        }

        // Migrate recent tracks
        const guestRecentTracks = localStorage.getItem('recentTracks');
        if (guestRecentTracks) {
            const tracks = JSON.parse(guestRecentTracks);
            for (const track of tracks) {
                await supabaseClient
                    .from('recent_tracks')
                    .insert([{
                        user_id: window.currentUser.id,
                        title: track.title,
                        artist: track.artist,
                        album: track.album || '',
                        artwork_url: track.artworkUrl || '',
                        station_name: track.station || 'Unknown Station'
                    }]);
            }
            console.log(`✅ Migrated ${tracks.length} recent tracks`);
        }

        // Migrate station history (recent stations & most played)
        const guestStationHistory = localStorage.getItem('station_history');
        if (guestStationHistory) {
            const history = JSON.parse(guestStationHistory);
            // Batch insert station history
            if (history.length > 0) {
                const historyRecords = history.map(record => ({
                    user_id: window.currentUser.id,
                    station_id: record.station_id,
                    clicked_at: record.clicked_at
                }));

                // Insert in batches of 100 to avoid request limits
                for (let i = 0; i < historyRecords.length; i += 100) {
                    const batch = historyRecords.slice(i, i + 100);
                    await supabaseClient
                        .from('station_history')
                        .insert(batch);
                }

                stationHistoryCount = history.length;
                console.log(`✅ Migrated ${history.length} station history records`);
            }
        }

        // Clear localStorage after successful migration
        localStorage.removeItem('likedTracks');
        localStorage.removeItem('recentTracks');
        localStorage.removeItem('station_history');

        if (migratedCount > 0 || stationHistoryCount > 0) {
            const messages = [];
            if (migratedCount > 0) messages.push(`${migratedCount} liked tracks`);
            if (stationHistoryCount > 0) messages.push(`${stationHistoryCount} station history records`);
            alert(`✨ Successfully migrated ${messages.join(' and ')} to your account!`);
        }
    } catch (error) {
        console.error('❌ Error migrating data:', error);
        alert('There was an error migrating some of your data. Your local data has been preserved.');
    }
}

// ==============================================
// LIKED TRACKS FUNCTIONS (with Supabase sync)
// ==============================================

// Load liked tracks (works in both guest and authenticated mode)
async function loadLikedTracks() {
    if (window.isGuestMode) {
        // Guest mode - use localStorage
        const stored = localStorage.getItem('likedTracks');
        return stored ? JSON.parse(stored) : [];
    } else {
        // Authenticated - use Supabase
        const { data, error } = await supabaseClient
            .from('liked_tracks')
            .select('*')
            .eq('user_id', window.currentUser.id)
            .order('created_at', { ascending: false });
        
        if (error) {
            console.error('Error loading liked tracks:', error);
            return [];
        }
        
        return data || [];
    }
}

// Save liked tracks (guest mode only, authenticated saves individually)
async function saveLikedTracks(tracks) {
    if (window.isGuestMode) {
        localStorage.setItem('likedTracks', JSON.stringify(tracks));
    }
}

// Add a liked track (called from main app)
async function addLikedTrack(trackInfo) {
    if (window.isGuestMode) {
        // Guest mode - add to localStorage
        const likedTracks = await loadLikedTracks();
        
        // Check if already liked
        const alreadyLiked = likedTracks.some(track => 
            track.title === trackInfo.title && track.artist === trackInfo.artist
        );
        
        if (alreadyLiked) {
            return false; // Already liked
        }
        
        likedTracks.unshift({
            title: trackInfo.title,
            artist: trackInfo.artist,
            album: trackInfo.album || '',
            artworkUrl: trackInfo.artworkUrl || '',
            station: trackInfo.station || 'Unknown Station',
            timestamp: new Date().toISOString()
        });
        
        saveLikedTracks(likedTracks);
        return true;
    } else {
        // Authenticated - check if already liked
        const { data: existing } = await supabaseClient
            .from('liked_tracks')
            .select('id')
            .eq('user_id', window.currentUser.id)
            .eq('title', trackInfo.title)
            .eq('artist', trackInfo.artist)
            .maybeSingle();

        if (existing) {
            return false; // Already liked
        }
        
        // Insert to Supabase
        const { error } = await supabaseClient
            .from('liked_tracks')
            .insert([{
                user_id: window.currentUser.id,
                title: trackInfo.title,
                artist: trackInfo.artist,
                album: trackInfo.album || '',
                artwork_url: trackInfo.artworkUrl || '',
                station_name: trackInfo.station || 'Unknown Station'
            }]);
        
        if (error) {
            console.error('Error saving liked track:', error);
            return false;
        }
        
        return true;
    }
}

// Remove a liked track
async function removeLikedTrack(track) {
    if (window.isGuestMode) {
        // Guest mode
        const likedTracks = await loadLikedTracks();
        const filtered = likedTracks.filter(t => 
            !(t.title === track.title && t.artist === track.artist)
        );
        saveLikedTracks(filtered);
    } else {
        // Authenticated - delete from Supabase
        const { error } = await supabaseClient
            .from('liked_tracks')
            .delete()
            .eq('id', track.id);
        
        if (error) {
            console.error('Error deleting liked track:', error);
        }
    }
}

// Check if track is liked
async function isTrackLiked(title, artist) {
    const likedTracks = await loadLikedTracks();
    return likedTracks.some(track => 
        track.title === title && track.artist === artist
    );
}

// Clear all liked tracks
async function clearAllLikedTracks() {
    if (window.isGuestMode) {
        saveLikedTracks([]);
    } else {
        const { error } = await supabaseClient
            .from('liked_tracks')
            .delete()
            .eq('user_id', window.currentUser.id);
        
        if (error) {
            console.error('Error clearing liked tracks:', error);
        }
    }
}

// ==============================================
// RECENT TRACKS FUNCTIONS (with Supabase sync)
// ==============================================

// Load recent tracks
async function loadRecentTracks() {
    if (window.isGuestMode) {
        const stored = localStorage.getItem('recentTracks');
        return stored ? JSON.parse(stored) : [];
    } else {
        const { data, error } = await supabaseClient
            .from('recent_tracks')
            .select('*')
            .eq('user_id', window.currentUser.id)
            .order('played_at', { ascending: false })
            .limit(15);
        
        if (error) {
            console.error('Error loading recent tracks:', error);
            return [];
        }
        
        return data || [];
    }
}

// Save recent tracks (guest mode only)
async function saveRecentTracks(tracks) {
    if (window.isGuestMode) {
        localStorage.setItem('recentTracks', JSON.stringify(tracks));
    }
}

// Add to recent tracks
async function addToRecentTracks(trackInfo) {
    if (!trackInfo.title || !trackInfo.artist) return;

    if (window.isGuestMode) {
        // Guest mode - use localStorage
        const recentTracks = await loadRecentTracks();

        // Find existing track to preserve artwork if new one is empty
        const existingTrack = recentTracks.find(track =>
            track.title === trackInfo.title && track.artist === trackInfo.artist
        );

        // Remove if already exists
        const filteredTracks = recentTracks.filter(track =>
            !(track.title === trackInfo.title && track.artist === trackInfo.artist)
        );

        const newTrack = {
            title: trackInfo.title,
            artist: trackInfo.artist,
            album: trackInfo.album || '',
            artworkUrl: trackInfo.artworkUrl || (existingTrack && existingTrack.artworkUrl) || '',
            station: trackInfo.station || 'Unknown Station',
            timestamp: new Date().toISOString()
        };

        filteredTracks.unshift(newTrack);
        const limitedTracks = filteredTracks.slice(0, 15);
        saveRecentTracks(limitedTracks);
    } else {
        // Authenticated - insert to Supabase
        // Check if there's an existing entry to preserve artwork if new one is empty
        let artworkUrl = trackInfo.artworkUrl || '';

        if (!artworkUrl) {
            // If new artwork is empty, try to preserve existing artwork
            const { data: existing } = await supabaseClient
                .from('recent_tracks')
                .select('artwork_url')
                .eq('user_id', window.currentUser.id)
                .eq('title', trackInfo.title)
                .eq('artist', trackInfo.artist)
                .maybeSingle();

            if (existing && existing.artwork_url) {
                artworkUrl = existing.artwork_url;
            }
        }

        // Delete existing entry for this track (to move it to top)
        await supabaseClient
            .from('recent_tracks')
            .delete()
            .eq('user_id', window.currentUser.id)
            .eq('title', trackInfo.title)
            .eq('artist', trackInfo.artist);

        // Insert new entry with preserved or new artwork
        const { error } = await supabaseClient
            .from('recent_tracks')
            .insert([{
                user_id: window.currentUser.id,
                title: trackInfo.title,
                artist: trackInfo.artist,
                album: trackInfo.album || '',
                artwork_url: artworkUrl,
                station_name: trackInfo.station || 'Unknown Station'
            }]);

        if (error) {
            console.error('Error saving recent track:', error);
            return;
        }

        // Cleanup: Keep only the 15 most recent tracks for this user
        // Get all tracks ordered by played_at
        const { data: allTracks } = await supabaseClient
            .from('recent_tracks')
            .select('id, played_at')
            .eq('user_id', window.currentUser.id)
            .order('played_at', { ascending: false });

        if (allTracks && allTracks.length > 15) {
            // Get IDs of tracks to delete (everything after the first 15)
            const tracksToDelete = allTracks.slice(15).map(track => track.id);

            // Delete old tracks
            await supabaseClient
                .from('recent_tracks')
                .delete()
                .in('id', tracksToDelete);
        }
    }
}

// Clear all recent tracks
async function clearAllRecentTracks() {
    if (window.isGuestMode) {
        saveRecentTracks([]);
    } else {
        const { error } = await supabaseClient
            .from('recent_tracks')
            .delete()
            .eq('user_id', window.currentUser.id);
        
        if (error) {
            console.error('Error clearing recent tracks:', error);
        }
    }
}

// Cleanup old recent tracks (keep only last 15 per user)
// This can be called manually to clean up existing data
async function cleanupOldRecentTracks() {
    if (window.isGuestMode) {
        console.log('Cleanup not needed in guest mode');
        return;
    }

    try {
        console.log('🧹 Cleaning up old recent tracks...');

        // Get all tracks for the current user ordered by played_at
        const { data: allTracks } = await supabaseClient
            .from('recent_tracks')
            .select('id, played_at')
            .eq('user_id', window.currentUser.id)
            .order('played_at', { ascending: false });

        if (allTracks && allTracks.length > 15) {
            // Get IDs of tracks to delete (everything after the first 15)
            const tracksToDelete = allTracks.slice(15).map(track => track.id);

            // Delete old tracks
            const { error } = await supabaseClient
                .from('recent_tracks')
                .delete()
                .in('id', tracksToDelete);

            if (error) {
                console.error('Error cleaning up old tracks:', error);
            } else {
                console.log(`✅ Deleted ${tracksToDelete.length} old tracks`);
            }
        } else {
            console.log('✅ No cleanup needed - you have 15 or fewer tracks');
        }
    } catch (error) {
        console.error('Error during cleanup:', error);
    }
}

// ==============================================
// UTILITY FUNCTIONS
// ==============================================

// Normalize track data format (handles both localStorage and Supabase formats)
function normalizeTrack(track) {
    return {
        id: track.id || null,
        title: track.title,
        artist: track.artist,
        album: track.album || '',
        artworkUrl: track.artworkUrl || track.artwork_url || '',
        station: track.station || track.station_name || 'Unknown Station',
        timestamp: track.timestamp || track.created_at || track.played_at || new Date().toISOString()
    };
}

// ==============================================
// INITIALIZATION
// ==============================================

// Auto-initialize authentication when this script loads
console.log('🔐 Authentication module loaded');

// Export functions to global scope for use in main app
window.checkAuth = checkAuth;
window.signOut = signOut;
window.updateAuthUI = updateAuthUI;
window.updateAuthButton = updateAuthButton;
window.loadLikedTracks = loadLikedTracks;
window.saveLikedTracks = saveLikedTracks;
window.addLikedTrack = addLikedTrack;
window.removeLikedTrack = removeLikedTrack;
window.isTrackLiked = isTrackLiked;
window.clearAllLikedTracks = clearAllLikedTracks;
window.loadRecentTracks = loadRecentTracks;
window.saveRecentTracks = saveRecentTracks;
window.addToRecentTracks = addToRecentTracks;
window.clearAllRecentTracks = clearAllRecentTracks;
window.cleanupOldRecentTracks = cleanupOldRecentTracks;
window.normalizeTrack = normalizeTrack;
window.supabaseClient = supabaseClient;

console.log('✅ Authentication functions available globally');
