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
    if (window.isAuthenticated && window.currentUser) {
        // Show user email indicator
        const userEmail = window.currentUser.email;
        const displayName = userEmail.split('@')[0];
        
        // Add user indicator
        if (!document.getElementById('userIndicator')) {
            const userIndicator = document.createElement('div');
            userIndicator.id = 'userIndicator';
            userIndicator.style.cssText = 'position: fixed; top: 20px; right: 80px; color: var(--text-secondary); font-size: 12px; z-index: 1000; background: var(--bg-secondary); padding: 8px 12px; border-radius: 8px; border: 1px solid var(--border-color);';
            userIndicator.innerHTML = `👤 ${displayName}`;
            document.body.appendChild(userIndicator);
        }
    } else {
        // Remove user indicator if it exists
        const userIndicator = document.getElementById('userIndicator');
        if (userIndicator) {
            userIndicator.remove();
        }
    }
    
    // Update auth button
    updateAuthButton();
}

// Update auth button text
function updateAuthButton() {
    const authBtnText = document.getElementById('authBtnText');
    if (authBtnText) {
        if (window.isAuthenticated && window.currentUser) {
            authBtnText.textContent = '🚪 Sign Out';
        } else {
            authBtnText.textContent = '🔐 Sign In';
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
            .single();
        
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
        
        // Remove if already exists
        const filteredTracks = recentTracks.filter(track => 
            !(track.title === trackInfo.title && track.artist === trackInfo.artist)
        );
        
        const newTrack = {
            title: trackInfo.title,
            artist: trackInfo.artist,
            album: trackInfo.album || '',
            artworkUrl: trackInfo.artworkUrl || '',
            station: trackInfo.station || 'Unknown Station',
            timestamp: new Date().toISOString()
        };
        
        filteredTracks.unshift(newTrack);
        const limitedTracks = filteredTracks.slice(0, 15);
        saveRecentTracks(limitedTracks);
    } else {
        // Authenticated - insert to Supabase
        // Delete existing entry for this track (to move it to top)
        await supabaseClient
            .from('recent_tracks')
            .delete()
            .eq('user_id', window.currentUser.id)
            .eq('title', trackInfo.title)
            .eq('artist', trackInfo.artist);
        
        // Insert new entry
        const { error } = await supabaseClient
            .from('recent_tracks')
            .insert([{
                user_id: window.currentUser.id,
                title: trackInfo.title,
                artist: trackInfo.artist,
                album: trackInfo.album || '',
                artwork_url: trackInfo.artworkUrl || '',
                station_name: trackInfo.station || 'Unknown Station'
            }]);
        
        if (error) {
            console.error('Error saving recent track:', error);
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
window.normalizeTrack = normalizeTrack;
window.supabaseClient = supabaseClient;

console.log('✅ Authentication functions available globally');
