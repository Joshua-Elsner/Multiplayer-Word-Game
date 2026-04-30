-- Schedule the cleanup to run every day at 8:00 am eastern time
SELECT cron.schedule(
    'daily-game-events-cleanup',
    '0 12 * * *',
    $$ DELETE FROM game_events WHERE created_at < NOW() - INTERVAL '1 day'; $$
);
