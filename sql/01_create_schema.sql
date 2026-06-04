-- Primary keys
ALTER TABLE dim_team    ADD PRIMARY KEY (team_id);
ALTER TABLE dim_player  ADD PRIMARY KEY (player_id);
ALTER TABLE dim_match   ADD PRIMARY KEY (match_id);
ALTER TABLE fact_deliveries ADD PRIMARY KEY (delivery_id);

-- Indexes for common joins and filters
CREATE INDEX idx_fd_match    ON fact_deliveries (match_id);
CREATE INDEX idx_fd_batsman  ON fact_deliveries (batsman);
CREATE INDEX idx_fd_bowler   ON fact_deliveries (bowler);
CREATE INDEX idx_fd_season   ON fact_deliveries (season);
CREATE INDEX idx_fd_phase    ON fact_deliveries (phase);

-- Useful view: deliveries joined with match details
CREATE OR REPLACE VIEW v_deliveries AS
SELECT
    fd.*,
    dm.team1,
    dm.team2,
    dm.tosswinner,
    dm.toss_decision,
    dm.winner
FROM fact_deliveries fd
JOIN dim_match dm ON fd.match_id = dm.match_id;