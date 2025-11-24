-- Migration: Add External Stations Support for Radio Browser Integration
-- This migration creates a new table for external stations (radio-browser.info)
-- and modifies existing tables to support both internal and external stations

-- ============================================================================
-- 1. Create external_stations table
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.external_stations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source VARCHAR(50) NOT NULL DEFAULT 'radio-browser',
    external_id VARCHAR(255), -- The station's ID from the external service (e.g., radio-browser stationuuid)
    name VARCHAR(255) NOT NULL,
    url TEXT NOT NULL,
    url_resolved TEXT, -- The actual streaming URL after redirects
    icon_url TEXT,
    favicon TEXT, -- Alternative to icon_url for radio-browser
    genres TEXT[], -- Array of genre/tag strings
    country VARCHAR(100),
    country_code VARCHAR(10),
    language VARCHAR(100),
    bitrate INTEGER,
    votes INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,
    codec VARCHAR(50),
    homepage TEXT,
    metadata JSONB, -- Store any additional metadata from the external service
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure we don't duplicate stations from the same source
    UNIQUE(source, external_id)
);

-- Add index for faster lookups
CREATE INDEX idx_external_stations_source ON public.external_stations(source);
CREATE INDEX idx_external_stations_external_id ON public.external_stations(external_id);
CREATE INDEX idx_external_stations_name ON public.external_stations(name);

-- Add RLS (Row Level Security) policies
ALTER TABLE public.external_stations ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read external stations
CREATE POLICY "Allow authenticated users to read external stations"
    ON public.external_stations
    FOR SELECT
    TO authenticated
    USING (true);

-- Allow all authenticated users to insert external stations
CREATE POLICY "Allow authenticated users to insert external stations"
    ON public.external_stations
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ============================================================================
-- 2. Modify playlist_items table
-- ============================================================================

-- Add external_station_id column
ALTER TABLE public.playlist_items
ADD COLUMN IF NOT EXISTS external_station_id UUID REFERENCES public.external_stations(id) ON DELETE CASCADE;

-- Add constraint: either station_id OR external_station_id must be set, but not both
ALTER TABLE public.playlist_items
DROP CONSTRAINT IF EXISTS playlist_items_station_check;

ALTER TABLE public.playlist_items
ADD CONSTRAINT playlist_items_station_check CHECK (
    (station_id IS NOT NULL AND external_station_id IS NULL) OR
    (station_id IS NULL AND external_station_id IS NOT NULL)
);

-- Add index for external station lookups
CREATE INDEX IF NOT EXISTS idx_playlist_items_external_station_id
ON public.playlist_items(external_station_id);

-- ============================================================================
-- 3. Modify station_history table
-- ============================================================================

-- Add external_station_id column
ALTER TABLE public.station_history
ADD COLUMN IF NOT EXISTS external_station_id UUID REFERENCES public.external_stations(id) ON DELETE CASCADE;

-- Add constraint: either station_id OR external_station_id must be set, but not both
ALTER TABLE public.station_history
DROP CONSTRAINT IF EXISTS station_history_station_check;

ALTER TABLE public.station_history
ADD CONSTRAINT station_history_station_check CHECK (
    (station_id IS NOT NULL AND external_station_id IS NULL) OR
    (station_id IS NULL AND external_station_id IS NOT NULL)
);

-- Add index for external station lookups
CREATE INDEX IF NOT EXISTS idx_station_history_external_station_id
ON public.station_history(external_station_id);

-- ============================================================================
-- 4. Create helper function to get station details (internal or external)
-- ============================================================================

-- This function will be useful for queries that need to work with both types
CREATE OR REPLACE FUNCTION public.get_combined_station_info(
    p_station_id INTEGER DEFAULT NULL,
    p_external_station_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id TEXT,
    name VARCHAR,
    url TEXT,
    icon_url TEXT,
    genres TEXT[],
    country VARCHAR,
    is_external BOOLEAN
) AS $$
BEGIN
    IF p_station_id IS NOT NULL THEN
        RETURN QUERY
        SELECT
            p_station_id::TEXT as id,
            rs.name,
            rs.url,
            rs.icon_url,
            rs.genres,
            ''::VARCHAR as country,
            false as is_external
        FROM public.radio_stations rs
        WHERE rs.id = p_station_id;
    ELSIF p_external_station_id IS NOT NULL THEN
        RETURN QUERY
        SELECT
            es.id::TEXT as id,
            es.name,
            COALESCE(es.url_resolved, es.url) as url,
            COALESCE(es.icon_url, es.favicon) as icon_url,
            es.genres,
            es.country,
            true as is_external
        FROM public.external_stations es
        WHERE es.id = p_external_station_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. Update updated_at trigger for external_stations
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_external_stations_updated_at ON public.external_stations;

CREATE TRIGGER update_external_stations_updated_at
    BEFORE UPDATE ON public.external_stations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. Comments for documentation
-- ============================================================================

COMMENT ON TABLE public.external_stations IS 'Stores stations from external services like radio-browser.info that are not part of the main radio_stations database';
COMMENT ON COLUMN public.external_stations.source IS 'The external service this station came from (e.g., radio-browser, tunein, etc.)';
COMMENT ON COLUMN public.external_stations.external_id IS 'The unique identifier from the external service';
COMMENT ON COLUMN public.external_stations.metadata IS 'JSONB field for storing any additional service-specific metadata';

-- ============================================================================
-- Migration Complete
-- ============================================================================
-- After running this migration, you can:
-- 1. Add radio-browser.info stations directly to playlists
-- 2. Track external stations in station_history (Recent Stations)
-- 3. Keep the main radio_stations table clean for curated/local stations
