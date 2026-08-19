-- Best FT shooters with at least 100 attempts
SELECT player, ft_pct, fta from player_stats
WHERE fta > 100
ORDER BY ft_pct DESC
LIMIT 10;

--Players with more blocks than turnovers (min 10 blocks)
SELECT player, blk, tov 
FROM player_stats
WHERE blk > tov
AND blk > 10;

--Double Double Machines (Averaged a double double)
SELECT * FROM(
SELECT player, ROUND(pts::numeric/games,1) as ppg, 
ROUND(trb::numeric/games,1) as rpg, 
ROUND(ast::numeric/games,1) as apg, 
ROUND(stl::numeric/games,1) as spg,
ROUND(blk::numeric/games,1) as bpg
FROM player_stats
WHERE games >40
) sub
WHERE (rpg >10 AND apg > 10)
OR (ppg>10 AND RPG > 10)
OR (ppg>10 AND apg > 10)
ORDER BY ppg DESC;

--check APG
SELECT * FROM( 
SELECT Player, ROUND(pts::numeric/games,1) as ppg, ROUND(ast::numeric/games,1) as apg
FROM player_stats
WHERE games > 40
)sub
WHERE apg > 8
ORDER BY apg DESC;

-- Youngest players in the league
SELECT player, age
FROM player_stats
ORDER BY age ASC
limit 20;

--Most efficient scorers (pts per min)
SELECT player, pts, ROUND(pts::numeric/minutes,4) as ppm
FROM player_stats
WHERE games > 40
ORDER BY ppm DESC;

-- Best rebounders by position.
SELECT * FROM (
SELECT player, pos, games, trb, ROUND(trb::numeric/games,1) as rpg,
RANK() over (PARTITION BY pos ORDER BY trb::numeric/games DESC) as rank_in_pos
FROM player_stats
WHERE games > 40
GROUP BY player, pos, games, trb
ORDER BY pos, rpg DESC
) sub
WHERE rank_in_pos <=1
ORDER BY trb DESC;

-- Best rookies this season
SELECT * FROM (
SELECT 
r.player, 
r.position, 
r.experience, 
ps.team, ps.games, ps.minutes, 
ROUND(ps.pts::numeric/games,1) as ppg, 
ROUND(ps.ast::numeric/games,1) as apg, 
ROUND(ps.trb::numeric/games,1) as rpg, 
ps.efg_pct  
FROM rosters as r
JOIN player_stats as ps ON r.player = ps.player AND r.team = ps.team
WHERE r.experience = 0 AND ps.games > 40
) sub
ORDER BY ppg DESC
LIMIT 10;


-- Which college produces the most NBA players
SELECT 
TRIM(SPLIT_PART(r.college, ',', -1)) as last_college,
COUNT(ps.player)
FROM rosters as r
JOIN player_stats as ps ON r.player = ps.player AND r.team = ps.team
WHERE college IS NOT NULL AND college != ''
GROUP BY r.college
ORDER BY COUNT(ps.player) DESC;


-- Best scorers from each conference
SELECT * FROM (
SELECT s.conference, 
ps.player,
RANK() over (PARTITION BY s.conference ORDER BY ps.pts::numeric/games DESC) as rank_in_conf,
ROUND(ps.pts::numeric/games,1) as ppg,
s.team, 
s.wins
FROM standings as s JOIN rosters as r ON s.team_abbrev = r.team
JOIN player_stats as ps ON r.team = ps.team AND r.player = ps.player
GROUP BY s.team, s.wins, s.conference, ps.player, ps.pts, ps.games
ORDER BY ppg
) sub
WHERE rank_in_conf <= 5
ORDER BY conference, ppg DESC;

-- Top Performers (PPG) on lottery teams.
SELECT * FROM (
SELECT s.team, s.wins, ps.player, ROUND(ps.pts::numeric/games,1) as ppg, ps.games
FROM standings as s
JOIN player_stats as ps ON s.team_abbrev = ps.team
WHERE wins < 45 and ps.games > 40
AND team_abbrev NOT LIKE 'POR'
GROUP BY s.team, s.wins, ps.player, ps.pts, ps.games
)sub
ORDER BY ppg DESC
LIMIT 10;

-- Gonzaga Alumni stats this season
SELECT * FROM (
SELECT ps.player, ps.team, ROUND(ps.pts::numeric/games,1) as ppg, 
ROUND(ps.trb::numeric/games,1) as rpg,
ROUND(ps.ast::numeric/games,1) as apg,
TRIM(SPLIT_PART(r.college, ',', -1)) as last_college
FROM rosters as r JOIN player_stats as ps ON r.team = ps.team 
AND r.player = ps.player
) sub
WHERE last_college LIKE 'Gonzaga'
ORDER BY ppg DESC;

--Tallest players and their scoring averages
SELECT r.player, r.height as height_inches, 
CONCAT(FLOOR(height / 12), '''', (height % 12), '"') AS height_ft,
ROUND(ps.pts::numeric/games,1) as ppg, CONCAT(ROUND(ps.fg_pct::numeric * 100,1), '%')as fg_pct
FROM rosters as r 
JOIN player_stats as ps ON r.team = ps.team AND r.player = ps.player
ORDER BY height DESC;

-- Highest scoring player on each lottery team
SELECT * FROM (
SELECT s.team, s.wins, ps.player, 
RANK() over (PARTITION BY s.team ORDER BY ROUND(ps.pts::numeric/ps.games,1 ) DESC) as rank_by_team, 
ROUND(ps.pts::numeric/ps.games,1) as ppg, ps.games
FROM standings as s
JOIN player_stats as ps ON ps.team = s.team_abbrev
WHERE wins < 45 and ps.games > 40
AND team_abbrev <> 'POR'
GROUP BY s.team, s.wins, ps.player, ps.pts, ps.games
) sub
WHERE rank_by_team = 1

-- highest scoring player on each team
SELECT * FROM(
SELECT player, team, 
RANK() over (PARTITION BY team ORDER BY ROUND(pts::numeric/games,1 ) DESC) as rank_by_team,
ROUND(pts::numeric/games,1) as ppg
FROM player_stats
) sub
WHERE rank_by_team = 1

-- Teams with best assist to turnover ratios

SELECT team, SUM(ast), SUM(TOV), 
ROUND(SUM(ast)::numeric/NULLIF(SUM(tov),0)::numeric, 1) as ast_tov_ratio
FROM player_stats
GROUP BY team
ORDER BY ast_tov_ratio DESC

Select * FROM rosters

-- Average age of each team
SELECT team, ROUND(AVG(EXTRACT(YEAR FROM(AGE(birth_date)))),2) as avg_age
FROM rosters
GROUP BY team
ORDER BY avg_age ASC

-- average age of each team weighted by minutes
SELECT team, ROUND(SUM(eage * minutes) / sum(minutes),2) as weighted 
FROM (
SELECT ps.team, ps.player, ROUND(EXTRACT(YEAR FROM(AGE(r.birth_date))),2) as eage, ps.minutes
FROM player_stats as ps
JOIN rosters as r on ps.player = r.player
) sub
GROUP BY team
ORDER BY weighted ASC

-- average age of each team weighted by minutes (playoff teams only)
SELECT team, ROUND(SUM(eage * minutes) / sum(minutes),2) as weighted 
FROM (
SELECT ps.team, ps.player, ROUND(EXTRACT(YEAR FROM(AGE(r.birth_date))),2) as eage, ps.minutes
FROM player_stats as ps
JOIN rosters as r on ps.player = r.player
) sub
WHERE team NOT IN (SELECT team_abbrev FROM standings
WHERE wins < 45 AND team_abbrev <> 'POR')
GROUP BY team
ORDER BY weighted ASC

SELECT team_abbrev FROM standings
WHERE wins < 45 AND team_abbrev <> 'POR'

-- add wins to previous 
SELECT s2.team, s.wins, s2.weighted as weight_min_by_age
FROM standings as s JOIN
(
SELECT team, ROUND(SUM(eage * minutes) / sum(minutes),2) as weighted 
FROM (
SELECT ps.team, ps.player, ROUND(EXTRACT(YEAR FROM(AGE(r.birth_date))),2) as eage, ps.minutes
FROM player_stats as ps
JOIN rosters as r on ps.player = r.player
) sub
WHERE team NOT IN (SELECT team_abbrev FROM standings
WHERE wins < 45 AND team_abbrev <> 'POR')
GROUP BY team
ORDER BY weighted ASC) s2
ON s.team_abbrev = s2.team
ORDER BY s.wins DESC


--For each team wht % of their total points come from their top 3 scoreres
-- Start with one team, then expand

-- top 3 players BOS
SELECT player, pts, games,
RANK() OVER (PARTITION BY team ORDER BY pts DESC) as rank_total_pts
FROM player_stats as ps
WHERE team = 'BOS'
LIMIT 3

-- sum of top 3 players
SELECT ROUND(SUM(pts) :: numeric, 0)
FROM (SELECT player, pts, games,
RANK() OVER (PARTITION BY team ORDER BY pts DESC) as rank_total_pts
FROM player_stats as ps
WHERE team = 'BOS'
LIMIT 3) sub

--BOS total points
SELECT ROUND(SUM(pts):: numeric, 0)
FROM player_stats
WHERE team ='BOS'
GROUP BY team

-- %

SELECT ROUND((SELECT ROUND(SUM(pts) :: numeric, 0)
FROM (SELECT player, pts, games,
RANK() OVER (PARTITION BY team ORDER BY pts DESC) as rank_total_pts
FROM player_stats as ps
WHERE team = 'BOS'
LIMIT 3)) / (SELECT ROUND(SUM(pts):: numeric, 0)
FROM player_stats
WHERE team ='BOS'
GROUP BY team)::numeric, 2) as pct_of_points_scored_by_top_3

-- top 3 players total points by team
SELECT team, ROUND(SUM(pts)::numeric,0) as pts_top_3 FROM
(SELECT player, team, pts, games,
RANK() OVER (PARTITION BY team ORDER BY pts DESC) as rank_total_pts
FROM player_stats as ps) as sub
WHERE rank_total_pts <= 3
GROUP BY team


--Total points team
SELECT team, ROUND(SUM(pts)::numeric, 0) as total_pts
FROM player_stats
GROUP BY team

-- For each team, what % of their points came from top 3 scorers
SELECT top_3.team, top_3.pts_top_3, team_total.total_pts, 
ROUND(top_3.pts_top_3/team_total.total_pts::numeric, 3) as pct_top_3 FROM
(SELECT team, ROUND(SUM(pts)::numeric,0) as pts_top_3 FROM
(SELECT player, team, pts, games,
RANK() OVER (PARTITION BY team ORDER BY pts DESC) as rank_total_pts
FROM player_stats as ps) as sub
WHERE rank_total_pts <= 3
GROUP BY team) top_3 
JOIN
(SELECT team, ROUND(SUM(pts)::numeric, 0) as total_pts
FROM player_stats
GROUP BY team) team_total ON top_3.team = team_total.team
ORDER BY pct_top_3 DESC

-- which teams have the most balanced scoring 
--(lowest standard Dev across scorers)
SELECT team, ROUND(MAX(wins)::numeric,0) as wins, ROUND(STDDEV(ppg) :: numeric, 2) as std_ppg
FROM (
SELECT ps.player, ps.team, s.wins, ROUND(ps.pts:: numeric / ps.games, 1) as ppg 
FROM player_stats as ps 
JOIN standings as s ON ps.team = s.team_abbrev
WHERE games > 10) sub
GROUP BY team
ORDER BY std_ppg asc

-- TOP 3 scoreres per team (Edit team name)
-- top 3 players
SELECT player, pts, games,
RANK() OVER (PARTITION BY team ORDER BY pts DESC) as rank_total_pts
FROM player_stats as ps
WHERE team = 'BOS'
LIMIT 3


--Find players who are above avg in pts reb and ast compared to their peers

SELECT * 
FROM( 
SELECT player, games, team, pos, ROUND(pts::numeric/games, 1) as ppg, 
ROUND(AVG(pts::numeric/games) OVER(PARTITION BY pos),1) as avg_ppg_pos,
ROUND(trb::numeric/games,1) as rpg, 
ROUND(AVG(trb::numeric/games) OVER(PARTITION BY pos),1) avg_rpg_pos,
ROUND(ast::numeric/games,1) as apg,
ROUND(AVG(ast::numeric/games) OVER(PARTITION BY pos),1) avg_ast_pos
FROM player_stats) sub
WHERE ppg > avg_ppg_pos
AND rpg > avg_rpg_pos
AND apg > avg_ast_pos
AND games > 50

SELECT * FROM player_stats

-- players percentile for ppg
SELECT player, pos, ROUND(pts::numeric/games, 1) as ppg, 
NTILE(4) OVER (ORDER BY ROUND(pts::numeric/games, 1) DESC)
FROM player_stats
WHERE games > 40

-- Most complete player(Top 25% in pts, reb, ast, stl, blk) NTILE()
SELECT * FROM
(
SELECT player, ROUND(pts::numeric/games, 1) as ppg, 
NTILE(4) OVER (ORDER BY ROUND(pts::numeric/games, 1) DESC) pts_ntile, 
ROUND(trb::numeric/games, 1) as rpg,
NTILE(4) OVER (ORDER BY ROUND(trb::numeric/games, 1) DESC) reb_ntile, 
ROUND(ast::numeric/games, 1) as apg, 
NTILE(4) OVER (ORDER BY ROUND(ast::numeric/games, 1) DESC) ast_ntile,
ROUND(stl::numeric/games, 1) as spg, 
NTILE(4) OVER (ORDER BY ROUND(stl::numeric/games, 1) DESC) stl_ntile, 
ROUND(blk::numeric/games, 1) as bpg, 
NTILE(4) OVER (ORDER BY ROUND(blk::numeric/games, 1) DESC) blk_ntile
FROM player_stats
WHERE games > 40) 
WHERE pts_ntile = 1 AND reb_ntile = 1 
AND ast_ntile = 1 AND stl_ntile = 1 AND blk_ntile = 1


-- Most complete player(Top 25% in their POS pts, reb, ast, stl, blk) NTILE()
SELECT * FROM
(
SELECT player, pos, ROUND(pts::numeric/games, 1) as ppg, 
NTILE(4) OVER (PARTITION BY pos ORDER BY ROUND(pts::numeric/games, 1) DESC) pts_ntile, 
ROUND(trb::numeric/games, 1) as rpg,
NTILE(4) OVER (PARTITION BY pos ORDER BY ROUND(trb::numeric/games, 1) DESC) reb_ntile, 
ROUND(ast::numeric/games, 1) as apg, 
NTILE(4) OVER (PARTITION BY pos ORDER BY ROUND(ast::numeric/games, 1) DESC) ast_ntile,
ROUND(stl::numeric/games, 1) as spg, 
NTILE(4) OVER (PARTITION BY pos ORDER BY ROUND(stl::numeric/games, 1) DESC) stl_ntile, 
ROUND(blk::numeric/games, 1) as bpg, 
NTILE(4) OVER (PARTITION BY pos ORDER BY ROUND(blk::numeric/games, 1) DESC) blk_ntile
FROM player_stats
WHERE games > 40) as sub
WHERE pts_ntile = 1 AND reb_ntile = 1 
AND ast_ntile = 1 AND stl_ntile = 1 AND blk_ntile = 1