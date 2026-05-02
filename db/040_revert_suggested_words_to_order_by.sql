CREATE OR REPLACE FUNCTION get_word_suggestions()
RETURNS TABLE(word TEXT)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT d.word
    FROM dictionary d
    WHERE d.is_common = true
      AND d.word NOT IN (SELECT u.word FROM used_words u)
    ORDER BY random()
    LIMIT 2;
$$;

