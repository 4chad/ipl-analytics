-- ── Run rate by phase across all seasons ──────────────────────────────────────
SELECT
    phase,
    SUM(total_runs)                                     AS total_runs,
    SUM(is_legal_delivery)                              AS total_balls,
    ROUND(6.0 * SUM(total_runs)
          / NULLIF(SUM(is_legal_delivery), 0), 2)       AS run_rate,
    ROUND(100.0 * SUM(is_boundary)
          / NULLIF(SUM(is_legal_delivery), 0), 2)       AS boundary_pct,
    ROUND(100.0 * SUM(is_dot_ball)
          / NULLIF(SUM(is_legal_delivery), 0), 2)       AS dot_ball_pct,
    SUM(is_wicket)                                      AS wickets
FROM fact_deliveries
GROUP BY phase
ORDER BY phase;


-- ── Phase run rate trend by season ────────────────────────────────────────────
SELECT
    season,
    phase,
    ROUND(6.0 * SUM(total_runs)
          / NULLIF(SUM(is_legal_delivery), 0), 2)       AS run_rate,
    ROUND(100.0 * SUM(is_boundary)
          / NULLIF(SUM(is_legal_delivery), 0), 2)       AS boundary_pct
FROM fact_deliveries
GROUP BY season, phase
ORDER BY season, phase;


-- ── CTE: Batsman phase profile ────────────────────────────────────────────────
-- Compare same batsman across all three phases
WITH phase_stats AS (
    SELECT
        batsman,
        phase,
        SUM(batsman_runs)                               AS runs,
        SUM(is_legal_delivery)                          AS balls,
        ROUND(
            100.0 * SUM(batsman_runs)
            / NULLIF(SUM(is_legal_delivery), 0), 2
        )                                               AS strike_rate,
        ROUND(
            100.0 * SUM(is_boundary)
            / NULLIF(SUM(is_legal_delivery), 0), 2
        )                                               AS boundary_pct
    FROM fact_deliveries
    GROUP BY batsman, phase
    HAVING SUM(is_legal_delivery) >= 30
),
overall AS (
    SELECT batsman, SUM(runs) AS total_runs
    FROM phase_stats
    GROUP BY batsman
    HAVING SUM(balls) >= 200
)
SELECT
    ps.batsman,
    ps.phase,
    ps.runs,
    ps.balls,
    ps.strike_rate,
    ps.boundary_pct
FROM phase_stats ps
JOIN overall o ON ps.batsman = o.batsman
ORDER BY o.total_runs DESC, ps.batsman, ps.phase;


-- ── CTE: Bowler phase profile ─────────────────────────────────────────────────
WITH bowler_phase AS (
    SELECT
        bowler,
        phase,
        SUM(is_legal_delivery)                          AS balls,
        SUM(is_bowler_wicket)                           AS wickets,
        ROUND(
            6.0 * SUM(total_runs)
            / NULLIF(SUM(is_legal_delivery), 0), 2
        )                                               AS economy,
        ROUND(
            100.0 * SUM(is_dot_ball)
            / NULLIF(SUM(is_legal_delivery), 0), 2
        )                                               AS dot_pct
    FROM fact_deliveries
    GROUP BY bowler, phase
    HAVING SUM(is_legal_delivery) >= 30
),
top_bowlers AS (
    SELECT bowler, SUM(wickets) AS total_wickets
    FROM bowler_phase
    GROUP BY bowler
    HAVING SUM(balls) >= 300
    ORDER BY total_wickets DESC
    LIMIT 30
)
SELECT
    bp.bowler,
    bp.phase,
    bp.balls,
    bp.wickets,
    bp.economy,
    bp.dot_pct
FROM bowler_phase bp
JOIN top_bowlers tb ON bp.bowler = tb.bowler
ORDER BY tb.total_wickets DESC, bp.bowler, bp.phase;


-- ── First innings score by over — cumulative run buildup ─────────────────────
SELECT
    over,
    ROUND(AVG(over_runs), 2)                            AS avg_over_runs,
    ROUND(AVG(SUM(over_runs)) OVER (
        ORDER BY over
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                               AS avg_cumulative_runs
FROM (
    SELECT
        match_id,
        over,
        SUM(total_runs)                                 AS over_runs
    FROM fact_deliveries
    WHERE inning = 1
    GROUP BY match_id, over
) over_scores
GROUP BY over
ORDER BY over;