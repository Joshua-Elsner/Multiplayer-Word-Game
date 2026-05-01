-- Create a lightweight table specifically for catching and broadcasting UI updates
CREATE TABLE game_events (
    id SERIAL PRIMARY KEY,
    event_type TEXT NOT NULL,
    player_id UUID REFERENCES players(id) ON DELETE CASCADE,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Secure it for public read access
ALTER TABLE game_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to game_events" ON game_events FOR SELECT USING (true);
