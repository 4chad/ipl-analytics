-- ── Overall career bowling stats ──────────────────────────────────────────────
-- Min 50 overs bowled (300 legal deliveries)
SELECT
    bowler,
    SUM(is_legal_delivery)                              AS balls_bowled,
    ROUND(SUM(is_legal_delivery) / 6.0, 1)             AS overs_bowled,
    SUM(total_runs) - SUM(wide_runs) - SUM(noball_runs) AS runs_conceded,
    SUM(is_bowler_wicket)                               AS wickets,
    COUNT(DISTINCT match_id)                            AS matches,
    -- Economy: runs per over
    ROUND(
        6.0 * (SUM(total_runs) - SUM(wide_runs) - SUM(noball_runs))
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS economy_rate,
    -- Bowling average: runs per wicket
    ROUND(
        (SUM(total_runs) - SUM(wide_runs) - SUM(noball_runs))::NUMERIC
        / NULLIF(SUM(is_bowler_wicket), 0), 2
    )                                                   AS bowling_average,
    -- Bowling strike rate: balls per wicket
    ROUND(
        SUM(is_legal_delivery)::NUMERIC
        / NULLIF(SUM(is_bowler_wicket), 0), 2
    )                                                   AS bowling_strike_rate,
    -- Dot ball %
    ROUND(
        100.0 * SUM(is_dot_ball)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS dot_ball_pct
FROM fact_deliveries
GROUP BY bowler
HAVING SUM(is_legal_delivery) >= 300
ORDER BY wickets DESC;


-- ── Most economical bowlers in POWERPLAY (1–6) ───────────────────────────────
SELECT
    bowler,
    SUM(is_legal_delivery)                              AS pp_balls,
    SUM(is_bowler_wicket)                               AS pp_wickets,
    ROUND(
        6.0 * SUM(total_runs)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS pp_economy,
    ROUND(
        100.0 * SUM(is_dot_ball)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS pp_dot_pct
FROM fact_deliveries
WHERE phase = 'Powerplay (1-6)'
GROUP BY bowler
HAVING SUM(is_legal_delivery) >= 60
ORDER BY pp_economy ASC
LIMIT 20;


-- ── Most economical bowlers in DEATH OVERS (16–20) ───────────────────────────
SELECT
    bowler,
    SUM(is_legal_delivery)                              AS death_balls,
    SUM(is_bowler_wicket)                               AS death_wickets,
    ROUND(
        6.0 * SUM(total_runs)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS death_economy,
    ROUND(
        100.0 * SUM(is_dot_ball)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS death_dot_pct
FROM fact_deliveries
WHERE phase = 'Death (16-20)'
GROUP BY bowler
HAVING SUM(is_legal_delivery) >= 60
ORDER BY death_economy ASC
LIMIT 20;


-- ── Wicket types distribution ─────────────────────────────────────────────────
SELECT
    dismissal_kind,
    COUNT(*)                                            AS wicket_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2)  AS pct_of_wickets
FROM fact_deliveries
WHERE dismissal_kind NOT IN ('not_out', '')
GROUP BY dismissal_kind
ORDER BY wicket_count DESC;