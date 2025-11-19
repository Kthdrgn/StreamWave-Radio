-- Station Metadata Table
-- This table stores the last known metadata (currently playing song) for each station per user

CREATE TABLE IF NOT EXISTS station_metadata (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    station_id INTEGER NOT NULL,
    title TEXT,
    artist TEXT,
    album TEXT,
    artwork_url TEXT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, station_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_station_metadata_user_station
    ON station_metadata(user_id, station_id);

-- Add RLS (Row Level Security) policies
ALTER TABLE station_metadata ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own metadata
CREATE POLICY "Users can view their own station metadata"
    ON station_metadata FOR SELECT
    USING (auth.uid()::text = user_id);

-- Policy: Users can insert their own metadata
CREATE POLICY "Users can insert their own station metadata"
    ON station_metadata FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

-- Policy: Users can update their own metadata
CREATE POLICY "Users can update their own station metadata"
    ON station_metadata FOR UPDATE
    USING (auth.uid()::text = user_id);

-- Policy: Users can delete their own metadata
CREATE POLICY "Users can delete their own station metadata"
    ON station_metadata FOR DELETE
    USING (auth.uid()::text = user_id);
