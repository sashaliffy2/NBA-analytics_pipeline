# NBA Analytics Pipeline — 2025-26 Season

## Overview
An end-to-end data pipeline that scrapes NBA data from Basketball Reference, 
cleans and transforms it with Python, stores it in a PostgreSQL database, 
and analyzes it with SQL queries and visualizations.

Built as a personal project to develop hands-on experience with data 
pipelines, SQL analytics, and data visualization.

## Tech Stack
- **Python** — web scraping (BeautifulSoup, requests) and data cleaning (pandas)
- **PostgreSQL** — local database storage
- **SQL** — analysis and querying (PGAdmin 4)
- **Plotly** — interactive visualizations
- **Tableau Public** — dashboard (coming soon)

## Database Schema
Three tables connected via team abbreviation as foreign key:

| Table | Rows | Description |
|-------|------|-------------|
| `standings` | 30 | 2025-26 NBA standings with conference and team abbreviation |
| `rosters` | ~536 | All 30 team rosters with height, weight, experience, college |
| `player_stats` | ~661 | Full season totals for all players |

## Pipeline Flow
Basketball Reference → Python (scrape + clean) → PostgreSQL → SQL Analysis → Visualizations

## Some SQL Analysis
- Top scorers by PPG filtered by minimum games played
- Most complete players using NTILE window functions (top 25% in pts, reb, ast, stl, blk by position)
- Balanced scoring analysis using standard deviation of PPG by team
- Percentage of team points scored by top 3 players
- Weighted average age of playoff teams vs win totals
- Multi-table JOINs across standings, rosters, and player stats

## Status
- [x] Standings scraped and loaded
- [x] Rosters scraped and loaded
- [x] Player stats scraped and loaded
- [x] SQL analysis complete (PGAdmin 4)
- [ ] Plotly visualizations (in progress on pause working on another project)
- [ ] Tableau Public dashboard


## Author
Sasha — Data Analyst