-- Q9. Change control governance
-- Business question: How fast are change requests decided, what share is approved,
--                    and how much have approved changes grown each project's budget?
-- Techniques: LEFT JOIN with aggregates, COALESCE, scope-creep ratio, HAVING
SET search_path TO pmo;

SELECT
    p.project_name,
    count(cr.cr_id)                                                   AS change_requests,
    count(cr.cr_id) FILTER (WHERE cr.decision = 'Approved')           AS approved,
    round(avg(cr.decided_on - cr.submitted_on), 1)                    AS avg_days_to_decide,
    coalesce(sum(cr.cost_impact) FILTER (WHERE cr.decision = 'Approved'), 0) AS approved_cost_impact,
    round(100.0 * coalesce(sum(cr.cost_impact) FILTER (WHERE cr.decision = 'Approved'), 0)
          / p.budget_bac, 1)                                          AS budget_growth_pct
FROM projects p
LEFT JOIN change_requests cr USING (project_id)
GROUP BY p.project_id, p.project_name, p.budget_bac
HAVING count(cr.cr_id) > 0
ORDER BY budget_growth_pct DESC
LIMIT 10;
