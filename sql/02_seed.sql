-- =============================================================
-- PMO Portfolio Analytics — Synthetic seed data
-- Deterministic (setseed) so every run produces identical data.
-- Data is fictional and generated for demonstration only.
-- Reporting cut-off ("as-of" date): 2026-10-31
-- =============================================================
SET search_path TO pmo;
DO $$ BEGIN PERFORM setseed(0.42); END $$;

INSERT INTO portfolios VALUES
 (1, 'Digital Transformation', 'Chief Information Officer'),
 (2, 'Infrastructure & Facilities', 'Chief Operating Officer'),
 (3, 'Social Programs', 'Director of Programs'),
 (4, 'Innovation Lab', 'Chief Strategy Officer');

INSERT INTO project_managers VALUES
 (1, 'Mona Farouk',    '2019-03-01'),
 (2, 'Karim Nabil',    '2020-07-15'),
 (3, 'Sara Hamdy',     '2018-01-10'),
 (4, 'Omar Khaled',    '2021-05-02'),
 (5, 'Nour El-Din Ali','2017-09-20'),
 (6, 'Heba Mostafa',   '2022-02-01'),
 (7, 'Youssef Samir',  '2020-11-11'),
 (8, 'Laila Ibrahim',  '2023-04-03');

DO $$
DECLARE
    asof        CONSTANT DATE := DATE '2026-10-31';
    names TEXT[] := ARRAY[
      'ERP Rollout','Customer Portal','Data Warehouse','HQ Renovation','Regional Office Fit-out',
      'Network Upgrade','Youth Skills Program','Microfinance Outreach','Women Entrepreneurs Fund',
      'AI Pilot: Document OCR','Mobile App v2','Cybersecurity Hardening','Warehouse Automation',
      'Solar Rooftop','Community Health Units','Rural Training Centers','Innovation Challenge 2025',
      'Chatbot for Service Desk','BI Dashboards Suite','Fleet Management System','Records Digitization',
      'Vendor Portal','Smart Meeting Rooms','Startup Incubator Cohort 3'];
    ports INT[] := ARRAY[1,1,1,2,2,1,3,3,3,4,1,1,2,2,3,3,4,4,1,2,1,1,2,4];
    cats  TEXT[] := ARRAY['Schedule','Cost','Scope','Resource','Vendor','Regulatory'];
    p INT; T INT; perf NUMERIC; cf NUMERIC; s DATE; m INT; hold_at INT;
    planned NUMERIC; prev_planned NUMERIC; inc NUMERIC; actual NUMERIC; prev_actual NUMERIC; prev_cost NUMERIC; cost NUMERIC; bac NUMERIC;
    k INT; q NUMERIC; d DATE; r DATE;
    ms_id INT := 0; rk_id INT := 0; cr_id INT := 0;
BEGIN
  FOR p IN 1..24 LOOP
    T    := 8 + floor(random()*17)::INT;                       -- 8..24 months
    s    := (DATE '2024-01-01' + (floor(random()*27)::INT || ' months')::INTERVAL)::DATE;
    perf := round((0.72 + random()*0.38)::NUMERIC, 3);         -- schedule efficiency
    cf   := round((0.90 + random()*0.38)::NUMERIC, 3);         -- cost multiplier
    bac  := round((250000 + random()*4750000)::NUMERIC, -3);
    hold_at := CASE WHEN p IN (8, 20) THEN 5 ELSE NULL END;    -- two projects put on hold

    INSERT INTO projects VALUES (
      p, ports[p], 1 + (p % 8), names[p], s,
      (s + make_interval(months => T))::DATE, NULL, bac, 'Active');

    -- Monthly cumulative progress: planned follows an S-curve, actual is a
    -- random walk around it (scaled by the project's efficiency), never decreasing.
    prev_cost := 0; prev_actual := 0; prev_planned := 0; m := 1;
    WHILE (s + make_interval(months => m)) <= asof LOOP
      planned := LEAST(1, 0.5 - 0.5*cos(pi() * LEAST(m, T)::NUMERIC / T));
      inc     := CASE WHEN m <= T THEN planned - prev_planned ELSE 0.10 END;
      actual  := LEAST(1, prev_actual + inc * perf * (0.55 + random()::NUMERIC*0.9));
      IF hold_at IS NOT NULL AND m > hold_at THEN actual := prev_actual; END IF;
      cost := GREATEST(prev_cost, round(bac * actual * cf * (0.97 + random()::NUMERIC*0.06), 2));
      INSERT INTO monthly_progress VALUES
        (p, date_trunc('month', s + make_interval(months => m))::DATE,
         round(planned, 4), round(actual, 4), cost);
      prev_cost := cost; prev_actual := actual; prev_planned := planned;
      IF actual >= 1 THEN
        UPDATE projects
           SET status = 'Completed',
               actual_end_date = (s + make_interval(months => m) - (floor(random()*25)::INT || ' days')::INTERVAL)::DATE
         WHERE project_id = p;
        EXIT;
      END IF;
      m := m + 1;
    END LOOP;
    IF hold_at IS NOT NULL THEN
      UPDATE projects SET status = 'On Hold' WHERE project_id = p;
    END IF;

    -- Four milestones at 25/50/75/100% of planned duration; a milestone is achieved
    -- in the first month where actual progress reaches the planned value for that point.
    FOR k IN 1..4 LOOP
      ms_id := ms_id + 1; q := k * 0.25;
      d := (s + make_interval(days => round(T*q*30.4)::INT))::DATE;
      SELECT (min(report_month) - (floor(random()*25)::INT))::DATE INTO r
        FROM monthly_progress
       WHERE project_id = p AND actual_pct >= round((0.5 - 0.5*cos(pi()*q))::NUMERIC, 4) - 0.0001;
      INSERT INTO milestones VALUES (ms_id, p,
        (ARRAY['Design Approved','Mid-point Review','Testing / Handover Prep','Final Handover'])[k],
        d, CASE WHEN r IS NOT NULL THEN GREATEST(r, s + 7) END);
    END LOOP;

    -- Risks
    FOR k IN 1..(3 + floor(random()*6)::INT) LOOP
      rk_id := rk_id + 1;
      d := (s + make_interval(days => floor(random()*GREATEST(asof - s, 1))::INT))::DATE;
      r := CASE WHEN random() < 0.6 THEN d + (15 + floor(random()*105))::INT END;
      INSERT INTO risks VALUES (rk_id, p, cats[1 + floor(random()*6)::INT],
        1 + floor(random()*5)::INT, 1 + floor(random()*5)::INT, d,
        CASE WHEN r <= asof THEN r END);
    END LOOP;

    -- Change requests
    FOR k IN 1..floor(random()*5)::INT LOOP
      cr_id := cr_id + 1;
      d := (s + make_interval(days => floor(random()*GREATEST(asof - s, 1))::INT))::DATE;
      q := random();
      INSERT INTO change_requests VALUES (cr_id, p, d,
        CASE WHEN asof - d > 45 OR q < 0.7 THEN LEAST(asof, d + (5 + floor(random()*40))::INT) END,
        round((bac * (random()*0.12 - 0.02))::NUMERIC, -2),
        CASE WHEN asof - d <= 45 AND q >= 0.7 THEN 'Pending'
             WHEN random() < 0.72 THEN 'Approved' ELSE 'Rejected' END);
    END LOOP;
  END LOOP;
END $$;

-- -------------------------------------------------------------
-- Deliberately injected data-quality issues (caught by Q10),
-- mimicking what a PMO typically finds in real PM submissions.
-- -------------------------------------------------------------
DELETE FROM monthly_progress                                          -- missing report
WHERE (project_id, report_month) = (
    SELECT project_id, report_month FROM monthly_progress
    WHERE project_id = (SELECT min(project_id) FROM projects WHERE status = 'Active')
    ORDER BY report_month OFFSET 3 LIMIT 1);

WITH target AS (                                                      -- progress regression
    SELECT project_id, report_month,
           lag(actual_pct) OVER (PARTITION BY project_id ORDER BY report_month) AS prev_pct
    FROM monthly_progress
    WHERE project_id = (SELECT max(project_id) FROM projects WHERE status = 'Active')
    ORDER BY report_month OFFSET 4 LIMIT 1)
UPDATE monthly_progress mp
   SET actual_pct = GREATEST(t.prev_pct - 0.03, 0)
  FROM target t
 WHERE (mp.project_id, mp.report_month) = (t.project_id, t.report_month);

ANALYZE;
