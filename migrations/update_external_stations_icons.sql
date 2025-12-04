-- Migration: Update existing external_stations to populate icon_url from favicon
-- This fixes the issue where stations added before the icon_url field was added
-- don't have their icons displayed in playlists and recently played sections

-- ============================================================================
-- Update icon_url from favicon for existing records
-- ============================================================================

-- Update all records where icon_url is null but favicon is not null
UPDATE public.external_stations
SET icon_url = favicon
WHERE icon_url IS NULL AND favicon IS NOT NULL;

-- ============================================================================
-- Migration Complete
-- ============================================================================
-- After running this migration:
-- 1. All existing external stations will have their icon_url populated
-- 2. Icons will display correctly in playlists and recently played sections
-- 3. No new data is added, just copying existing favicon URLs to icon_url field
