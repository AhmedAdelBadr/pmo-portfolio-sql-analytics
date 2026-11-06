-- Q5. Milestone delivery performance
-- Business question: What share of milestones were delivered on time (≤ 7 days late),
--                    and what is the average / median slippage per portfolio?
-- Techniques: date arithmetic, PERCENTILE_CONT, FILTER, ratio formatting
SET search_path TO pmo;

SELECT
    pf.portfolio_name,
    count(*)                                                        AS milestones_delivered,
    round(100.0 * count(*) FILTER (WHERE m.actual_date - m.planned_date <= 7) / count(*), 1)
                                                                    AS on_time_pct,
    round(avg(m.actual_date - m.planned_date), 1)                   AS avg_slip_days,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY m.actual_date - m.planned_date)
                                                                    AS median_slip_days,
    max(m.actual_date - m.planned_date)                             AS worst_slip_days
FROM milestones m
JOIN projects   p  USING (project_id)
JOIN portfolios pf USING (portfolio_id)
WHERE m.actual_date IS NOT NULL
GROUP BY pf.portfolio_name
ORDER BY on_time_pct;
