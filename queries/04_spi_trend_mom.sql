-- Q4. Is performance improving or deteriorating?
-- Business question: For each active project, compare the latest SPI with the previous
--                    month and the 3-month average to flag a worsening trend.
-- Techniques: window functions LAG, AVG OVER (ROWS BETWEEN), ROW_NUMBER
SET search_path TO pmo;

WITH trend AS (
    SELECT
        e.project_id,
        e.report_month,
        e.spi,
        lag(e.spi) OVER w                                             AS prev_spi,
        round(avg(e.spi) OVER (w ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 3) AS spi_3m_avg,
        row_number() OVER (PARTITION BY e.project_id ORDER BY e.report_month DESC) AS rn
    FROM v_evm_monthly e
    WINDOW w AS (PARTITION BY e.project_id ORDER BY e.report_month)
)
SELECT
    p.project_name,
    t.report_month,
    t.prev_spi,
    t.spi,
    t.spi_3m_avg,
    round(t.spi - t.prev_spi, 3) AS mom_change,
    CASE WHEN t.spi < t.prev_spi AND t.spi < t.spi_3m_avg THEN 'Worsening'
         WHEN t.spi > t.prev_spi THEN 'Improving'
         ELSE 'Stable' END       AS trend
FROM trend t
JOIN projects p USING (project_id)
WHERE t.rn = 1 AND p.status = 'Active'
ORDER BY mom_change;
