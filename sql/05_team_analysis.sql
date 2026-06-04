-- ── Toss analysis: does winning toss help? ────────────────────────────────────
SELECT
    toss_decision,
    COUNT(*)                                            AS matches,
    SUM(CASE WHEN tosswinner = winner THEN 1 ELSE 0 END) AS toss_winner_won,
    ROUND(
        100.0 * SUM(CASE WHEN tosswinner = winner THEN 1 ELSE 0 END)
        / COUNT(*), 2
    )                                                   AS toss_win_rate_pct
FROM dim_match
WHERE winner IS NOT NULL AND winner != ''
GROUP BY toss_decision;


-- ── Toss win rate by team ─────────────────────────────────────────────────────
SELECT
    tosswinner                                         AS team,
    COUNT(*)                                            AS tosses_won,
    SUM(CASE WHEN tosswinner = winner THEN 1 ELSE 0 END) AS matches_won_after_toss,
    ROUND(
        100.0 * SUM(CASE WHEN tosswinner = winner THEN 1 ELSE 0 END)
        / COUNT(*), 2
    )                                                   AS win_rate_after_toss_pct
FROM dim_match
WHERE winner IS NOT NULL AND winner != ''
GROUP BY tosswinner
ORDER BY tosses_won DESC;


-- ── Overall team win record ───────────────────────────────────────────────────
WITH all_matches AS (
    SELECT team1 AS team, match_id FROM dim_match
    UNION ALL
    SELECT team2 AS team, match_id FROM dim_match
),
wins AS (
    SELECT winner AS team, COUNT(*) AS wins
    FROM dim_match
    WHERE winner IS NOT NULL AND winner != ''
    GROUP BY winner
)
SELECT
    am.team,
    COUNT(DISTINCT am.match_id)                         AS matches_played,
    COALESCE(w.wins, 0)                                 AS wins,
    COUNT(DISTINCT am.match_id) - COALESCE(w.wins, 0)  AS losses,
    ROUND(
        100.0 * COALESCE(w.wins, 0)
        / NULLIF(COUNT(DISTINCT am.match_id), 0), 2
    )                                                   AS win_pct
FROM all_matches am
LEFT JOIN wins w ON am.team = w.team
GROUP BY am.team, w.wins
ORDER BY win_pct DESC;


-- ── Average first innings score by season ────────────────────────────────────
WITH first_innings AS (
    SELECT
        match_id,
        season,
        SUM(total_runs)                                 AS innings_total
    FROM fact_deliveries
    WHERE inning = 1
    GROUP BY match_id, season
)
SELECT
    season,
    COUNT(match_id)                                     AS matches,
    ROUND(AVG(innings_total), 2)                        AS avg_first_innings_score,
    MAX(innings_total)                                  AS highest_score,
    MIN(innings_total)                                  AS lowest_score
FROM first_innings
GROUP BY season
ORDER BY season;


-- ── Venue analysis: bat-first vs chase win rate ───────────────────────────────
SELECT
    venue,
    COUNT(*)                                                        AS matches,
    SUM(CASE WHEN LOWER(won_by) = 'runs'    THEN 1 ELSE 0 END)    AS bat_first_wins,
    SUM(CASE WHEN LOWER(won_by) = 'wickets' THEN 1 ELSE 0 END)    AS chase_wins,
    SUM(CASE WHEN winner IS NULL
              OR winner = ''             THEN 1 ELSE 0 END)        AS no_result,
    ROUND(
        100.0 * SUM(CASE WHEN LOWER(won_by) = 'runs' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    )                                                               AS bat_first_win_pct,
    -- Winning margin when batting first (average runs defended)
    ROUND(
        AVG(CASE WHEN LOWER(won_by) = 'runs'
                 THEN margin::NUMERIC END), 1
    )                                                               AS avg_winning_margin_runs,
    -- Winning margin when chasing (average wickets in hand)
    ROUND(
        AVG(CASE WHEN LOWER(won_by) = 'wickets'
                 THEN margin::NUMERIC END), 1
    )                                                               AS avg_winning_margin_wickets
FROM dim_match
WHERE winner IS NOT NULL AND winner != ''
GROUP BY venue
HAVING COUNT(*) >= 10
ORDER BY bat_first_win_pct DESC;