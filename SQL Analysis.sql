--NBA Lineup Data cleaning

--Need to identify players with same name in player_data
-- CTE to identify duplicate players
WITH DuplicatePlayers AS (
    SELECT
        COUNT(*) AS player_count,
        player_name,
        season
    FROM player_data
    GROUP BY player_name, season
    HAVING COUNT(*) > 1
)

SELECT *
FROM DuplicatePlayers dp
LEFT JOIN player_data pd ON dp.player_name = pd.player_name AND dp.season = pd.season;

-- Going to create a copy of player_data to use for this project
CREATE TEMPORARY TABLE clean_player_data AS
    SELECT *
    FROM player_data;

-- for duplicates I will update the name to be something identifiable
UPDATE clean_player_data
SET player_name = 
    CASE 
        WHEN player_name = "Marcus Williams" AND season = "2007-08" AND team_abbreviation = "LAC" THEN "Marcus Williams LAC"
        WHEN player_name = "Marcus Williams" AND season = "2007-08" AND team_abbreviation = "NJN" THEN "Marcus Williams NJN"
        WHEN player_name = "Marcus Williams" AND season = "2008-09" AND team_abbreviation = "GSW" THEN "Marcus Williams GSW"
        WHEN player_name = "Marcus Williams" AND season = "2008-09" AND team_abbreviation = "LAC" THEN "Marcus Williams LAC"
        WHEN player_name = "Chris Johnson" AND season = "2012-13" AND team_abbreviation = "MEM" THEN "Chris Johnson MEM"
        WHEN player_name = "Chris Johnson" AND season = "2012-13" AND team_abbreviation = "MIN" THEN "Chris Johnson MIN"
        WHEN player_name = "Tony Mitchell" AND season = "2013-14" AND team_abbreviation = "DET" THEN "Tony Mitchell DET"
        WHEN player_name = "Tony Mitchell" AND season = "2013-14" AND team_abbreviation = "MIL" THEN "Marcus Williams MIL"
        ELSE player_name
    END  ;      

-- Validation for lineup data table
--First check to make sure that all lineups have 5 players
SELECT Name,
    PlayerOne,
    PlayerTwo,
    PlayerThree,
    PlayerFour,
    PlayerFive,
    TeamAbbreviation,
    SeasonName,
    SeasonType,
    SecondsPlayed
FROM lineup_data
WHERE  PlayerOne IS NULL OR
    PlayerTwo IS NULL OR
    PlayerThree IS NULL OR
    PlayerFour IS NULL OR
    PlayerFive IS NULL;

--No missing data
--Transforming data to have 1 player per line
CREATE TEMPORARY TABLE player_lineup_data AS
SELECT Name,
    PlayerOne as Player,
    TeamAbbreviation,
    SeasonName,
    SeasonType,
    SecondsPlayed
FROM lineup_data

UNION ALL

SELECT Name,
    PlayerTwo as Player,
    TeamAbbreviation,
    SeasonName,
    SeasonType,
    SecondsPlayed
FROM lineup_data

UNION ALL

SELECT Name,
    PlayerThree as Player,
    TeamAbbreviation,
    SeasonName,
    SeasonType,
    SecondsPlayed
FROM lineup_data

UNION ALL

SELECT Name,
    PlayerFour as Player,
    TeamAbbreviation,
    SeasonName,
    SeasonType,
    SecondsPlayed
FROM lineup_data

UNION ALL

SELECT Name,
    PlayerFive as Player,
    TeamAbbreviation,
    SeasonName,
    SeasonType,
    SecondsPlayed
FROM lineup_data
ORDER BY SeasonName,
    SeasonType,
    Name;

--Trim Whitespace and match duplicate names
UPDATE player_lineup_data
SET Player = 
    CASE 
        WHEN Player = "Marcus Williams" AND SeasonName = "2007-08" AND TeamAbbreviation = "LAC" THEN "Marcus Williams LAC"
        -- Marcus Williams was also on the SAS this year, but sticking to the team listed in player_data
        WHEN Player = "Marcus Williams" AND SeasonName = "2007-08" AND TeamAbbreviation = "SAS" THEN "Marcus Williams LAC"    
        WHEN Player = "Marcus Williams" AND SeasonName = "2007-08" AND TeamAbbreviation = "NJN" THEN "Marcus Williams NJN"
        WHEN Player = "Marcus Williams" AND SeasonName = "2008-09" AND TeamAbbreviation = "GSW" THEN "Marcus Williams GSW"
        WHEN Player = "Marcus Williams" AND SeasonName = "2008-09" AND TeamAbbreviation = "LAC" THEN "Marcus Williams LAC"
        WHEN Player = "Chris Johnson" AND SeasonName = "2012-13" AND TeamAbbreviation = "MEM" THEN "Chris Johnson MEM"
        WHEN Player = "Chris Johnson" AND SeasonName = "2012-13" AND TeamAbbreviation = "MIN" THEN "Chris Johnson MIN"
        WHEN Player = "Tony Mitchell" AND SeasonName = "2013-14" AND TeamAbbreviation = "DET" THEN "Tony Mitchell DET"
        WHEN Player = "Tony Mitchell" AND SeasonName = "2013-14" AND TeamAbbreviation = "MIL" THEN "Marcus Williams MIL"
        ELSE TRIM(Player)
    END;

--join on height and order
SELECT Name,
    Player,
    player_height as PlayerHeight,
    TeamAbbreviation,
    SeasonName,
    SeasonType,
    SecondsPlayed
FROM player_lineup_data
LEFT JOIN clean_player_data
ON Player = clean_player_data.player_name AND SeasonName = clean_player_data.season
ORDER BY SeasonName,
    SeasonType,
    Name,
    PlayerHeight;
-- Have expected number of rows (5x lineup_data)
    
--find missing height values
SELECT DISTINCT
    Player,
    SeasonName,
    player_height as PlayerHeight
FROM player_lineup_data
LEFT JOIN clean_player_data
ON Player = clean_player_data.player_name AND SeasonName = clean_player_data.season
WHERE PlayerHeight IS NULL
ORDER BY SeasonName;    

--fill in values that are missing with those players from other years
SELECT 
    Player,
    SeasonName,
    max(player_height) as PlayerHeight --max height is most accurate
    --from query above that is finding null values in height
    FROM (
        SELECT DISTINCT
             Player,
             SeasonName,
             player_height as PlayerHeight
         FROM player_lineup_data
         LEFT JOIN clean_player_data
         ON Player = clean_player_data.player_name AND SeasonName = clean_player_data.season
         WHERE PlayerHeight IS NULL
         ORDER BY SeasonName)
LEFT JOIN clean_player_data
ON Player = clean_player_data.player_name -- Join is just on the name
GROUP BY Player,
    SeasonName
ORDER BY PlayerHeight;

--"Patrick Baldwin" has inconsistent names in player_data, so updating them
UPDATE player_lineup_data
SET Player = 
    CASE 
        WHEN Player = "Patrick Baldwin Jr." AND SeasonName = "2022-23" THEN "Patrick Baldwin"
        ELSE Player
    END;    
    
-- Update clean_player_data to have the same names as lineup_data
UPDATE clean_player_data
SET player_name = 
    CASE
        WHEN player_name = "Charlie Brown Jr." AND season = "2019-20" THEN "Charles Brown Jr."
        WHEN player_name = "Juancho Hernangomez" AND season = "2016-17" THEN "Juan Hernangomez"
        WHEN player_name = "Kevin Knox II" AND season = "2018-19" THEN "Kevin Knox"
        WHEN player_name = "Charlie Brown" AND season = "2021-22" THEN "Luca Vildoza"
        WHEN player_name = "M.J. Walker" AND season = "2021-22" THEN "MJ Walker"
        WHEN player_name = "Michael Frazier II" AND season = "2019-20" THEN "Michael Frazier"
        WHEN player_name = "Walt Lemon Jr." AND season = "2017-18" THEN "Walter Lemon Jr."
        WHEN player_name = "Walt Lemon Jr." AND season = "2018-19" THEN "Walter Lemon Jr."
        ELSE player_name
    END;

--There is no data for Luca Vildoza, so need to add that row to clean_player_data
INSERT INTO clean_player_data (player_name, player_height, season)
VALUES ("Luca Vildoza", 190, "2021-22");

--Saving this table off for the missing values
CREATE TEMPORARY TABLE max_height as 
SELECT 
    Player,
    SeasonName,
    max(player_height) as PlayerHeight --max height is most accurate
    --from query above that is finding null values in height
    FROM (
        SELECT DISTINCT
             Player,
             SeasonName,
             player_height as PlayerHeight
         FROM player_lineup_data
         LEFT JOIN clean_player_data
         ON Player = clean_player_data.player_name AND SeasonName = clean_player_data.season
         WHERE PlayerHeight IS NULL
         ORDER BY SeasonName)
LEFT JOIN clean_player_data
ON Player = clean_player_data.player_name -- Join is just on the name
GROUP BY Player,
    SeasonName
ORDER BY PlayerHeight;

CREATE TEMPORARY TABLE clean_pld AS
SELECT *,
    CASE (ROW_NUMBER() OVER () - 1) % 5 + 1
        WHEN 1 THEN "PG"
        WHEN 2 THEN "SG"
        WHEN 3 THEN "SF"
        WHEN 4 THEN "PF"
        WHEN 5 THEN "C"
    END AS Position
FROM (
    SELECT Name as Lineup,
        pld.Player,
        TeamAbbreviation,
        pld.SeasonName,
        SeasonType,
        SecondsPlayed,
        CASE
            WHEN cpd.player_height IS NOT NULL THEN cpd.player_height
            ELSE mh.PlayerHeight
        END AS PlayerHeight
    FROM player_lineup_data as pld
    LEFT JOIN clean_player_data as cpd
    ON pld.Player = cpd.player_name AND pld.SeasonName = cpd.season
    LEFT JOIN max_height as mh
    ON pld.Player = mh.Player AND pld.SeasonName = mh.SeasonName
    ORDER BY pld.SeasonName,
        pld.SeasonType,
        Lineup,
        PlayerHeight
) AS ordered_pld;

-- Add in position

SELECT Position,
    Player,
    SeasonName,
    TeamAbbreviation,
    PlayerHeight,
    SeasonType,
    SUM(SecondsPlayed) as SecondsPlayed
FROM clean_pld
GROUP BY Position,
    SeasonName,
    TeamAbbreviation,
    PlayerHeight,
    SeasonType;

-- Create table for weighted average height at each position
CREATE TEMPORARY TABLE weighted_avg_height AS
SELECT
    Position,
    TeamAbbreviation,
    SeasonName,
    SeasonType,
    SUM(SecondsPlayed) as SecondsPlayed,
    SUM(PlayerHeight * SecondsPlayed) / SUM(SecondsPlayed) AS WeightedAverageHeight
FROM
    clean_pld
WHERE SeasonType = "Regular Season"
GROUP BY
    Position,
    TeamAbbreviation,
    SeasonName,
    SeasonType
ORDER BY 
    SeasonName,
    TeamAbbreviation,
    SeasonType,
    Position;

-- Create Table defining players as over or undersized
CREATE TEMPORARY TABLE plyr_pos_cat AS
SELECT cpld.Position,
    cpld.Player,
    cpld.TeamAbbreviation,
    cpld.SeasonName,
    cpld.SeasonType,
    WeightedAverageHeight,
    cpld.PlayerHeight,
    CASE
        WHEN PlayerHeight<WeightedAverageHeight THEN "Undersized"
        WHEN PlayerHeight>=WeightedAverageHeight THEN "Oversized"
    END AS Size,
    PlayerHeight-WeightedAverageHeight AS HeightAboveAverage
FROM (
    SELECT Position,
         Player,
         TeamAbbreviation,
         SeasonName,
         SeasonType,
         SUM(SecondsPlayed) as SecondsPlayed,
         PlayerHeight
     FROM clean_pld 
     GROUP BY Player,
         Position,
         TeamAbbreviation,
         SeasonName,
         SeasonType,
         PlayerHeight) AS cpld
LEFT JOIN weighted_avg_height wah
ON cpld.Position = wah.Position AND
    cpld.TeamAbbreviation = wah.TeamAbbreviation AND
    cpld.SeasonName = wah.SeasonName
ORDER BY cpld.SeasonName,
    cpld.TeamAbbreviation,
    cpld.SeasonType,
    cpld.Position,
    cpld.PlayerHeight;
    
-- Create table for teams that made the playoffs and not
SELECT TeamAbbreviation,
    SeasonName,
    MAX(Playoffs) as Playoffs
FROM (
SELECT TeamAbbreviation,
    SeasonType,
    SeasonName,
    CASE
        WHEN SeasonType = "Regular Season" THEN 0
        WHEN SeasonType = "Playoffs" THEN 1
        ELSE NULL
    END AS Playoffs
FROM lineup_data)
GROUP BY TeamAbbreviation,
    SeasonName;

-- Join additional metrics on clean_pld
SELECT
    TeamID,
    Name,
    TeamAbbreviation,
    SeasonName,
    SeasonEndYr,
    SeasonType,
    SecondsPlayed,
    Minutes,
    PlusMinus,
    OffPoss,
    DefPoss,
    Points,
    OpponentPoints