-- ============================================================================
-- StreamWave Radio - Complete Database Setup & User Authentication Migration
-- ============================================================================
-- This migration creates all necessary tables and sets up Row Level Security
-- to ensure each user has their own isolated playlists and data.
--
-- INSTRUCTIONS:
-- 1. Go to your Supabase Dashboard: https://zwrunupvlkhnwbylzizj.supabase.co
-- 2. Navigate to SQL Editor
-- 3. Create a new query and paste this entire file
-- 4. Run the migration
-- ============================================================================

-- ============================================================================
-- STEP 1: Create all necessary tables
-- ============================================================================

-- Create radio_stations table (shared across all users)
CREATE TABLE IF NOT EXISTS radio_stations (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    genre TEXT,
    country TEXT,
    language TEXT,
    logo_url TEXT,
    homepage_url TEXT,
    description TEXT,
    bitrate INTEGER,
    codec TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create playlists table (user-specific)
CREATE TABLE IF NOT EXISTS playlists (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create playlist_items junction table
CREATE TABLE IF NOT EXISTS playlist_items (
    id BIGSERIAL PRIMARY KEY,
    playlist_id BIGINT REFERENCES playlists(id) ON DELETE CASCADE NOT NULL,
    station_id BIGINT REFERENCES radio_stations(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(playlist_id, station_id)
);

-- Create liked_tracks table (user-specific)
CREATE TABLE IF NOT EXISTS liked_tracks (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    album TEXT,
    artwork_url TEXT,
    station_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create recent_tracks table (user-specific)
CREATE TABLE IF NOT EXISTS recent_tracks (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    album TEXT,
    artwork_url TEXT,
    station_name TEXT,
    played_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create station_history table (user-specific)
CREATE TABLE IF NOT EXISTS station_history (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    station_id BIGINT REFERENCES radio_stations(id) ON DELETE CASCADE NOT NULL,
    clicked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- STEP 2: Create indexes for better query performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON playlists(user_id);
CREATE INDEX IF NOT EXISTS idx_playlists_sort_order ON playlists(sort_order);
CREATE INDEX IF NOT EXISTS idx_playlist_items_playlist_id ON playlist_items(playlist_id);
CREATE INDEX IF NOT EXISTS idx_playlist_items_station_id ON playlist_items(station_id);
CREATE INDEX IF NOT EXISTS idx_liked_tracks_user_id ON liked_tracks(user_id);
CREATE INDEX IF NOT EXISTS idx_liked_tracks_created_at ON liked_tracks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recent_tracks_user_id ON recent_tracks(user_id);
CREATE INDEX IF NOT EXISTS idx_recent_tracks_played_at ON recent_tracks(played_at DESC);
CREATE INDEX IF NOT EXISTS idx_station_history_user_id ON station_history(user_id);
CREATE INDEX IF NOT EXISTS idx_station_history_station_id ON station_history(station_id);
CREATE INDEX IF NOT EXISTS idx_station_history_clicked_at ON station_history(clicked_at DESC);
CREATE INDEX IF NOT EXISTS idx_radio_stations_genre ON radio_stations(genre);
CREATE INDEX IF NOT EXISTS idx_radio_stations_name ON radio_stations(name);

-- ============================================================================
-- STEP 3: Enable Row Level Security (RLS) on all user-data tables
-- ============================================================================

ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE liked_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE recent_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE station_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE radio_stations ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 4: Drop existing policies (if any) to avoid conflicts
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own playlists" ON playlists;
DROP POLICY IF EXISTS "Users can create their own playlists" ON playlists;
DROP POLICY IF EXISTS "Users can update their own playlists" ON playlists;
DROP POLICY IF EXISTS "Users can delete their own playlists" ON playlists;

DROP POLICY IF EXISTS "Users can view their own playlist items" ON playlist_items;
DROP POLICY IF EXISTS "Users can create their own playlist items" ON playlist_items;
DROP POLICY IF EXISTS "Users can delete their own playlist items" ON playlist_items;

DROP POLICY IF EXISTS "Users can view their own liked tracks" ON liked_tracks;
DROP POLICY IF EXISTS "Users can create their own liked tracks" ON liked_tracks;
DROP POLICY IF EXISTS "Users can delete their own liked tracks" ON liked_tracks;

DROP POLICY IF EXISTS "Users can view their own recent tracks" ON recent_tracks;
DROP POLICY IF EXISTS "Users can create their own recent tracks" ON recent_tracks;
DROP POLICY IF EXISTS "Users can delete their own recent tracks" ON recent_tracks;

DROP POLICY IF EXISTS "Users can view their own station history" ON station_history;
DROP POLICY IF EXISTS "Users can create their own station history" ON station_history;
DROP POLICY IF EXISTS "Users can update their own station history" ON station_history;

DROP POLICY IF EXISTS "Users can view all radio stations" ON radio_stations;
DROP POLICY IF EXISTS "Users can create radio stations" ON radio_stations;
DROP POLICY IF EXISTS "Users can update radio stations" ON radio_stations;
DROP POLICY IF EXISTS "Users can delete radio stations" ON radio_stations;

DROP POLICY IF EXISTS "Anon users can view all radio stations" ON radio_stations;

-- ============================================================================
-- STEP 5: Create RLS Policies for PLAYLISTS
-- ============================================================================

-- Users can only view their own playlists
CREATE POLICY "Users can view their own playlists"
ON playlists FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Users can create their own playlists
CREATE POLICY "Users can create their own playlists"
ON playlists FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Users can update their own playlists
CREATE POLICY "Users can update their own playlists"
ON playlists FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Users can delete their own playlists
CREATE POLICY "Users can delete their own playlists"
ON playlists FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================================================
-- STEP 6: Create RLS Policies for PLAYLIST_ITEMS
-- ============================================================================

-- Users can only view playlist items from their own playlists
CREATE POLICY "Users can view their own playlist items"
ON playlist_items FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM playlists
    WHERE playlists.id = playlist_items.playlist_id
    AND playlists.user_id = auth.uid()
  )
);

-- Users can add items to their own playlists
CREATE POLICY "Users can create their own playlist items"
ON playlist_items FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM playlists
    WHERE playlists.id = playlist_items.playlist_id
    AND playlists.user_id = auth.uid()
  )
);

-- Users can delete items from their own playlists
CREATE POLICY "Users can delete their own playlist items"
ON playlist_items FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM playlists
    WHERE playlists.id = playlist_items.playlist_id
    AND playlists.user_id = auth.uid()
  )
);

-- ============================================================================
-- STEP 7: Create RLS Policies for LIKED_TRACKS
-- ============================================================================

-- Users can only view their own liked tracks
CREATE POLICY "Users can view their own liked tracks"
ON liked_tracks FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Users can add their own liked tracks
CREATE POLICY "Users can create their own liked tracks"
ON liked_tracks FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Users can delete their own liked tracks
CREATE POLICY "Users can delete their own liked tracks"
ON liked_tracks FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================================================
-- STEP 8: Create RLS Policies for RECENT_TRACKS
-- ============================================================================

-- Users can only view their own recent tracks
CREATE POLICY "Users can view their own recent tracks"
ON recent_tracks FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Users can add their own recent tracks
CREATE POLICY "Users can create their own recent tracks"
ON recent_tracks FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Users can delete their own recent tracks
CREATE POLICY "Users can delete their own recent tracks"
ON recent_tracks FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================================================
-- STEP 9: Create RLS Policies for STATION_HISTORY
-- ============================================================================

-- Users can only view their own station history
CREATE POLICY "Users can view their own station history"
ON station_history FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Users can add their own station history
CREATE POLICY "Users can create their own station history"
ON station_history FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Users can update their own station history
CREATE POLICY "Users can update their own station history"
ON station_history FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- STEP 10: Create RLS Policies for RADIO_STATIONS (Shared Resource)
-- ============================================================================

-- All authenticated users can view all radio stations
CREATE POLICY "Users can view all radio stations"
ON radio_stations FOR SELECT
TO authenticated
USING (true);

-- All authenticated users can create new radio stations
CREATE POLICY "Users can create radio stations"
ON radio_stations FOR INSERT
TO authenticated
WITH CHECK (true);

-- All authenticated users can update radio stations
CREATE POLICY "Users can update radio stations"
ON radio_stations FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- All authenticated users can delete radio stations
CREATE POLICY "Users can delete radio stations"
ON radio_stations FOR DELETE
TO authenticated
USING (true);

-- Anonymous users can view radio stations (for guest mode browsing)
CREATE POLICY "Anon users can view all radio stations"
ON radio_stations FOR SELECT
TO anon
USING (true);

-- ============================================================================
-- STEP 11: Grant necessary permissions
-- ============================================================================

-- Grant usage on public schema
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

-- Grant permissions on tables
GRANT ALL ON playlists TO authenticated;
GRANT ALL ON playlist_items TO authenticated;
GRANT ALL ON liked_tracks TO authenticated;
GRANT ALL ON recent_tracks TO authenticated;
GRANT ALL ON station_history TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON radio_stations TO authenticated;
GRANT SELECT ON radio_stations TO anon;

-- Grant permissions on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- ============================================================================
-- STEP 12: Create updated_at trigger function (optional but recommended)
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at columns
DROP TRIGGER IF EXISTS update_playlists_updated_at ON playlists;
CREATE TRIGGER update_playlists_updated_at
    BEFORE UPDATE ON playlists
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_radio_stations_updated_at ON radio_stations;
CREATE TRIGGER update_radio_stations_updated_at
    BEFORE UPDATE ON radio_stations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- After running this migration:
-- 1. All necessary tables are created
-- 2. Each user has their own isolated playlists, liked tracks, and history
-- 3. Radio stations are shared across all users
-- 4. Guest users can browse stations (anon access)
-- 5. When guests sign up, their data will be migrated with their user_id
-- ============================================================================

-- Verify migration
SELECT
  'Migration completed successfully!' as status,
  NOW() as completed_at;

-- Show table counts
SELECT
  'radio_stations' as table_name,
  COUNT(*) as record_count
FROM radio_stations
UNION ALL
SELECT 'playlists', COUNT(*) FROM playlists
UNION ALL
SELECT 'playlist_items', COUNT(*) FROM playlist_items
UNION ALL
SELECT 'liked_tracks', COUNT(*) FROM liked_tracks
UNION ALL
SELECT 'recent_tracks', COUNT(*) FROM recent_tracks
UNION ALL
SELECT 'station_history', COUNT(*) FROM station_history
ORDER BY table_name;
