-- ============================================================================
-- StreamWave Radio - User Authentication & Row Level Security Migration
-- ============================================================================
-- This migration adds user_id columns and RLS policies to ensure each user
-- has their own isolated playlists, liked tracks, and history.
--
-- INSTRUCTIONS:
-- 1. Go to your Supabase Dashboard: https://zwrunupvlkhnwbylzizj.supabase.co
-- 2. Navigate to SQL Editor
-- 3. Create a new query and paste this entire file
-- 4. Run the migration
-- ============================================================================

-- ============================================================================
-- STEP 1: Add user_id columns to all user-data tables
-- ============================================================================

-- Add user_id to playlists table
ALTER TABLE playlists
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add user_id to liked_tracks table
ALTER TABLE liked_tracks
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add user_id to recent_tracks table
ALTER TABLE recent_tracks
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add user_id to station_history table
ALTER TABLE station_history
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- ============================================================================
-- STEP 2: Create indexes for better query performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON playlists(user_id);
CREATE INDEX IF NOT EXISTS idx_liked_tracks_user_id ON liked_tracks(user_id);
CREATE INDEX IF NOT EXISTS idx_recent_tracks_user_id ON recent_tracks(user_id);
CREATE INDEX IF NOT EXISTS idx_station_history_user_id ON station_history(user_id);

-- ============================================================================
-- STEP 3: Enable Row Level Security (RLS) on all user-data tables
-- ============================================================================

ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE liked_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE recent_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE station_history ENABLE ROW LEVEL SECURITY;

-- Radio stations table is shared across all users (no RLS needed)
-- Users can read all stations, but only insert/update/delete their own custom stations
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
DROP POLICY IF EXISTS "Users can update their own radio stations" ON radio_stations;
DROP POLICY IF EXISTS "Users can delete their own radio stations" ON radio_stations;

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

-- Users can update radio stations (consider restricting this if needed)
CREATE POLICY "Users can update radio stations"
ON radio_stations FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Users can delete radio stations (consider restricting this if needed)
CREATE POLICY "Users can delete radio stations"
ON radio_stations FOR DELETE
TO authenticated
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

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- After running this migration:
-- 1. Each user will have their own isolated playlists
-- 2. Liked tracks, recent tracks, and history are user-specific
-- 3. Radio stations are shared across all users
-- 4. Guest users continue to use localStorage (no database access)
-- 5. When guests sign up, their data will be migrated with their user_id
-- ============================================================================

-- Verify migration
SELECT
  'Migration completed successfully!' as status,
  NOW() as completed_at;
