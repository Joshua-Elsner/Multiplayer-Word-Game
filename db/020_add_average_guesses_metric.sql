

-- 1. Add Tracking Columns
ALTER TABLE players ADD COLUMN weekly_guesses INTEGER DEFAULT 0;
ALTER TABLE players ADD COLUMN weekly_puzzles_played INTEGER DEFAULT 0;
ALTER TABLE players ADD COLUMN all_time_guesses INTEGER DEFAULT 0;
ALTER TABLE players ADD COLUMN all_time_puzzles_played INTEGER DEFAULT 0;

-- 2. Drop existing functions so we can modify their parameters safely
DROP FUNCTION IF EXISTS record_shark_meal();
DROP FUNCTION IF EXISTS claim_shark_title(UUID, TEXT, TEXT);

-- 3. Replace record_shark_meal (Handles Losses)
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

    -- Update Shark (Give them their meal point)
    IF db_current_shark_id IS NOT NULL THEN
        UPDATE players 
        SET fish_eaten = fish_eaten + 1, 
            weekly_fish_eaten = weekly_fish_eaten + 1 
        WHERE id = db_current_shark_id;
    END IF;

    -- Update Loser (Log their guesses and games played)
    IF loser_id IS NOT NULL THEN
        UPDATE players
        SET weekly_guesses = weekly_guesses + guesses_used,
            all_time_guesses = all_time_guesses + guesses_used,
            -- Only count as a new puzzle if it's NOT a retry
            weekly_puzzles_played = weekly_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END,
            all_time_puzzles_played = all_time_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END
        WHERE id = loser_id;
    END IF;
END;
$$;

-- 4. Replace claim_shark_title (Handles Wins & Word Setting)
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

    -- Apply Outgoing Shark Updates (Cash in their time)
    IF db_current_shark_id IS NOT NULL THEN
        UPDATE players
        SET total_time_as_shark = total_time_as_shark + COALESCE(shark_duration_seconds, 0),
            all_time_time_as_shark = all_time_time_as_shark + COALESCE(shark_duration_seconds, 0)
        WHERE id = db_current_shark_id;
    END IF;

    -- Apply Winner Updates (Evades + Guesses)
    UPDATE players
    SET sharks_evaded = sharks_evaded + 1,
        weekly_sharks_evaded = weekly_sharks_evaded + 1,
        weekly_guesses = weekly_guesses + guesses_used,
        all_time_guesses = all_time_guesses + guesses_used,
        -- Only count as a new puzzle if it's NOT a retry
        weekly_puzzles_played = weekly_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END,
        all_time_puzzles_played = all_time_puzzles_played + CASE WHEN is_retry THEN 0 ELSE 1 END
    WHERE id = winner_id;

    -- Update Global Game State & Dictionary
    UPDATE game_state SET current_shark_id = winner_id, secret_word = upper(new_secret_word), shark_start_time = NOW() WHERE id = 1;
    INSERT INTO used_words (word, shark_id) VALUES (upper(new_secret_word), winner_id);
END;
$$;

-- 5. Update Weekly Reset RPC to wipe the new weekly columns
CREATE OR REPLACE FUNCTION process_weekly_shark_reset()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    top_shark_id UUID;
    active_shark_id UUID;
    active_duration INTEGER;
BEGIN
    -- 1. Cash in the CURRENT active shark's live running time
    SELECT current_shark_id, EXTRACT(EPOCH FROM (NOW() - shark_start_time))::INTEGER
    INTO active_shark_id, active_duration
    FROM game_state
    WHERE id = 1;

    IF active_shark_id IS NOT NULL THEN
        UPDATE players
        SET total_time_as_shark = total_time_as_shark + COALESCE(active_duration, 0),
            all_time_time_as_shark = all_time_time_as_shark + COALESCE(active_duration, 0)
        WHERE id = active_shark_id;
    END IF;

    -- 2. NOW find the player with the most weekly time_as_shark
    SELECT id INTO top_shark_id
    FROM players
    WHERE total_time_as_shark > 0
    ORDER BY total_time_as_shark DESC
    LIMIT 1;

    -- 3. Award the 'Shark of the Week' crown
    IF top_shark_id IS NOT NULL THEN
        UPDATE players
        SET shark_of_the_week_wins = shark_of_the_week_wins + 1
        WHERE id = top_shark_id;
    END IF;

    -- 4. Archive everyone's time into the history table
    INSERT INTO weekly_shark_history (player_id, time_as_shark, week_ending)
    SELECT id, total_time_as_shark, CURRENT_DATE
    FROM players
    WHERE total_time_as_shark > 0;

    -- 5. RESET ALL WEEKLY STATS TO 0 (Leave All-Time stats untouched)
    UPDATE players
    SET total_time_as_shark = 0,
        weekly_fish_eaten = 0,
        weekly_sharks_evaded = 0,
        weekly_yoinks = 0,
        weekly_guesses = 0,          -- NEW
        weekly_puzzles_played = 0    -- NEW
    WHERE id IS NOT NULL;

    -- 6. Reset active game state
    UPDATE game_state
    SET current_shark_id = NULL, secret_word = 'SHARK', shark_start_time = NOW()
    WHERE id = 1;

    -- 7. ARCHIVE AND WIPE THE USED WORDS DICTIONARY
    INSERT INTO used_words_history (word, shark_id, used_at, week_ending)
    SELECT word, shark_id, used_at, CURRENT_DATE 
    FROM used_words 
    WHERE word != 'SHARK';
    
    DELETE FROM used_words WHERE word IS NOT NULL;
    INSERT INTO used_words (word) VALUES ('SHARK');
END;
$$;
