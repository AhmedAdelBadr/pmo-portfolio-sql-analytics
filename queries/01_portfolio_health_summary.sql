-- Q1. Portfolio health at a glance
-- Business question: How many projects in each portfolio are Green / Amber / Red,
--                    and what is the budget exposed in Red projects?
-- Techniques: aggregate FILTER, conditional SUM, view reuse
SET search_path TO pmo;

SELECT
    portfolio_name,
    count(*)                                          AS projects,
    count(*) FILTER (WHERE rag = 'Green')             AS green,
    count(*) FILTER (WHERE rag = 'Amber')             AS amber,
    count(*) FILTER (WHERE rag = 'Red')               AS red,
    count(*) FILTER (WHERE rag = 'Grey')              AS on_hold,
    to_char(sum(bac), 'FM999,999,999')                AS total_budget,
    to_char(coalesce(sum(bac) FILTER (WHERE rag = 'Red'), 0), 'FM999,999,999') AS budget_in_red
FROM v_project_health
GROUP BY portfolio_name
ORDER BY red DESC, portfolio_name;
