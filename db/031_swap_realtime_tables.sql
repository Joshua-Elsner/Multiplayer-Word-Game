-- Turn off the heavy firehose
ALTER PUBLICATION supabase_realtime DROP TABLE players;

-- Turn on the lightweight stream
ALTER PUBLICATION supabase_realtime ADD TABLE game_events;
