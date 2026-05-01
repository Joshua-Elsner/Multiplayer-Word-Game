CREATE OR REPLACE FUNCTION record_shark_meal(
    loser_id UUID DEFAULT NULL, 
    guesses_used INTEGER DEFAULT 0, 
    is_retry BOOLEAN DEFAULT false
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    db_current_shark_id UUID;
BEGIN
    SELECT current_shark_id INTO db_current_shark_id FROM game_state WHERE id = 1;

    -- Update Shark
    IF db_current_shark_id IS NOT NULL THEN
        UPDATE players 
        SET fish_eaten = fish_eaten + 1, 
            weekly_fish_eaten = weekly_fish_eaten + 1 
        WHERE id = db_current_shark_id;

        INSERT INTO game_events (event_type, player_id) VALUES ('FISH_EATEN', db_current_shark_id);
    END IF;

    -- Update Loser
    IF loser_id IS NOT NULL THEN
        UPDATE players
        SET weekly_guesses = weekly_guesses + guesses_used,
            all_time_guesses = all_time_guesses + guesses_used,
            weekly_puzzles_played = weekly_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END,
            all_time_puzzles_played = all_time_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END
        WHERE id = loser_id;

        -- NEW: Emit the puzzle lost event with the guess data
        INSERT INTO game_events (event_type, player_id, payload) 
        VALUES (
            'PUZZLE_LOST', 
            loser_id, 
            jsonb_build_object('guesses_used', guesses_used, 'is_retry', is_retry)
        );
    END IF;
END;
$$;
