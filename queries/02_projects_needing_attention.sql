-- Q2. Which active projects need escalation this month?
-- Business question: List active projects that are behind schedule or over budget,
--                    worst first, with the main driver of the problem.
-- Techniques: CASE classification, LEAST for ranking severity
SET search_path TO pmo;

SELECT
    project_name,
    project_manager,
    spi,
    cpi,
    CASE
        WHEN spi < 0.95 AND cpi < 0.95 THEN 'Schedule + Cost'
        WHEN spi < 0.95                THEN 'Schedule'
        ELSE 'Cost'
    END AS problem_area,
    rag
FROM v_project_health
WHERE status = 'Active'
  AND (spi < 0.95 OR cpi < 0.95)
ORDER BY LEAST(spi, cpi);
