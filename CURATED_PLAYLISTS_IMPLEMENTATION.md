# Curated Playlists Feature Implementation Guide

## Overview
This document describes the new **Curated Playlists** and **Multi-Channel Internet Radio Stations** feature that allows admins to create curated collections of radio stations displayed in carousel format at the top of the Browse Stations modal.

## Feature Description

### Two Types of Curated Collections:

1. **Curated Playlists** - Thematic collections displayed with a collage of station icons (e.g., "Jazz Essentials", "Classical Music Collection")
2. **Multi-Channel Internet Radio Stations** - Single broadcaster with multiple channels displayed with one station icon (e.g., "KEXP", "BBC Radio")

## What's Been Implemented ✅

### 1. Database Schema (`migrations/curated_playlists.sql`)

**Tables Created:**
- `curated_playlists` - Stores playlist metadata
  - `id` (UUID, primary key)
  - `name` (TEXT) - Display name
  - `type` (ENUM: 'curated_playlist' or 'multi_channel_radio')
  - `description` (TEXT) - Optional description
  - `sort_order` (INTEGER) - Display order
  - `created_at`, `updated_at` (TIMESTAMP)

- `curated_playlist_items` - Junction table linking stations to playlists
  - `id` (UUID, primary key)
  - `curated_playlist_id` (UUID, foreign key)
  - `station_id` (INTEGER, foreign key to radio_stations)
  - `external_station_id` (INTEGER, foreign key to external_stations)
  - `sort_order` (INTEGER) - Order within playlist
  - `created_at` (TIMESTAMP)
  - Constraint: Either station_id OR external_station_id must be set (not both)

**Features:**
- Row Level Security (RLS) enabled
- Public read access for all users
- Write access for authenticated users (admin check in app layer)
- Automatic updated_at timestamp trigger
- Sample data included (4 example playlists)

### 2. Frontend UI

**New HTML Elements:**
- Two carousel sections at top of Browse Stations modal (index.html:636-654):
  - `curatedPlaylistsSection` - Shows Curated Playlists with collage
  - `multiChannelRadioSection` - Shows Multi-Channel Radio stations

**State Management:**
- Added `curatedPlaylists` array (index.html:1111)
- Tracks loaded curated playlists in memory

**Functions Created:**

1. **`loadCuratedPlaylists()`** (index.html:3105-3125)
   - Fetches all curated playlists from database
   - Orders by sort_order then created_at
   - Calls renderCuratedPlaylistsInBrowseModal()

2. **`renderCuratedPlaylistsInBrowseModal()`** (index.html:3127-3163)
   - Separates playlists by type
   - Loads first 4 stations for each playlist (for collage)
   - Renders both carousels
   - Shows/hides sections based on data availability

3. **`loadCuratedPlaylistStations()`** (index.html:3165-3212)
   - Loads stations for a single curated playlist
   - Handles both internal (radio_stations) and external (external_stations) stations
   - Returns playlist with stations array

4. **`openCuratedPlaylist()`** (index.html:4754-4768)
   - Opens a curated playlist in the playlist modal
   - Sets currentPlaylist with is_curated flag
   - Calls loadCuratedPlaylistStationsForModal()

5. **`loadCuratedPlaylistStationsForModal()`** (index.html:4770-4812)
   - Loads ALL stations for a curated playlist (not just 4)
   - Populates playlistStations array
   - Calls renderPlaylistStations()

**Updated Functions:**

1. **`renderCarousel()`** (index.html:3432-3491)
   - Now handles 'curated-playlist' type
   - Creates collage for multi-station playlists
   - Shows single icon for single-station playlists
   - Adds data-playlist-type attribute
   - Handles click events to open curated playlists

2. **Bottom Nav Handler** (index.html:5383-5406)
   - Calls `loadCuratedPlaylists()` when opening Browse Stations modal
   - Ensures carousels are populated

## What Still Needs to Be Implemented ❌

### 1. Admin-Only "Add to Curated Playlist" Options

**Location 1: Curated Stations Dropdown**
- File: `index.html`, around line 4062-4075
- Add dropdown menu item: "Add to Curated Playlist"
- Only show if user is admin (check: `window.currentUser.email.split('@')[0] === 'keith.e.dragon'`)
- Should open curated playlist selector modal

**Location 2: Radio Database Search Results Dropdown**
- File: `index.html`, around line 2115-2157
- Add dropdown menu item: "Add to Curated Playlist"
- Only show if user is admin
- Should open curated playlist selector modal

### 2. Curated Playlist Selector Modal

**Create New Modal HTML:**
```html
<!-- Curated Playlist Selector Modal -->
<div id="curatedPlaylistSelectorModal" class="modal-overlay">
    <div class="modal-content" style="max-width: 500px;">
        <div class="modal-header">
            <h2 class="modal-title">Add to Curated Playlist</h2>
            <button class="modal-close" id="closeCuratedPlaylistSelectorModal">&times;</button>
        </div>
        <div class="modal-body">
            <div id="curatedPlaylistSelectorList" class="playlist-selector-list"></div>
            <button id="createNewCuratedPlaylistBtn" class="form-btn form-btn-primary" style="width: 100%; margin-top: 16px;">
                ➕ Create New Curated Playlist
            </button>
        </div>
    </div>
</div>
```

**Functions Needed:**
1. `showCuratedPlaylistSelectorForStation(station)` - Opens selector modal
2. `renderCuratedPlaylistSelector()` - Renders list of curated playlists
3. `addStationToCuratedPlaylist(station, curatedPlaylistId)` - Adds station to playlist

### 3. Curated Playlist Management UI (Admin Only)

**Create New Modal HTML:**
```html
<!-- Curated Playlist Form Modal -->
<div id="curatedPlaylistFormModal" class="modal-overlay">
    <div class="modal-content" style="max-width: 500px;">
        <div class="modal-header">
            <h2 class="modal-title" id="curatedPlaylistFormTitle">Create Curated Playlist</h2>
            <button class="modal-close" id="closeCuratedPlaylistFormModal">&times;</button>
        </div>
        <div class="modal-body">
            <form id="curatedPlaylistForm">
                <div class="form-group">
                    <label for="curatedPlaylistName">Playlist Name *</label>
                    <input type="text" id="curatedPlaylistName" required>
                </div>
                <div class="form-group">
                    <label for="curatedPlaylistType">Type *</label>
                    <select id="curatedPlaylistType" required>
                        <option value="curated_playlist">Curated Playlist (shows collage)</option>
                        <option value="multi_channel_radio">Multi-Channel Radio (shows single icon)</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="curatedPlaylistDescription">Description</label>
                    <textarea id="curatedPlaylistDescription" rows="3"></textarea>
                </div>
                <div class="form-actions">
                    <button type="button" class="form-btn form-btn-secondary" id="cancelCuratedPlaylistFormBtn">Cancel</button>
                    <button type="submit" class="form-btn form-btn-primary">Save</button>
                </div>
            </form>
        </div>
    </div>
</div>
```

**Functions Needed:**
1. `showCuratedPlaylistForm(id = null)` - Open form for create/edit
2. `saveCuratedPlaylist()` - Save new or update existing playlist
3. `deleteCuratedPlaylist(id)` - Delete playlist
4. Admin menu in playlist modal to edit/delete curated playlists

### 4. Admin Navigation/Management

**Option A: Add to Hamburger Menu (for admins only)**
- "Manage Curated Playlists" menu item
- Opens modal showing all curated playlists with edit/delete options

**Option B: Add Context Menu to Carousels**
- Admin-only edit/delete buttons on carousel items
- Inline management

## Database Migration Instructions

**Step 1: Run the SQL Migration**
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Open the file: `migrations/curated_playlists.sql`
4. Execute the entire script

**Step 2: Verify Tables Created**
```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('curated_playlists', 'curated_playlist_items');

-- Check sample data
SELECT * FROM curated_playlists;
```

**Step 3: Test Permissions**
- As a non-admin user: Try to read curated playlists (should work)
- As admin user: Try to create/update playlists (should work)

## Testing the Current Implementation

1. **Run the SQL migration** in Supabase
2. **Refresh the app** and open Browse Stations modal
3. **Verify** you see two new carousel sections at the top:
   - "Curated Playlists" (with sample playlists if you kept the sample data)
   - "Multi-Channel Internet Radio Stations"
4. **Click on a carousel item** to open the curated playlist
5. **Verify** the playlist modal opens showing stations from that curated playlist

## Implementation Priority

**High Priority (Core Functionality):**
1. ✅ Database schema (DONE)
2. ✅ Load and display carousels (DONE)
3. ✅ Open curated playlists (DONE)
4. ❌ Add stations to curated playlists (TODO - this is critical for admins)
5. ❌ Create new curated playlists (TODO)

**Medium Priority (Admin Convenience):**
6. ❌ Edit existing curated playlists
7. ❌ Delete curated playlists
8. ❌ Reorder stations within playlists
9. ❌ Reorder playlists themselves

**Low Priority (Nice to Have):**
10. ❌ Duplicate playlists
11. ❌ Export/import playlists
12. ❌ Playlist analytics (view counts)

## Code Locations Reference

### HTML
- Carousel sections: `index.html:636-654`
- (Need to add: Selector modal, Form modal)

### JavaScript State
- State variable: `index.html:1111`

### JavaScript Functions
- Load functions: `index.html:3105-3212`
- Render functions: `index.html:3127-3163`
- Open functions: `index.html:4754-4812`
- Carousel rendering: `index.html:3432-3491`
- Modal opener: `index.html:5383-5406`

### Database
- Migration script: `migrations/curated_playlists.sql`
- Tables: `curated_playlists`, `curated_playlist_items`

## Notes

- The current implementation reuses the existing playlist modal UI for displaying curated playlists
- Curated playlists can contain both internal stations (from radio_stations) and external stations (from external_stations/radio-browser)
- The collage shows up to 4 station icons
- Pagination is NOT applied to curated playlist carousels (they show all items)
- The carousel navigation (left/right arrows) is handled by existing `setupCarouselNavigation()` function

## Questions?

If you have questions about this implementation or need help completing the remaining tasks, refer to:
- Existing playlist code patterns (for UI consistency)
- Admin check: `window.currentUser.email.split('@')[0] === 'keith.e.dragon'`
- Modal patterns: See existing modals like playlistSelectorModal, playlistFormModal
