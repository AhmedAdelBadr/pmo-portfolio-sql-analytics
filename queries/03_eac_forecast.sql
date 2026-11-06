-- Q3. Forecast: where will active projects finish financially?
-- Business question: Using current cost performance, what is the Estimate At Completion
--                    (EAC = BAC / CPI) and the expected overrun (VAC = BAC − EAC)?
-- Techniques: derived metrics, NULLIF safe division, portfolio subtotal with ROLLUP
SET search_path TO pmo;

SELECT
    coalesce(portfolio_name, '== ALL PORTFOLIOS ==')            AS portfolio,
    coalesce(project_name, '-- subtotal --')                    AS project,
    sum(bac)                                                    AS bac,
    round(sum(bac / NULLIF(cpi, 0)))                            AS eac,
    round(sum(bac - bac / NULLIF(cpi, 0)))                      AS vac,
    round(100.0 * sum(bac - bac / NULLIF(cpi, 0)) / sum(bac), 1) AS vac_pct
FROM v_project_health
WHERE status = 'Active'
GROUP BY ROLLUP (portfolio_name, project_name)
ORDER BY portfolio_name NULLS LAST, project_name NULLS LAST;
