-- Q7. Project manager scorecard
-- Business question: Rank project managers by delivery performance using
--                    budget-weighted SPI and CPI across their projects.
-- Techniques: weighted average, RANK() window, multiple CTEs
SET search_path TO pmo;

WITH pm_stats AS (
    SELECT
        project_manager,
        count(*)                                         AS projects,
        sum(bac)                                         AS managed_budget,
        round(sum(spi * bac) / sum(bac), 3)              AS weighted_spi,
        round(sum(cpi * bac) / sum(bac), 3)              AS weighted_cpi,
        count(*) FILTER (WHERE rag = 'Red')              AS red_projects
    FROM v_project_health
    WHERE status <> 'On Hold'
    GROUP BY project_manager
)
SELECT
    rank() OVER (ORDER BY (weighted_spi + weighted_cpi) DESC) AS rank,
    project_manager,
    projects,
    to_char(managed_budget, 'FM999,999,999') AS managed_budget,
    weighted_spi,
    weighted_cpi,
    red_projects
FROM pm_stats
ORDER BY rank;
