-- Migration: Separate multi_channel_radio into its own table
-- Description: Creates dedicated multi_channel_radio and multi_channel_radio_items tables,
--              migrates existing data from curated_playlists, and removes the migrated rows.
--
-- HOW TO RUN:
--   1. Open your Supabase project dashboard
--   2. Navigate to SQL Editor
--   3. Paste this entire file and click Run
--   4. Verify the new tables exist and data was migrated correctly
--   5. Then deploy the updated application code

-- ============================================================
-- STEP 1: Create the multi_channel_radio table
-- ============================================================
CREATE TABLE IF NOT EXISTS multi_channel_radio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- STEP 2: Create the multi_channel_radio_items junction table
-- ============================================================
CREATE TABLE IF NOT EXISTS multi_channel_radio_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    multi_channel_radio_id UUID NOT NULL REFERENCES multi_channel_radio(id) ON DELETE CASCADE,
    station_id INTEGER REFERENCES radio_stations(id) ON DELETE CASCADE,
    external_station_id UUID REFERENCES external_stations(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure either station_id or external_station_id is set, but not both
    CONSTRAINT check_mcr_station_reference CHECK (
        (station_id IS NOT NULL AND external_station_id IS NULL) OR
        (station_id IS NULL AND external_station_id IS NOT NULL)
    )
);

-- ============================================================
-- STEP 3: Create indexes for performance
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_multi_channel_radio_sort_order
    ON multi_channel_radio(sort_order);

CREATE INDEX IF NOT EXISTS idx_multi_channel_radio_items_radio_id
    ON multi_channel_radio_items(multi_channel_radio_id);

CREATE INDEX IF NOT EXISTS idx_multi_channel_radio_items_station_id
    ON multi_channel_radio_items(station_id);

CREATE INDEX IF NOT EXISTS idx_multi_channel_radio_items_external_station_id
    ON multi_channel_radio_items(external_station_id);

-- ============================================================
-- STEP 4: Create updated_at trigger (matches curated_playlists pattern)
-- ============================================================
CREATE OR REPLACE FUNCTION update_multi_channel_radio_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_multi_channel_radio_timestamp
BEFORE UPDATE ON multi_channel_radio
FOR EACH ROW
EXECUTE FUNCTION update_multi_channel_radio_updated_at();

-- ============================================================
-- STEP 5: Enable Row Level Security
-- ============================================================
ALTER TABLE multi_channel_radio ENABLE ROW LEVEL SECURITY;
ALTER TABLE multi_channel_radio_items ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 6: Create RLS policies (mirrors curated_playlists policies)
-- ============================================================

-- Public read access
CREATE POLICY "Anyone can view multi_channel_radio"
ON multi_channel_radio FOR SELECT
USING (true);

CREATE POLICY "Anyone can view multi_channel_radio_items"
ON multi_channel_radio_items FOR SELECT
USING (true);

-- Authenticated write access (admin check enforced in application code)
CREATE POLICY "Authenticated users can insert multi_channel_radio"
ON multi_channel_radio FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated users can update multi_channel_radio"
ON multi_channel_radio FOR UPDATE
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can delete multi_channel_radio"
ON multi_channel_radio FOR DELETE
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can insert multi_channel_radio_items"
ON multi_channel_radio_items FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated users can update multi_channel_radio_items"
ON multi_channel_radio_items FOR UPDATE
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can delete multi_channel_radio_items"
ON multi_channel_radio_items FOR DELETE
TO authenticated
USING (true);

-- ============================================================
-- STEP 7: Migrate existing multi_channel_radio rows
-- ============================================================

-- Copy multi_channel_radio playlists from curated_playlists
-- (preserving the same UUIDs so existing references remain valid)
INSERT INTO multi_channel_radio (id, name, description, sort_order, created_at, updated_at)
SELECT id, name, description, sort_order, created_at, updated_at
FROM curated_playlists
WHERE type = 'multi_channel_radio';

-- Copy associated station items from curated_playlist_items
INSERT INTO multi_channel_radio_items (id, multi_channel_radio_id, station_id, external_station_id, sort_order, created_at)
SELECT id, curated_playlist_id, station_id, external_station_id, sort_order, created_at
FROM curated_playlist_items
WHERE curated_playlist_id IN (
    SELECT id FROM curated_playlists WHERE type = 'multi_channel_radio'
);

-- ============================================================
-- STEP 8: Remove migrated rows from the original tables
-- ============================================================

-- Delete items first (foreign key constraint)
DELETE FROM curated_playlist_items
WHERE curated_playlist_id IN (
    SELECT id FROM curated_playlists WHERE type = 'multi_channel_radio'
);

-- Delete the multi_channel_radio playlists from curated_playlists
DELETE FROM curated_playlists
WHERE type = 'multi_channel_radio';

-- ============================================================
-- STEP 9: Table comments for documentation
-- ============================================================
COMMENT ON TABLE multi_channel_radio IS 'Admin-curated multi-channel radio stations (e.g. KEXP, BBC Radio)';
COMMENT ON TABLE multi_channel_radio_items IS 'Junction table linking stations to multi-channel radio entries';
COMMENT ON COLUMN multi_channel_radio_items.station_id IS 'Reference to internal station (radio_stations table)';
COMMENT ON COLUMN multi_channel_radio_items.external_station_id IS 'Reference to external station from Radio Browser (external_stations table)';

-- ============================================================
-- VERIFICATION QUERIES (run these after the migration to confirm)
-- ============================================================
-- SELECT COUNT(*) FROM multi_channel_radio;           -- Should show your MCR count
-- SELECT COUNT(*) FROM multi_channel_radio_items;     -- Should show your MCR item count
-- SELECT COUNT(*) FROM curated_playlists WHERE type = 'multi_channel_radio';  -- Should be 0
