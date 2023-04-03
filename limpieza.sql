USE olympic_games;

-- SEPARO AÑO DE GAMES PARA CALCULAR AGE Y PARA SEPARARLO DE LA ESTACIÓN
SELECT 
	ID as ID_athletes
	, Name
	, Sex
	, Age
	, Height
	, Weight
	, NOC
	, SUBSTRING(Games, 1, CHARINDEX(' ', Games) - 1) as Year, 
		SUBSTRING(Games, CHARINDEX(' ', Games) + 1, LEN(Games)) as Season
	, City
	, Sport
	, Event
	, NULLIF(Medal, 'NA') as Medal
INTO dbo.completo
FROM dbo.athletes_event_results;



-- HAGO TABLAS CON LA INFORMACIÓN, ELIMINANDO INFO DUPLICADA

-- TABLA ATLETAS
SELECT DISTINCT
	ID_athletes as ID,
	Name, 
	Sex,
	(Year - Age) as Birth_year,
	COALESCE(Height,
				ROUND(AVG(Height) OVER(PARTITION BY Sex, Sport),0)) as Height,
	COALESCE(Weight,
				ROUND(AVG(Weight) OVER(PARTITION BY Sex, Sport),0)) as Weight,
	NOC
INTO athletes
FROM dbo.completo;
-- ELIMINO IDS DUPLICADOS
WITH ToDelete AS (
   SELECT ROW_NUMBER() OVER (PARTITION BY ID
                             ORDER BY ID) AS rn
   FROM dbo.athletes
)
DELETE FROM ToDelete
WHERE rn > 1;
-- ELIMINO LA INFO QUE ESTÁ EN ESTA TABLA DE LA TABLA COMPLETA
ALTER TABLE dbo.completo DROP COLUMN Name, Sex, Age, Height, Weight, NOC;

-- AGREGO IDS TABLA GRAL
ALTER TABLE dbo.completo
   ADD ID INT IDENTITY
       CONSTRAINT PK_completo PRIMARY KEY(ID);

-- TABLA JUEGOS
SELECT DISTINCT
	Year, 
	Season,
	City
INTO games
FROM dbo.completo;
-- AGREGO IDS 
ALTER TABLE dbo.games
   ADD ID INT IDENTITY
       CONSTRAINT PK_games PRIMARY KEY(ID);
-- REEMPLAZO EN TABLA GRAL
ALTER TABLE dbo.completo ADD ID_games INT;
UPDATE dbo.completo
SET ID_games = g.ID 
FROM dbo.completo as c, dbo.games as g
WHERE c.Season = g.Season
AND c.Year = g.Year
AND c.City = g.City;
-- ELIMINO EN TABLA GRAL
ALTER TABLE dbo.completo DROP COLUMN City, Season, Year;


-- TABLA EVENTOS
SELECT DISTINCT
	Event
INTO events
FROM dbo.completo;
ALTER TABLE dbo.events
   ADD ID INT IDENTITY
       CONSTRAINT PK_events PRIMARY KEY(ID);
-- REEMPLAZO EN TABLA GRAL
ALTER TABLE dbo.completo ADD ID_events INT;
UPDATE dbo.completo
SET ID_events = e.ID 
FROM dbo.completo as c, dbo.events as e
WHERE c.Event = e.Event;
-- ELIMINO EN TABLA GRAL
ALTER TABLE dbo.completo DROP COLUMN Event;

-- TABLA SPORTS
SELECT DISTINCT
	Sport
INTO sports
FROM dbo.completo;
--AGREGO IDS
ALTER TABLE dbo.sports
   ADD ID INT IDENTITY
       CONSTRAINT PK_sports PRIMARY KEY(ID);
-- REEMPLAZO EN TABLA GRAL
ALTER TABLE dbo.completo ADD ID_sports INT;
UPDATE dbo.completo
SET ID_sports = s.ID 
FROM dbo.completo as c, dbo.sports as s
WHERE c.Sport = s.Sport;
-- ELIMINO EN TABLA GRAL
ALTER TABLE dbo.completo DROP COLUMN Sport;

-- TABLA MEDALS
SELECT DISTINCT
	NULLIF(Medal, 'NA') as Medal
INTO medals
FROM dbo.completo;
-- AGREGO IDS
ALTER TABLE dbo.medals
   ADD ID INT IDENTITY
       CONSTRAINT PK_medal PRIMARY KEY(ID);
-- REEMPLAZO EN TABLA GRAL
ALTER TABLE dbo.completo ADD ID_medal INT;
UPDATE dbo.completo
SET ID_medal = m.ID 
FROM dbo.completo as c, dbo.medals as m
WHERE c.Medal = m.Medal;
-- ELIMINO EN TABLA GRAL
ALTER TABLE dbo.completo DROP COLUMN Medal;

-- CORRIJO NOMBRE DE PAISES EN TEAM_INFO	
-- primer agrego con Import Data la tabla csv con los nombres y valores iso3 de los paises
-- elimino comillas 
UPDATE dbo.paises SET dbo.paises.iso3 = REPLACE(dbo.paises.iso3, '"', '')
UPDATE dbo.paises SET dbo.paises.name = REPLACE(dbo.paises.name, '"', '')
--corrijo nombres que están en ambas tablas
UPDATE dbo.team_info
SET dbo.team_info.Team = dbo.paises.name
FROM dbo.team_info
     JOIN dbo.paises ON dbo.team_info.NOC = dbo.paises.iso3;

--Elimino duplicados en team_info
WITH ToDelete AS (
   SELECT ROW_NUMBER() OVER (PARTITION BY NOC
                             ORDER BY NOC) AS rn
   FROM dbo.team_info
)
DELETE FROM ToDelete
WHERE rn > 1;

-- como le fue a los países históricamente en los juegos olímpicos de verano

SELECT TOP 10 p.Team as pais, COUNT (c.ID_medal) as cantidad_medallas
FROM dbo.completo as c 
INNER JOIN dbo.athletes as a 
ON (c.ID_athletes = a.ID)
INNER JOIN dbo.team_info as p
ON (a.NOC =  p.NOC)
INNER JOIN dbo.games as g
ON (c.ID_games = g.ID)
WHERE g.Season = 'Summer'
AND c.ID_medal IS NOT NULL
GROUP BY p.Team
ORDER BY cantidad_medallas DESC;
