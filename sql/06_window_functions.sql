-- ── W1: Season-wise top scorer using RANK ─────────────────────────────────────
WITH season_runs AS (
    SELECT
        season,
        batsman,
        SUM(batsman_runs)                               AS runs,
        RANK() OVER (
            PARTITION BY season
            ORDER BY SUM(batsman_runs) DESC
        )                                               AS season_rank
    FROM fact_deliveries
    GROUP BY season, batsman
)
SELECT season, batsman, runs, season_rank
FROM season_runs
WHERE season_rank <= 3
ORDER BY season, season_rank;


-- ── W2: Most wickets per season using DENSE_RANK ──────────────────────────────
WITH season_wickets AS (
    SELECT
        season,
        bowler,
        SUM(is_bowler_wicket)                           AS wickets,
        DENSE_RANK() OVER (
            PARTITION BY season
            ORDER BY SUM(is_bowler_wicket) DESC
        )                                               AS wicket_rank
    FROM fact_deliveries
    GROUP BY season, bowler
)
SELECT season, bowler, wickets, wicket_rank
FROM season_wickets
WHERE wicket_rank <= 3
ORDER BY season, wicket_rank;


-- ── W3: Season-on-season run rate change per phase using LAG ──────────────────
WITH phase_season AS (
    SELECT
        season,
        phase,
        ROUND(6.0 * SUM(total_runs)
              / NULLIF(SUM(is_legal_delivery), 0), 2)   AS run_rate
    FROM fact_deliveries
    GROUP BY season, phase
)
SELECT
    season,
    phase,
    run_rate,
    LAG(run_rate) OVER (
        PARTITION BY phase
        ORDER BY season
    )                                                   AS prev_season_rr,
    ROUND(
        run_rate - LAG(run_rate) OVER (
            PARTITION BY phase ORDER BY season
        ), 2
    )                                                   AS rr_change
FROM phase_season
ORDER BY phase, season;


-- ── W4: Player of the match awards count with rank ────────────────────────────
SELECT
    player_of_match,
    COUNT(*)                                            AS potm_awards,
    RANK() OVER (ORDER BY COUNT(*) DESC)                AS potm_rank
FROM dim_match
WHERE player_of_match IS NOT NULL AND player_of_match != ''
GROUP BY player_of_match
ORDER BY potm_rank
LIMIT 20;


-- ── W5: Running total of runs per batsman across seasons ──────────────────────
WITH season_totals AS (
    SELECT
        batsman,
        season,
        SUM(batsman_runs)                               AS season_runs
    FROM fact_deliveries
    GROUP BY batsman, season
),
top_batsmen AS (
    SELECT batsman
    FROM season_totals
    GROUP BY batsman
    HAVING SUM(season_runs) >= 2000
)
SELECT
    st.batsman,
    st.season,
    st.season_runs,
    SUM(st.season_runs) OVER (
        PARTITION BY st.batsman
        ORDER BY st.season
    )                                                   AS career_running_total
FROM season_totals st
JOIN top_batsmen tb ON st.batsman = tb.batsman
ORDER BY st.batsman, st.season;


-- ── W6: Over-by-over scoring pattern with rolling 3-over average ──────────────
WITH over_avg AS (
    SELECT
        over,
        ROUND(AVG(over_total), 2)                       AS avg_runs_per_over
    FROM (
        SELECT match_id, inning, over, SUM(total_runs)  AS over_total
        FROM fact_deliveries
        WHERE inning = 1
        GROUP BY match_id, inning, over
    ) sub
    GROUP BY over
)
SELECT
    over,
    avg_runs_per_over,
    ROUND(AVG(avg_runs_per_over) OVER (
        ORDER BY over
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                               AS rolling_3_over_avg
FROM over_avg
ORDER BY over;


-- ── W7: Batsmen consistency — NTILE quartiles by batting average ───────────────
WITH bat_avg AS (
    SELECT
        batsman,
        SUM(batsman_runs)                               AS runs,
        SUM(is_wicket)                                  AS dismissals,
        ROUND(
            SUM(batsman_runs)::NUMERIC
            / NULLIF(SUM(is_wicket), 0), 2
        )                                               AS batting_average
    FROM fact_deliveries
    GROUP BY batsman
    HAVING SUM(is_legal_delivery) >= 200
          AND SUM(is_wicket) >= 10
)
SELECT
    batsman,
    runs,
    batting_average,
    NTILE(4) OVER (ORDER BY batting_average)            AS consistency_quartile
FROM bat_avg
ORDER BY batting_average DESC;