CREATE OR REPLACE FUNCTION record_yoink(target_shark_id UUID) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_yoinks INTEGER;
    new_weekly_yoinks INTEGER;
BEGIN
    UPDATE players 
    SET yoinks = yoinks + 1,
        weekly_yoinks = weekly_yoinks + 1 
    WHERE id = target_shark_id
    RETURNING yoinks, weekly_yoinks INTO new_yoinks, new_weekly_yoinks;

    -- Emit the exact totals
    INSERT INTO game_events (event_type, player_id, payload) 
    VALUES (
        'YOINK', 
        target_shark_id, 
        jsonb_build_object('yoinks', new_yoinks, 'weekly_yoinks', new_weekly_yoinks)
    );
END;
$$;
