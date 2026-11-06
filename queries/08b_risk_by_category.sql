-- Q8b. Open risk exposure by category
-- Business question: Which risk categories carry the most high-exposure open risks,
--                    and how long have they been open?
-- Techniques: computed score (probability × impact), FILTER, date aging
SET search_path TO pmo;

-- score = probability × impact; ≥ 15 = high
SELECT
    category,
    count(*)                                              AS open_risks,
    count(*) FILTER (WHERE probability * impact >= 15)    AS high_exposure,
    round(avg(probability * impact), 1)                   AS avg_score,
    round(avg(DATE '2026-10-31' - raised_on))             AS avg_age_days
FROM risks
WHERE closed_on IS NULL
GROUP BY category
ORDER BY high_exposure DESC, avg_score DESC;
