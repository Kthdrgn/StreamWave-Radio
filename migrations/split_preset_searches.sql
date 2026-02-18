-- Migration: Split preset_searches into three dedicated tables
-- Description:
--   name_preset_searches  → Quick Search by station name (station_name IS NOT NULL)
--   tag_preset_searches   → Quick Search by genre/tag  (tags IS NOT NULL, station_name IS NULL)
--   decade_preset_searches→ Decade browsing (new section, starts empty)
--
-- HOW TO RUN:
--   1. Open your Supabase project dashboard
--   2. Navigate to SQL Editor
--   3. Paste this entire file and click Run
--   4. Then deploy the updated application code
--   5. After verifying everything works, you can drop the old preset_searches table

-- ============================================================
-- STEP 1: Create name_preset_searches table
-- ============================================================
CREATE TABLE IF NOT EXISTS name_preset_searches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    station_name TEXT,
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

-- ============================================================
-- STEP 2: Create tag_preset_searches table
-- ============================================================
CREATE TABLE IF NOT EXISTS tag_preset_searches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    station_name TEXT,
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

-- ============================================================
-- STEP 3: Create decade_preset_searches table
-- ============================================================
CREATE TABLE IF NOT EXISTS decade_preset_searches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    station_name TEXT,
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

-- ============================================================
-- STEP 4: Indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_name_preset_searches_display_order
    ON name_preset_searches(display_order);

CREATE INDEX IF NOT EXISTS idx_tag_preset_searches_display_order
    ON tag_preset_searches(display_order);

CREATE INDEX IF NOT EXISTS idx_decade_preset_searches_display_order
    ON decade_preset_searches(display_order);

-- ============================================================
-- STEP 5: updated_at triggers (mirrors preset_searches pattern)
-- ============================================================
CREATE OR REPLACE FUNCTION update_name_preset_searches_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_name_preset_searches_updated_at
    BEFORE UPDATE ON name_preset_searches
    FOR EACH ROW EXECUTE FUNCTION update_name_preset_searches_updated_at();

CREATE OR REPLACE FUNCTION update_tag_preset_searches_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tag_preset_searches_updated_at
    BEFORE UPDATE ON tag_preset_searches
    FOR EACH ROW EXECUTE FUNCTION update_tag_preset_searches_updated_at();

CREATE OR REPLACE FUNCTION update_decade_preset_searches_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_decade_preset_searches_updated_at
    BEFORE UPDATE ON decade_preset_searches
    FOR EACH ROW EXECUTE FUNCTION update_decade_preset_searches_updated_at();

-- ============================================================
-- STEP 6: Row Level Security
-- ============================================================
ALTER TABLE name_preset_searches   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_preset_searches    ENABLE ROW LEVEL SECURITY;
ALTER TABLE decade_preset_searches ENABLE ROW LEVEL SECURITY;

-- Public read
CREATE POLICY "Allow public read access to name_preset_searches"
    ON name_preset_searches FOR SELECT USING (true);

CREATE POLICY "Allow public read access to tag_preset_searches"
    ON tag_preset_searches FOR SELECT USING (true);

CREATE POLICY "Allow public read access to decade_preset_searches"
    ON decade_preset_searches FOR SELECT USING (true);

-- Admin write (name)
CREATE POLICY "Allow admin to insert name_preset_searches"
    ON name_preset_searches FOR INSERT
    WITH CHECK (auth.email() = 'keith.e.dragon@gmail.com');

CREATE POLICY "Allow admin to update name_preset_searches"
    ON name_preset_searches FOR UPDATE
    USING (auth.email() = 'keith.e.dragon@gmail.com');

CREATE POLICY "Allow admin to delete name_preset_searches"
    ON name_preset_searches FOR DELETE
    USING (auth.email() = 'keith.e.dragon@gmail.com');

-- Admin write (tag)
CREATE POLICY "Allow admin to insert tag_preset_searches"
    ON tag_preset_searches FOR INSERT
    WITH CHECK (auth.email() = 'keith.e.dragon@gmail.com');

CREATE POLICY "Allow admin to update tag_preset_searches"
    ON tag_preset_searches FOR UPDATE
    USING (auth.email() = 'keith.e.dragon@gmail.com');

CREATE POLICY "Allow admin to delete tag_preset_searches"
    ON tag_preset_searches FOR DELETE
    USING (auth.email() = 'keith.e.dragon@gmail.com');

-- Admin write (decade)
CREATE POLICY "Allow admin to insert decade_preset_searches"
    ON decade_preset_searches FOR INSERT
    WITH CHECK (auth.email() = 'keith.e.dragon@gmail.com');

CREATE POLICY "Allow admin to update decade_preset_searches"
    ON decade_preset_searches FOR UPDATE
    USING (auth.email() = 'keith.e.dragon@gmail.com');

CREATE POLICY "Allow admin to delete decade_preset_searches"
    ON decade_preset_searches FOR DELETE
    USING (auth.email() = 'keith.e.dragon@gmail.com');

-- ============================================================
-- STEP 7: Migrate existing data from preset_searches
-- Rows with station_name  → name_preset_searches
-- Remaining rows with tags → tag_preset_searches
-- decade_preset_searches   → starts empty (create via admin UI)
-- ============================================================
INSERT INTO name_preset_searches
    (id, name, station_name, country, language, tags, image_url, description, display_order, created_at, updated_at, created_by)
SELECT
    id, name, station_name, country, language, tags, image_url, description, display_order, created_at, updated_at, created_by
FROM preset_searches
WHERE station_name IS NOT NULL AND station_name <> '';

INSERT INTO tag_preset_searches
    (id, name, station_name, country, language, tags, image_url, description, display_order, created_at, updated_at, created_by)
SELECT
    id, name, station_name, country, language, tags, image_url, description, display_order, created_at, updated_at, created_by
FROM preset_searches
WHERE (station_name IS NULL OR station_name = '')
  AND tags IS NOT NULL AND tags <> '';

-- ============================================================
-- STEP 8: (Optional) Drop the old preset_searches table
-- Run this ONLY after confirming the new tables work correctly:
--
-- DROP TABLE IF EXISTS preset_searches;
-- ============================================================

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================
-- SELECT COUNT(*) FROM name_preset_searches;    -- name-based presets
-- SELECT COUNT(*) FROM tag_preset_searches;     -- tag-based presets
-- SELECT COUNT(*) FROM decade_preset_searches;  -- should be 0 (fill via admin UI)
