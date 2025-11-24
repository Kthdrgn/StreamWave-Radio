-- Fix for External Stations Schema
-- This script fixes the issue where station_id columns are NOT NULL
-- but need to be nullable to support external stations

-- ============================================================================
-- Fix playlist_items table
-- ============================================================================

-- Drop the existing check constraint
ALTER TABLE public.playlist_items
DROP CONSTRAINT IF EXISTS playlist_items_station_check;

-- Make station_id nullable
ALTER TABLE public.playlist_items
ALTER COLUMN station_id DROP NOT NULL;

-- Re-add the constraint with the correct logic
ALTER TABLE public.playlist_items
ADD CONSTRAINT playlist_items_station_check CHECK (
    (station_id IS NOT NULL AND external_station_id IS NULL) OR
    (station_id IS NULL AND external_station_id IS NOT NULL)
);

-- ============================================================================
-- Fix station_history table
-- ============================================================================

-- Drop the existing check constraint
ALTER TABLE public.station_history
DROP CONSTRAINT IF EXISTS station_history_station_check;

-- Make station_id nullable
ALTER TABLE public.station_history
ALTER COLUMN station_id DROP NOT NULL;

-- Re-add the constraint with the correct logic
ALTER TABLE public.station_history
ADD CONSTRAINT station_history_station_check CHECK (
    (station_id IS NOT NULL AND external_station_id IS NULL) OR
    (station_id IS NULL AND external_station_id IS NOT NULL)
);

-- ============================================================================
-- Verification
-- ============================================================================

-- Verify the changes by checking the constraints
SELECT
    table_name,
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_name IN ('playlist_items', 'station_history')
  AND column_name IN ('station_id', 'external_station_id')
ORDER BY table_name, column_name;

-- Check constraints
SELECT
    con.conname AS constraint_name,
    rel.relname AS table_name,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
INNER JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname IN ('playlist_items', 'station_history')
  AND con.conname LIKE '%station_check%';
