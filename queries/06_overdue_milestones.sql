-- Q6. Overdue milestones (open items for the PMO review meeting)
-- Business question: Which milestones are past their planned date and still not
--                    delivered as of the reporting cut-off?
-- Techniques: anti-condition on NULL, date difference, ordering by aging
SET search_path TO pmo;

SELECT
    p.project_name,
    p.status,
    pm.full_name                       AS project_manager,
    m.milestone_name,
    m.planned_date,
    DATE '2026-10-31' - m.planned_date AS days_overdue
FROM milestones m
JOIN projects         p  USING (project_id)
JOIN project_managers pm USING (pm_id)
WHERE m.actual_date IS NULL
  AND m.planned_date < DATE '2026-10-31'
ORDER BY days_overdue DESC;
