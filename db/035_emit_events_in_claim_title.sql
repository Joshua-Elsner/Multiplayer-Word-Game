CREATE OR REPLACE FUNCTION claim_shark_title(
    winner_id UUID,          
    guessed_word TEXT,       
    new_secret_word TEXT,
    guesses_used INTEGER DEFAULT 0,
    is_retry BOOLEAN DEFAULT false
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    db_current_shark_id UUID;
    db_secret_word TEXT;
    shark_duration_seconds INTEGER;
BEGIN
    -- Validations
    IF upper(new_secret_word) !~ '^[A-Z]{5}$' THEN 
        RAISE EXCEPTION 'Invalid secret word. Must be exactly 5 letters.'; 
    END IF;
    IF NOT EXISTS (SELECT 1 FROM dictionary WHERE word = upper(new_secret_word)) THEN 
        RAISE EXCEPTION 'Invalid word. Not in dictionary.'; 
    END IF;
    IF EXISTS (SELECT 1 FROM used_words WHERE word = upper(new_secret_word)) THEN 
        RAISE EXCEPTION 'Word already used! You must pick a word that has never been played.'; 
    END IF;

    -- Lock State
    SELECT current_shark_id, secret_word, EXTRACT(EPOCH FROM (NOW() - shark_start_time))::INTEGER
    INTO db_current_shark_id, db_secret_word, shark_duration_seconds
    FROM game_state WHERE id = 1 FOR UPDATE;

    IF upper(guessed_word) != db_secret_word THEN 
        RAISE EXCEPTION 'TOO SLOW!!! The Shark may have already been defeated by someone else!'; 
    END IF;

    IF winner_id = db_current_shark_id THEN 
        RAISE EXCEPTION 'You are already the Shark!';
    END IF;

    -- Apply Outgoing Shark Updates
    IF db_current_shark_id IS NOT NULL THEN
        UPDATE players
        SET total_time_as_shark = total_time_as_shark + COALESCE(shark_duration_seconds, 0),
            all_time_time_as_shark = all_time_time_as_shark + COALESCE(shark_duration_seconds, 0)
        WHERE id = db_current_shark_id;
    END IF;

    -- Apply Winner Updates
    UPDATE players
        SET sharks_evaded = sharks_evaded + 1,
        weekly_sharks_evaded = weekly_sharks_evaded + 1,
        weekly_guesses = weekly_guesses + guesses_used,
        all_time_guesses = all_time_guesses + guesses_used,
        weekly_puzzles_played = weekly_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END,
        all_time_puzzles_played = all_time_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END
    WHERE id = winner_id;

    -- Update Global Game State & Dictionary
    UPDATE game_state SET current_shark_id = winner_id, secret_word = upper(new_secret_word), shark_start_time = NOW() WHERE id = 1;
    INSERT INTO used_words (word, shark_id) VALUES (upper(new_secret_word), winner_id);

    -- NEW: Emit the event
    INSERT INTO game_events (event_type, player_id) VALUES ('NEW_SHARK', winner_id);
END;
$$;
