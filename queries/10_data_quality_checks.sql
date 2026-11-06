-- Q10. Data quality checks on PM status reports
-- Business question: Are there reporting gaps or inconsistent records the PMO
--                    should chase before the monthly review?
-- Techniques: UNION ALL rule set, generate_series gap detection, LAG for regressions
SET search_path TO pmo;

WITH expected AS (            -- every month a project should have reported
    SELECT p.project_id, gs::DATE AS report_month
    FROM projects p
    CROSS JOIN LATERAL generate_series(
        date_trunc('month', p.start_date) + INTERVAL '1 month',
        (SELECT max(report_month) FROM monthly_progress mp WHERE mp.project_id = p.project_id),
        INTERVAL '1 month') gs
),
regressions AS (              -- cumulative % should never go down
    SELECT project_id, report_month, actual_pct,
           lag(actual_pct) OVER (PARTITION BY project_id ORDER BY report_month) AS prev_pct
    FROM monthly_progress
)
SELECT 'Missing monthly report' AS rule, e.project_id, e.report_month::TEXT AS detail
FROM expected e
LEFT JOIN monthly_progress mp USING (project_id, report_month)
WHERE mp.project_id IS NULL
UNION ALL
SELECT 'Progress went backwards', project_id, report_month::TEXT
FROM regressions WHERE actual_pct < prev_pct
UNION ALL
SELECT 'Milestone delivered before project start', m.project_id, m.milestone_name
FROM milestones m JOIN projects p USING (project_id)
WHERE m.actual_date < p.start_date
UNION ALL
SELECT 'Completed project without end date', project_id, project_name
FROM projects WHERE status = 'Completed' AND actual_end_date IS NULL
UNION ALL
SELECT 'Risk closed before it was raised', project_id, risk_id::TEXT
FROM risks WHERE closed_on < raised_on
ORDER BY rule, project_id;

-- An empty result means the dataset passed every rule.
