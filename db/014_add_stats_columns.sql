================================================================
FILE: ./db/014_add_stats_columns.sql
================================================================
-- Add new weekly tracking columns
ALTER TABLE players ADD COLUMN weekly_fish_eaten INTEGER DEFAULT 0;
ALTER TABLE players ADD COLUMN weekly_sharks_evaded INTEGER DEFAULT 0;
ALTER TABLE players ADD COLUMN weekly_yoinks INTEGER DEFAULT 0;

-- Add new all-time tracking column
ALTER TABLE players ADD COLUMN all_time_time_as_shark INTEGER DEFAULT 0;
