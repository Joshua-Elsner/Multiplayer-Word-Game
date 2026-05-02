CREATE OR REPLACE FUNCTION get_word_suggestions()
RETURNS TABLE(word TEXT)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT d.word
    FROM dictionary d TABLESAMPLE BERNOULLI(10) 
    WHERE d.is_common = true
      AND d.word NOT IN (SELECT u.word FROM used_words u)
    LIMIT 2;
$$;
