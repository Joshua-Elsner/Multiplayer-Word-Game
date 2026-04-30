CREATE OR REPLACE FUNCTION record_yoink(target_shark_id UUID) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE players 
    SET yoinks = yoinks + 1,
        weekly_yoinks = weekly_yoinks + 1 
    WHERE id = target_shark_id;

    -- NEW: Emit the event
    INSERT INTO game_events (event_type, player_id) VALUES ('YOINK', target_shark_id);
END;
$$;
