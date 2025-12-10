-- Preset Searches Table
-- This table stores preset search criteria for the Radio Database
-- Each preset will be displayed as a button in the Discover modal carousel

CREATE TABLE preset_searches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    country TEXT,
    language TEXT,
    tags TEXT,
    image_url TEXT,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Index for faster ordering
CREATE INDEX idx_preset_searches_display_order ON preset_searches(display_order);

-- Enable Row Level Security
ALTER TABLE preset_searches ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can read preset searches
CREATE POLICY "Allow public read access to preset searches"
    ON preset_searches
    FOR SELECT
    USING (true);

-- Policy: Only authenticated users with admin email can insert
CREATE POLICY "Allow admin to insert preset searches"
    ON preset_searches
    FOR INSERT
    WITH CHECK (
        auth.email() = 'keith.e.dragon@gmail.com'
    );

-- Policy: Only authenticated users with admin email can update
CREATE POLICY "Allow admin to update preset searches"
    ON preset_searches
    FOR UPDATE
    USING (
        auth.email() = 'keith.e.dragon@gmail.com'
    );

-- Policy: Only authenticated users with admin email can delete
CREATE POLICY "Allow admin to delete preset searches"
    ON preset_searches
    FOR DELETE
    USING (
        auth.email() = 'keith.e.dragon@gmail.com'
    );

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_preset_searches_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER trigger_update_preset_searches_updated_at
    BEFORE UPDATE ON preset_searches
    FOR EACH ROW
    EXECUTE FUNCTION update_preset_searches_updated_at();

-- Sample data (optional - you can remove this if you want to start with an empty table)
INSERT INTO preset_searches (name, country, language, tags, description, display_order)
VALUES
    ('Rock Music', NULL, 'english', 'rock', 'Popular rock music stations from around the world', 1),
    ('Jazz Stations', NULL, NULL, 'jazz', 'Smooth jazz and contemporary jazz stations', 2),
    ('USA Radio', 'United States', NULL, NULL, 'Radio stations from the United States', 3),
    ('UK Radio', 'United Kingdom', 'english', NULL, 'British radio stations', 4);
