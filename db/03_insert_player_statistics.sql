INSERT INTO players (username, total_time_as_shark, fish_eaten, sharks_evaded)
VALUES 
    ('Samantha', 0, 0, 0),
    ('Clayton', 0, 0, 0),
    ('Amelia', 0, 0, 0),
    ('Josh', 0, 0, 0),
    ('David', 0, 0, 0),
    ('Aliya', 0, 0, 0),
    ('Shane', 0, 0, 0),
    ('Elijah', 0, 0, 0),
    ('John', 0, 0, 0)
ON CONFLICT (username)
DO UPDATE SET 
    total_time_as_shark = EXCLUDED.total_time_as_shark,
    fish_eaten = EXCLUDED.fish_eaten,
    sharks_evaded = EXCLUDED.sharks_evaded;
