-- Migration: Create curated playlists tables
-- Description: Adds tables for admin-curated playlists and multi-channel radio stations

-- Create enum type for curated playlist types
CREATE TYPE curated_playlist_type AS ENUM ('curated_playlist', 'multi_channel_radio');

-- Create curated_playlists table
CREATE TABLE curated_playlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type curated_playlist_type NOT NULL DEFAULT 'curated_playlist',
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create curated_playlist_items table (junction table linking stations to curated playlists)
CREATE TABLE curated_playlist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    curated_playlist_id UUID NOT NULL REFERENCES curated_playlists(id) ON DELETE CASCADE,
    station_id INTEGER REFERENCES radio_stations(id) ON DELETE CASCADE,
    external_station_id INTEGER REFERENCES external_stations(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure either station_id or external_station_id is set, but not both
    CONSTRAINT check_station_reference CHECK (
        (station_id IS NOT NULL AND external_station_id IS NULL) OR
        (station_id IS NULL AND external_station_id IS NOT NULL)
    )
);

-- Create indexes for better query performance
CREATE INDEX idx_curated_playlists_type ON curated_playlists(type);
CREATE INDEX idx_curated_playlists_sort_order ON curated_playlists(sort_order);
CREATE INDEX idx_curated_playlist_items_playlist_id ON curated_playlist_items(curated_playlist_id);
CREATE INDEX idx_curated_playlist_items_station_id ON curated_playlist_items(station_id);
CREATE INDEX idx_curated_playlist_items_external_station_id ON curated_playlist_items(external_station_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_curated_playlist_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_update_curated_playlist_timestamp
BEFORE UPDATE ON curated_playlists
FOR EACH ROW
EXECUTE FUNCTION update_curated_playlist_updated_at();

-- Enable Row Level Security (RLS)
ALTER TABLE curated_playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE curated_playlist_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Everyone can read curated playlists
CREATE POLICY "Anyone can view curated playlists"
ON curated_playlists FOR SELECT
USING (true);

CREATE POLICY "Anyone can view curated playlist items"
ON curated_playlist_items FOR SELECT
USING (true);

-- RLS Policies: Only authenticated users can modify (we'll handle admin check in app)
-- Note: You may want to create a custom function to check if user is admin
CREATE POLICY "Authenticated users can insert curated playlists"
ON curated_playlists FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated users can update curated playlists"
ON curated_playlists FOR UPDATE
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can delete curated playlists"
ON curated_playlists FOR DELETE
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can insert curated playlist items"
ON curated_playlist_items FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated users can update curated playlist items"
ON curated_playlist_items FOR UPDATE
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can delete curated playlist items"
ON curated_playlist_items FOR DELETE
TO authenticated
USING (true);

-- Insert some example curated playlists (optional - you can remove these)
INSERT INTO curated_playlists (name, type, description, sort_order) VALUES
    ('Jazz Essentials', 'curated_playlist', 'The best jazz stations from around the world', 0),
    ('Classical Music Collection', 'curated_playlist', 'Premium classical music stations', 1),
    ('KEXP', 'multi_channel_radio', 'Seattle-based independent radio with multiple channels', 0),
    ('BBC Radio', 'multi_channel_radio', 'British Broadcasting Corporation radio channels', 1);

-- Comments for documentation
COMMENT ON TABLE curated_playlists IS 'Admin-curated collections of radio stations';
COMMENT ON TABLE curated_playlist_items IS 'Junction table linking stations to curated playlists';
COMMENT ON COLUMN curated_playlists.type IS 'Type: curated_playlist (shows as playlist with collage) or multi_channel_radio (shows as single station icon)';
COMMENT ON COLUMN curated_playlist_items.station_id IS 'Reference to internal curated station (radio_stations table)';
COMMENT ON COLUMN curated_playlist_items.external_station_id IS 'Reference to external station from Radio Browser (external_stations table)';
