# PMO Portfolio Analytics with SQL

![SQL CI](https://github.com/AhmedAdelBadr/pmo-portfolio-sql-analytics/actions/workflows/sql-ci.yml/badge.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

This repository models the data behind a **Project Management Office (PMO)** that oversees a portfolio of 24 projects across 4 portfolios. It answers the questions a PMO lead brings to the monthly review with leadership, using SQL only:

- Which projects are **Red / Amber / Green**, and how much budget sits in Red?
- Which active projects are **behind schedule or over budget**, and why?
- How much will active projects **overrun at completion** (EAC / VAC)?
- Is performance **improving or getting worse** month over month?
- How reliably are **milestones** delivered, and which are overdue?
- Which **project managers** deliver best on a budget-weighted basis?
- Where is **open risk** concentrated?
- Are **change requests** decided quickly, and how much have they grown budgets?
- Are PM status reports **complete and consistent**?

> All data is **synthetic**. It is generated in SQL with a fixed random seed, so every run reproduces exactly the same numbers. Amounts are in EGP and the reporting cut-off is **31 Oct 2026**.

---

## Data model

```mermaid
erDiagram
    PORTFOLIOS ||--o{ PROJECTS : contains
    PROJECT_MANAGERS ||--o{ PROJECTS : manages
    PROJECTS ||--o{ MONTHLY_PROGRESS : reports
    PROJECTS ||--o{ MILESTONES : has
    PROJECTS ||--o{ RISKS : carries
    PROJECTS ||--o{ CHANGE_REQUESTS : receives

    PROJECTS {
        int project_id PK
        smallint portfolio_id FK
        smallint pm_id FK
        date start_date
        date planned_end_date
        date actual_end_date
        numeric budget_bac
        text status
    }
    MONTHLY_PROGRESS {
        int project_id PK
        date report_month PK
        numeric planned_pct
        numeric actual_pct
        numeric actual_cost_cum
    }
    MILESTONES {
        int milestone_id PK
        date planned_date
        date actual_date
    }
    RISKS {
        int risk_id PK
        text category
        smallint probability
        smallint impact
        date raised_on
        date closed_on
    }
    CHANGE_REQUESTS {
        int cr_id PK
        date submitted_on
        date decided_on
        numeric cost_impact
        text decision
    }
```

A small **semantic layer** of views (`sql/03_views.sql`) computes **Earned Value Management** once, and every report reuses it:

| Metric | Formula | Meaning |
|---|---|---|
| PV | BAC × planned % | Planned Value |
| EV | BAC × actual % | Earned Value |
| AC | cumulative actual cost | Actual Cost |
| SPI | EV / PV | < 1 = behind schedule |
| CPI | EV / AC | < 1 = over budget |
| EAC | BAC / CPI | Estimate At Completion |
| RAG | Red if SPI or CPI < 0.85, Amber if < 0.95 | Health status |

---

## Analysis queries

| # | Question | SQL techniques |
|---|---|---|
| [01](queries/01_portfolio_health_summary.sql) | Portfolio RAG summary and budget in Red | `FILTER` aggregates, views |
| [02](queries/02_projects_needing_attention.sql) | Projects to escalate this month | `CASE` classification |
| [03](queries/03_eac_forecast.sql) | Forecast cost at completion | `GROUP BY ROLLUP`, `NULLIF` |
| [04](queries/04_spi_trend_mom.sql) | Month-over-month SPI trend | `LAG`, moving average, named `WINDOW` |
| [05](queries/05_milestone_slippage.sql) | On-time milestone % and slippage | `PERCENTILE_CONT`, date math |
| [06](queries/06_overdue_milestones.sql) | Overdue milestones for the review meeting | NULL handling, aging |
| [07](queries/07_pm_scorecard.sql) | Project manager ranking | weighted averages, `RANK()` |
| [08a](queries/08a_risk_heatmap.sql) | 5×5 risk heat map | pivot with `FILTER`, `generate_series` |
| [08b](queries/08b_risk_by_category.sql) | Risk exposure by category | computed scores |
| [09](queries/09_change_request_governance.sql) | Change control speed and budget growth | `LEFT JOIN`, `HAVING` |
| [10](queries/10_data_quality_checks.sql) | Data quality rules on PM submissions | `UNION ALL` rules, `LATERAL generate_series`, gap detection |

The full output of every query is saved in [`results/`](results/) as CSV, which GitHub renders as a table.

### Sample outputs

**Q1. Portfolio health**

| portfolio_name | projects | green | amber | red | on_hold | total_budget | budget_in_red |
|---|---|---|---|---|---|---|---|
| Digital Transformation | 9 | 3 | 3 | 3 | 0 | 18,346,000 | 8,133,000 |
| Infrastructure & Facilities | 6 | 2 | 1 | 2 | 1 | 10,025,000 | 2,296,000 |
| Innovation Lab | 4 | 2 | 1 | 1 | 0 | 8,245,000 | 789,000 |
| Social Programs | 5 | 2 | 1 | 1 | 1 | 12,086,000 | 3,417,000 |

**Q4. Is performance improving?**

| project_name | prev_spi | spi | spi_3m_avg | mom_change | trend |
|---|---|---|---|---|---|
| Network Upgrade | 0.701 | 0.666 | 0.709 | -0.035 | Worsening |
| Youth Skills Program | 0.913 | 0.900 | 0.904 | -0.013 | Worsening |
| Smart Meeting Rooms | 0.911 | 0.902 | 0.901 | -0.009 | Stable |
| Vendor Portal | 1.006 | 1.019 | 1.006 | 0.013 | Improving |
| Customer Portal | 0.911 | 0.946 | 0.914 | 0.035 | Improving |

**Q8a. Open risk heat map (probability × impact)**

| probability | impact_1 | impact_2 | impact_3 | impact_4 | impact_5 |
|---|---|---|---|---|---|
| 5 | 4 | 4 | 3 | 8 | 3 |
| 4 | 0 | 5 | 1 | 4 | 6 |
| 3 | 3 | 2 | 1 | 3 | 7 |
| 2 | 0 | 1 | 3 | 1 | 1 |
| 1 | 5 | 1 | 3 | 0 | 0 |

**Q10. Data quality issues caught**

| rule | project_id | detail |
|---|---|---|
| Missing monthly report | 2 | 2026-03-01 |
| Progress went backwards | 23 | 2026-01-01 |

---

## Key findings (for the leadership review)

1. **7 of 24 projects are Red.** Digital Transformation carries the largest exposure, with 8.1M of its 18.3M budget in Red projects.
2. **Active projects are forecast to finish about 4.9% over budget** (≈ 436K). Most of that comes from *Vendor Portal* (CPI 0.80, forecast overrun of −25.6%).
3. **Network Upgrade is the top escalation.** Its SPI is 0.67 and still falling month over month.
4. **Vendor risk is the biggest concentration.** 10 of the 15 open vendor risks score 15 or higher (high exposure).
5. **Social Programs delivers only 13% of milestones on time**, against 52% in Digital Transformation.
6. **Report quality:** one missing monthly report and one regressed progress figure were flagged for follow-up with the PMs.

---

## How to run

**Option 1: Docker (recommended)**

```bash
docker compose up -d                  # PostgreSQL 16; schema, seed and views load automatically
./scripts/run_all.sh                  # rebuilds the database and writes results/*.csv
```

**Option 2: an existing PostgreSQL 16 server**

```bash
createdb portfolio
DATABASE_URL=postgresql://USER:PASS@localhost:5432/portfolio ./scripts/run_all.sh
```

Or run any single file in psql, DBeaver, pgAdmin or VS Code once the `sql/` scripts have been loaded.

> PostgreSQL 16 is pinned because `setseed()` produces the same synthetic data only on the same major version.

Every push is checked by **GitHub Actions** ([`sql-ci.yml`](.github/workflows/sql-ci.yml)), which builds the database from scratch and runs every query.

---

## Project structure

```
├── sql/
│   ├── 01_schema.sql        # tables, constraints, indexes
│   ├── 02_seed.sql          # deterministic synthetic data (PL/pgSQL)
│   └── 03_views.sql         # EVM + project health semantic layer
├── queries/                 # one business question per file
├── results/                 # CSV output of every query
├── scripts/run_all.sh       # one-command rebuild + run
├── docker-compose.yml
└── .github/workflows/sql-ci.yml
```

---

## About

Built by **Ahmed Adel Badr**, PMO Team Lead with a background in project controls and planning engineering, working in data analytics, SQL and BI dashboards. The metrics and checks here are the ones used in real portfolio reviews: EVM, RAG status, milestone tracking, risk registers and change control.
