CREATE OR REPLACE FUNCTION record_shark_meal(
    loser_id UUID DEFAULT NULL, 
    guesses_used INTEGER DEFAULT 0, 
    is_retry BOOLEAN DEFAULT false
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    db_current_shark_id UUID;
    s_fish INTEGER;
    s_w_fish INTEGER;
    l_w_guess INTEGER;
    l_a_guess INTEGER;
    l_w_puzzles INTEGER;
    l_a_puzzles INTEGER;
BEGIN
    SELECT current_shark_id INTO db_current_shark_id FROM game_state WHERE id = 1;

    -- Update Shark
    IF db_current_shark_id IS NOT NULL THEN
        UPDATE players 
        SET fish_eaten = fish_eaten + 1, 
            weekly_fish_eaten = weekly_fish_eaten + 1 
        WHERE id = db_current_shark_id
        RETURNING fish_eaten, weekly_fish_eaten INTO s_fish, s_w_fish;

        INSERT INTO game_events (event_type, player_id, payload) 
        VALUES (
            'FISH_EATEN', 
            db_current_shark_id, 
            jsonb_build_object('fish_eaten', s_fish, 'weekly_fish_eaten', s_w_fish)
        );
    END IF;

    -- Update Loser
    IF loser_id IS NOT NULL THEN
        UPDATE players
        SET weekly_guesses = weekly_guesses + guesses_used,
            all_time_guesses = all_time_guesses + guesses_used,
            weekly_puzzles_played = weekly_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END,
            all_time_puzzles_played = all_time_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END
        WHERE id = loser_id
        RETURNING weekly_guesses, all_time_guesses, weekly_puzzles_played, all_time_puzzles_played 
        INTO l_w_guess, l_a_guess, l_w_puzzles, l_a_puzzles;

        INSERT INTO game_events (event_type, player_id, payload) 
        VALUES (
            'PUZZLE_LOST', 
            loser_id, 
            jsonb_build_object(
                'weekly_guesses', l_w_guess, 
                'all_time_guesses', l_a_guess,
                'weekly_puzzles_played', l_w_puzzles,
                'all_time_puzzles_played', l_a_puzzles
            )
        );
    END IF;
END;
$$;
