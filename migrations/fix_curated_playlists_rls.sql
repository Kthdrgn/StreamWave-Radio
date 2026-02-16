-- Migration: Fix curated_playlists RLS policies to allow anonymous/guest access
-- This fixes the error: "new row violates row-level security policy for table curated_playlist_items"
-- when guest/anonymous users try to add stations to curated playlists.

-- ============================================================================
-- 1. Add RLS policies for anonymous users on curated_playlists table
-- ============================================================================

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Anonymous users can insert curated playlists" ON public.curated_playlists;
DROP POLICY IF EXISTS "Anonymous users can update curated playlists" ON public.curated_playlists;
DROP POLICY IF EXISTS "Anonymous users can delete curated playlists" ON public.curated_playlists;

-- Allow anonymous users to insert curated playlists
CREATE POLICY "Anonymous users can insert curated playlists"
    ON public.curated_playlists
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Allow anonymous users to update curated playlists
CREATE POLICY "Anonymous users can update curated playlists"
    ON public.curated_playlists
    FOR UPDATE
    TO anon
    USING (true);

-- Allow anonymous users to delete curated playlists
CREATE POLICY "Anonymous users can delete curated playlists"
    ON public.curated_playlists
    FOR DELETE
    TO anon
    USING (true);

-- ============================================================================
-- 2. Add RLS policies for anonymous users on curated_playlist_items table
-- ============================================================================

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Anonymous users can insert curated playlist items" ON public.curated_playlist_items;
DROP POLICY IF EXISTS "Anonymous users can update curated playlist items" ON public.curated_playlist_items;
DROP POLICY IF EXISTS "Anonymous users can delete curated playlist items" ON public.curated_playlist_items;

-- Allow anonymous users to insert curated playlist items
CREATE POLICY "Anonymous users can insert curated playlist items"
    ON public.curated_playlist_items
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Allow anonymous users to update curated playlist items
CREATE POLICY "Anonymous users can update curated playlist items"
    ON public.curated_playlist_items
    FOR UPDATE
    TO anon
    USING (true);

-- Allow anonymous users to delete curated playlist items
CREATE POLICY "Anonymous users can delete curated playlist items"
    ON public.curated_playlist_items
    FOR DELETE
    TO anon
    USING (true);

-- ============================================================================
-- Migration Complete
-- ============================================================================
-- After running this migration:
-- 1. Guest/anonymous users can add stations to curated playlists
-- 2. Guest/anonymous users can modify curated playlists
-- 3. The "new row violates row-level security policy" error is resolved
