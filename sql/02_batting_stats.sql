-- ── Overall career batting stats ──────────────────────────────────────────────
-- Minimum 200 balls faced for meaningful strike rate
SELECT
    batsman,
    SUM(batsman_runs)                                   AS total_runs,
    SUM(is_legal_delivery)                              AS balls_faced,
    COUNT(DISTINCT match_id)                            AS matches,
    SUM(is_boundary)                                    AS boundaries,
    SUM(is_six)                                         AS sixes,
    SUM(is_four)                                        AS fours,
    ROUND(
        100.0 * SUM(batsman_runs)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS strike_rate,
    ROUND(
        SUM(batsman_runs)::NUMERIC
        / NULLIF(SUM(is_wicket), 0), 2
    )                                                   AS batting_average,
    ROUND(
        100.0 * SUM(is_boundary)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS boundary_pct,
    ROUND(
        100.0 * SUM(is_dot_ball)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS dot_ball_pct
FROM fact_deliveries
GROUP BY batsman
HAVING SUM(is_legal_delivery) >= 200
ORDER BY total_runs DESC;


-- ── Batting stats in DEATH OVERS (16–20) ─────────────────────────────────────
-- Top 20 finishers by strike rate (min 50 balls in death overs)
SELECT
    batsman,
    SUM(batsman_runs)                                   AS death_runs,
    SUM(is_legal_delivery)                              AS death_balls,
    SUM(is_six)                                         AS sixes,
    SUM(is_boundary)                                    AS boundaries,
    ROUND(
        100.0 * SUM(batsman_runs)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS death_strike_rate
FROM fact_deliveries
WHERE phase = 'Death (16-20)'
GROUP BY batsman
HAVING SUM(is_legal_delivery) >= 50
ORDER BY death_strike_rate DESC
LIMIT 20;


-- ── Batting stats in POWERPLAY (1–6) ─────────────────────────────────────────
SELECT
    batsman,
    SUM(batsman_runs)                                   AS pp_runs,
    SUM(is_legal_delivery)                              AS pp_balls,
    ROUND(
        100.0 * SUM(batsman_runs)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS pp_strike_rate,
    ROUND(
        100.0 * SUM(is_boundary)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS pp_boundary_pct
FROM fact_deliveries
WHERE phase = 'Powerplay (1-6)'
GROUP BY batsman
HAVING SUM(is_legal_delivery) >= 50
ORDER BY pp_strike_rate DESC
LIMIT 20;


-- ── Season-wise batting leaders ───────────────────────────────────────────────
SELECT
    season,
    batsman,
    SUM(batsman_runs)                                   AS season_runs,
    ROUND(
        100.0 * SUM(batsman_runs)
        / NULLIF(SUM(is_legal_delivery), 0), 2
    )                                                   AS season_sr
FROM fact_deliveries
GROUP BY season, batsman
HAVING SUM(is_legal_delivery) >= 50
ORDER BY season, season_runs DESC;