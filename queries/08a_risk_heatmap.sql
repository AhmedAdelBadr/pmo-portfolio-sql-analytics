-- Q8a. Open risk exposure heat map
-- Business question: Where is open risk concentrated? Show a probability × impact
--                    matrix of open risks and the high-exposure count per category.
-- Techniques: pivot with FILTER, generate_series to guarantee all matrix cells
SET search_path TO pmo;

-- 5×5 heat map (rows = probability, columns = impact)
SELECT
    pr.probability,
    count(r.risk_id) FILTER (WHERE r.impact = 1) AS impact_1,
    count(r.risk_id) FILTER (WHERE r.impact = 2) AS impact_2,
    count(r.risk_id) FILTER (WHERE r.impact = 3) AS impact_3,
    count(r.risk_id) FILTER (WHERE r.impact = 4) AS impact_4,
    count(r.risk_id) FILTER (WHERE r.impact = 5) AS impact_5
FROM generate_series(5, 1, -1) AS pr(probability)
LEFT JOIN risks r
       ON r.probability = pr.probability
      AND r.closed_on IS NULL
GROUP BY pr.probability
ORDER BY pr.probability DESC;
