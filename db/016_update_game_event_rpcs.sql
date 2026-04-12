
-- 1. Update Shark Meal to increment BOTH columns
CREATE OR REPLACE FUNCTION record_shark_meal() RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    db_current_shark_id UUID;
BEGIN
    SELECT current_shark_id INTO db_current_shark_id FROM game_state WHERE id = 1;

    IF db_current_shark_id IS NOT NULL THEN
        UPDATE players
        SET fish_eaten = fish_eaten + 1,
            weekly_fish_eaten = weekly_fish_eaten + 1
        WHERE id = db_current_shark_id;
    END IF;
END;
$$;

-- 2. Update Yoink to increment BOTH columns
CREATE OR REPLACE FUNCTION record_yoink(target_shark_id UUID) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE players 
    SET yoinks = yoinks + 1,
        weekly_yoinks = weekly_yoinks + 1 
    WHERE id = target_shark_id;
END;
$$;

-- 3. Update claim_shark_title to increment BOTH columns for evade and time
CREATE OR REPLACE FUNCTION claim_shark_title(
    winner_id UUID,          
    guessed_word TEXT,       
    new_secret_word TEXT     
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    db_current_shark_id UUID;
    db_secret_word TEXT;
    shark_duration_seconds INTEGER;
BEGIN
    -- Validation Checks
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
    FROM game_state
    WHERE id = 1
    FOR UPDATE;

    -- Verify guess
    IF upper(guessed_word) != db_secret_word THEN
        RAISE EXCEPTION 'TOO SLOW!!! The Shark may have already been defeated by someone else!';
    END IF;

    IF winner_id = db_current_shark_id THEN
        RAISE EXCEPTION 'You are already the Shark!';
    END IF;

    -- Update outgoing Shark (Weekly AND All-Time time added)
    IF db_current_shark_id IS NOT NULL THEN
        UPDATE players
        SET total_time_as_shark = total_time_as_shark + COALESCE(shark_duration_seconds, 0),
            all_time_time_as_shark = all_time_time_as_shark + COALESCE(shark_duration_seconds, 0)
        WHERE id = db_current_shark_id;
    END IF;

    -- Update the Winner (Weekly AND All-Time evade added)
    UPDATE players
    SET sharks_evaded = sharks_evaded + 1,
        weekly_sharks_evaded = weekly_sharks_evaded + 1
    WHERE id = winner_id;

    -- Update State & Dictionary
    UPDATE game_state
    SET current_shark_id = winner_id, secret_word = upper(new_secret_word), shark_start_time = NOW()
    WHERE id = 1;

    INSERT INTO used_words (word, shark_id) VALUES (upper(new_secret_word), winner_id);
END;
$$;
