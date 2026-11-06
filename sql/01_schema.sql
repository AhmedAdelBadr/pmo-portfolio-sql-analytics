-- =============================================================
-- PMO Portfolio Analytics — Schema (PostgreSQL 14+)
-- =============================================================
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS pmo CASCADE;
CREATE SCHEMA pmo;
SET search_path TO pmo;

CREATE TABLE portfolios (
    portfolio_id   SMALLINT PRIMARY KEY,
    portfolio_name TEXT NOT NULL UNIQUE,
    sponsor        TEXT NOT NULL
);

CREATE TABLE project_managers (
    pm_id      SMALLINT PRIMARY KEY,
    full_name  TEXT NOT NULL,
    hired_on   DATE NOT NULL
);

CREATE TABLE projects (
    project_id       INT PRIMARY KEY,
    portfolio_id     SMALLINT NOT NULL REFERENCES portfolios,
    pm_id            SMALLINT NOT NULL REFERENCES project_managers,
    project_name     TEXT NOT NULL,
    start_date       DATE NOT NULL,
    planned_end_date DATE NOT NULL,
    actual_end_date  DATE,
    budget_bac       NUMERIC(14,2) NOT NULL CHECK (budget_bac > 0),  -- Budget At Completion
    status           TEXT NOT NULL CHECK (status IN ('Active','Completed','On Hold')),
    CHECK (planned_end_date > start_date)
);

-- Monthly status report submitted by each PM (cumulative figures)
CREATE TABLE monthly_progress (
    project_id      INT  NOT NULL REFERENCES projects,
    report_month    DATE NOT NULL,                       -- first day of month
    planned_pct     NUMERIC(5,4) NOT NULL CHECK (planned_pct BETWEEN 0 AND 1),
    actual_pct      NUMERIC(5,4) NOT NULL CHECK (actual_pct  BETWEEN 0 AND 1),
    actual_cost_cum NUMERIC(14,2) NOT NULL CHECK (actual_cost_cum >= 0),
    PRIMARY KEY (project_id, report_month)
);

CREATE TABLE milestones (
    milestone_id   INT PRIMARY KEY,
    project_id     INT  NOT NULL REFERENCES projects,
    milestone_name TEXT NOT NULL,
    planned_date   DATE NOT NULL,
    actual_date    DATE
);

CREATE TABLE risks (
    risk_id     INT PRIMARY KEY,
    project_id  INT NOT NULL REFERENCES projects,
    category    TEXT NOT NULL CHECK (category IN ('Schedule','Cost','Scope','Resource','Vendor','Regulatory')),
    probability SMALLINT NOT NULL CHECK (probability BETWEEN 1 AND 5),
    impact      SMALLINT NOT NULL CHECK (impact BETWEEN 1 AND 5),
    raised_on   DATE NOT NULL,
    closed_on   DATE
);

CREATE TABLE change_requests (
    cr_id        INT PRIMARY KEY,
    project_id   INT NOT NULL REFERENCES projects,
    submitted_on DATE NOT NULL,
    decided_on   DATE,
    cost_impact  NUMERIC(14,2) NOT NULL,
    decision     TEXT NOT NULL CHECK (decision IN ('Approved','Rejected','Pending'))
);

CREATE INDEX ON projects (portfolio_id);
CREATE INDEX ON projects (pm_id);
CREATE INDEX ON milestones (project_id);
CREATE INDEX ON risks (project_id) WHERE closed_on IS NULL;
CREATE INDEX ON change_requests (project_id);
