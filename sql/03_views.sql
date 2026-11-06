-- =============================================================
-- PMO Portfolio Analytics — Reusable views (semantic layer)
-- =============================================================
SET search_path TO pmo;

-- Earned Value Management per project per month
--   PV = BAC × planned %     EV = BAC × actual %     AC = actual cost
--   SPI = EV / PV            CPI = EV / AC
CREATE OR REPLACE VIEW v_evm_monthly AS
SELECT
    mp.project_id,
    mp.report_month,
    p.budget_bac                                   AS bac,
    round(p.budget_bac * mp.planned_pct, 2)        AS pv,
    round(p.budget_bac * mp.actual_pct, 2)         AS ev,
    mp.actual_cost_cum                             AS ac,
    round(mp.actual_pct / NULLIF(mp.planned_pct, 0), 3)                         AS spi,
    round(p.budget_bac * mp.actual_pct / NULLIF(mp.actual_cost_cum, 0), 3)      AS cpi
FROM monthly_progress mp
JOIN projects p USING (project_id);

-- Latest status report per project (DISTINCT ON = "last row per group")
CREATE OR REPLACE VIEW v_evm_latest AS
SELECT DISTINCT ON (project_id) *
FROM v_evm_monthly
ORDER BY project_id, report_month DESC;

-- One row per project with RAG status used across all reports
CREATE OR REPLACE VIEW v_project_health AS
SELECT
    p.project_id,
    p.project_name,
    pf.portfolio_name,
    pm.full_name            AS project_manager,
    p.status,
    e.report_month          AS last_report,
    e.bac, e.ev, e.ac, e.spi, e.cpi,
    CASE
        WHEN p.status = 'On Hold'               THEN 'Grey'
        WHEN e.spi < 0.85 OR e.cpi < 0.85       THEN 'Red'
        WHEN e.spi < 0.95 OR e.cpi < 0.95       THEN 'Amber'
        ELSE 'Green'
    END AS rag
FROM projects p
JOIN portfolios       pf USING (portfolio_id)
JOIN project_managers pm USING (pm_id)
LEFT JOIN v_evm_latest e USING (project_id);
