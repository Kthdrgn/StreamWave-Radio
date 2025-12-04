# Database Migrations

This folder contains SQL migration scripts for the StreamWave Radio database.

## How to Apply Migrations

1. Log in to your Supabase dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of the migration file
4. Click "Run" to execute the migration

## Required Migrations for Radio Database Station Icons

If you're experiencing issues with Radio Database station icons not displaying in playlists or the Recently played section, you need to apply these migrations **in order**:

### 1. fix_external_stations_rls.sql
**Purpose:** Fixes Row Level Security (RLS) policies for the `external_stations` table.

**What it does:**
- Allows anonymous (guest) users to read external stations
- Allows anonymous users to insert external stations
- This is required for Radio Database stations to work in guest mode

**When to apply:** Required if Radio Database stations don't show up at all, or if different users see different stations.

### 2. update_external_stations_icons.sql
**Purpose:** Updates existing external station records to populate the `icon_url` field.

**What it does:**
- Copies the `favicon` value to `icon_url` for all existing stations where `icon_url` is null
- This fixes stations that were added before the code fix was implemented

**When to apply:** Required if Radio Database station icons display on the search page but not in playlists or recently played sections.

## Other Migrations

### curated_playlists.sql
**Purpose:** Creates tables and policies for the Curated Playlists feature.

**What it does:**
- Creates `curated_playlists` table for admin-managed playlist collections
- Creates `curated_playlist_items` table for stations in curated playlists
- Sets up RLS policies for public read and admin write access

**When to apply:** Required for the Curated Playlists feature to work.

## Troubleshooting

### Migration fails with "policy already exists"
Some migrations include `DROP POLICY IF EXISTS` statements, but older PostgreSQL versions might not support this. If you see an error, you can:
1. Remove the `DROP POLICY` lines from the migration
2. Or manually drop the policies first using:
   ```sql
   DROP POLICY "policy_name" ON table_name;
   ```

### Changes not taking effect
After applying migrations:
1. Clear your browser cache
2. Do a hard refresh (Ctrl+Shift+R or Cmd+Shift+R)
3. Check the browser console for any errors

### Still having issues?
Check the Supabase logs to see if there are any RLS policy violations or query errors.
