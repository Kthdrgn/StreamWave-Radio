-- Migration: Fix external_stations RLS policies to allow anonymous/guest access
-- This fixes the issue where Radio Database stations don't show on alternate hosts
-- or when users are not authenticated

-- ============================================================================
-- 1. Add RLS policy for anonymous users to read external stations
-- ============================================================================

-- Allow anonymous users to read external stations
CREATE POLICY IF NOT EXISTS "Allow anonymous users to read external stations"
    ON public.external_stations
    FOR SELECT
    TO anon
    USING (true);

-- ============================================================================
-- 2. Add RLS policy for anonymous users to insert external stations
-- ============================================================================

-- Allow anonymous users to insert external stations
-- This is needed for guest mode users who add Radio Browser stations to playlists
CREATE POLICY IF NOT EXISTS "Allow anonymous users to insert external stations"
    ON public.external_stations
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- ============================================================================
-- Migration Complete
-- ============================================================================
-- After running this migration:
-- 1. Guest users can see Radio Database stations in their playlists
-- 2. Users on alternate hosts can access external stations
-- 3. Guest mode users can add Radio Browser stations to playlists
