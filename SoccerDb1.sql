--These are my solutions for some exercises that were required for my studies in PostgreSQL.
-- Here we are creating a database and adding some queries that increase in difficulty.


--Creation of a Schema for a Soccer Tournament Database

CREATE SCHEMA euro2021;

-- Creation of the Tables:

CREATE TABLE euro2021.tb_country(
	country_code CHAR(5) NOT NULL,
	country_name VARCHAR (60) NOT NULL,
	created_by_user VARCHAR (10) NOT NULL DEFAULT 'OS_UEFA',
	created_date DATE,
	updated_date DATE,
	PRIMARY KEY (country_code)
);


CREATE TABLE euro2021.tb_city (
	city_code CHAR(5)NOT NULL,
	country_code CHAR(5) NOT NULL,
	city_name VARCHAR (60) NOT NULL,
	population INTEGER,
	created_by_user VARCHAR (10) NOT NULL DEFAULT 'OS_UEFA',
	created_date DATE,
	update_date DATE,
	PRIMARY KEY (city_code, country_code),
	FOREIGN KEY (country_code) REFERENCES euro2021.tb_country(country_code)
);


CREATE TABLE euro2021.tb_team (
	team_code CHAR (5) NOT NULL,
	team_alias VARCHAR (40) NOT NULL,
	country_code CHAR (5) NOT NULL,
	coach_name VARCHAR (120) NOT NULL,
	association_name VARCHAR (120),
	first_captain_name VARCHAR (120) NOT NULL,
	group_name VARCHAR (10) NOT NULL DEFAULT 'OS_UEFA',
	create_date DATE,
	updated_date DATE,
	PRIMARY KEY (team_code),
	FOREIGN KEY (country_code) REFERENCES euro2021.tb_country(country_code)
);


CREATE TABLE euro2021.tb_stadium (
	stadium_code CHAR(5) NOT NULL,
	stadium_name VARCHAR(60) NOT NULL,
	city_code CHAR (5) NOT NULL,
	country_code CHAR(5) NOT NULL,
	created_by_user VARCHAR(10) NOT NULL DEFAULT 'OS_UEFA',
	created_date DATE,
	updated_date DATE,
	PRIMARY KEY (stadium_code),
	FOREIGN KEY (city_code, country_code) REFERENCES euro2021.tb_city (city_code, country_code)
);


CREATE TABLE euro2021.tb_referee (
	referee_code CHAR (5) NOT NULL,
	referee_name VARCHAR (60) NOT NULL,
	dob DATE,
	country VARCHAR (5),
	referee_manager_code CHAR(5),
	created_by_user VARCHAR (10) NOT NULL DEFAULT 'OS_UEFA',
	created_date DATE,
	updated_date DATE,
	PRIMARY KEY (referee_code),
	FOREIGN KEY (referee_manager_code) REFERENCES euro2021.tb_referee (referee_code)
);


CREATE TABLE euro2021.tb_phase (
	phase_code INTEGER NOT NULL,
	phase_name VARCHAR (60) NOT NULL,
	created_by_user VARCHAR (10) NOT NULL DEFAULT 'OS_UEFA',
	created_date DATE,
	updated_date DATE,
	PRIMARY KEY (phase_code)
);



CREATE TABLE euro2021.tb_match (
	home_team_code CHAR (5) NOT NULL,
	visitor_team_code CHAR(5) NOT NULL,
	match_date DATE NOT NULL,
	stadium_code CHAR(5) NOT NULL,
	referee_code CHAR (5) NOT NULL,
	phase_code INTEGER NOT NULL,
	home_goals INTEGER NOT NULL,
	visitor_goals INTEGER NOT NULL,
	home_cards INTEGER NOT NULL, 
	visitor_cards INTEGER NOT NULL,
	created_by_user VARCHAR(10) NOT NULL DEFAULT 'OS_UEFA',
	created_date DATE,
	updated_date DATE,
	PRIMARY KEY (home_team_code, visitor_team_code, match_date),
	FOREIGN KEY (home_team_code) REFERENCES euro2021.tb_team (team_code),
	FOREIGN KEY (visitor_team_code) REFERENCES euro2021.tb_team (team_code),
	FOREIGN KEY (stadium_code) REFERENCES euro2021.tb_stadium (stadium_code),
	FOREIGN KEY (referee_code) REFERENCES euro2021.tb_referee (referee_code),
	FOREIGN KEY (phase_code) REFERENCES euro2021.tb_phase (phase_code)
); 


--We want to check the cities with a population below 1 Million, order by Name 


SELECT 	tb_city.city_name,
		euro2021.tb_country.country_name,
		tb_city.population
FROM euro2021.tb_country

INNER JOIN euro2021.tb_city 
	ON tb_country.country_code= tb_city.country_code

WHERE population < 1000000
ORDER BY city_name;


--Query to get the code and name of the tournament phases and how many matches have been played for each of them.
--The result is ordered by Phase Code


SELECT 
	euro2021.tb_phase.phase_code,
	euro2021.tb_phase.phase_name,
	COUNT (euro2021.tb_match.phase_code) AS num_matches
FROM euro2021.tb_phase

INNER JOIN euro2021.tb_match 
	ON tb_phase.phase_code= tb_match.phase_code
	
GROUP BY euro2021.tb_phase.phase_code
ORDER BY euro2021.tb_phase.phase_code
;


-- We want a list of the referees from country Finland, Spain or Turkay that have judged in mor than 3 matched.
--Ordered by referee name


SELECT	r.referee_name,
		r.dob,
		c.country_name,
		COUNT (m.*) AS matches_refereed
FROM euro2021.tb_match AS m

INNER JOIN euro2021.tb_referee r
		ON m.referee_code = r.referee_code
INNER JOIN euro2021.tb_country c
	ON r.country = c.country_code

WHERE	c.country_name = 'Finland' 
		OR c.country_name = 'Spain' 
		OR c.country_name = 'Turkey'
		
GROUP BY r.referee_name,r.dob,c.country_name

HAVING COUNT (m.referee_code)>3
ORDER BY r.referee_name
;


--We want to know the matches from the "Group Phase" that have referees that have been born during the 70's.
--We are working with Implicit Joins in this case.

SELECT h.team_alias AS LOCAL,
       v.team_alias AS visitante,
       r.referee_name AS arbitro,
       r.dob AS fecha_nacimiento
FROM   euro2021.tb_match M,
       euro2021.tb_team H, 
       euro2021.tb_team V,
       euro2021.tb_referee R,
	   euro2021.tb_phase P

WHERE  M.home_team_code    = H.team_code AND
       M.visitor_team_code = V.team_code AND
       M.referee_code = R.referee_code   AND 
       M.phase_code = P.phase_code

  AND EXTRACT (YEAR
               FROM R.dob)>1969
  AND EXTRACT (YEAR
               FROM R.dob)<1980
AND P.phase_name = 'Group phase'
ORDER BY arbitro ;


--We want to know how many different cities has each referee judged in (and only the referee that have judged at least 1 one match).
-- We only want to check each city once and check if any city has more than one stadium.


SELECT 	r.referee_name AS nombre_arbitro, 
		c.country_name AS pais_origen, 
		COUNT (DISTINCT st.city_code) AS num_cities
FROM euro2021.tb_referee AS r

INNER JOIN 	euro2021.tb_country AS c 
			ON (r.country=c.country_code)
INNER JOIN  euro2021.tb_match AS m 
			ON (m.referee_code=r.referee_code)
LEFT JOIN euro2021.tb_city AS ci 
			ON (c.country_code=ci.country_code)
INNER JOIN euro2021.tb_stadium AS st 
			ON (m.stadium_code=st.stadium_code)
			
GROUP BY nombre_arbitro, pais_origen
ORDER BY nombre_arbitro
;


-- Now we are adding a new column:
ALTER TABLE euro2021.tb_referee
	RENAME COLUMN country_ref VARCHAR (5);

-- And copying information from the previous column to the new one:

UPDATE euro2021.tb_referee
	SET country_ref = country;

--We are defining the new column as foreing key:

ALTER TABLE euro2021.tb_referee
	ADD CONSTRAINT fk_referee_country FOREIGN KEY (country_ref) 
	REFERENCES euro2021.tb_country (country_code);



--We are going to add a constraint to the goal columns to avoid having values higher than 12.

ALTER TABLE euro2021.tb_match
	ADD CONSTRAINT golesmax 
	CHECK (home_goals < 12 
	AND visitor_goals < 12 ) ;

				 

--We are going to create new columns for red and yellow cards
-- For the new columns we are going to set yellow cards to the same values as the previous columns.
-- However we are going to set red cards to default 0

-- We first create the new columns:
ALTER TABLE euro2021.tb_match
	ADD COLUMN home_yellow_cards INTEGER,
	ADD COLUMN home_red_cards INTEGER DEFAULT 0,
	ADD COLUMN visitor_yellow_cards INTEGER,
	ADD COLUMN visitor_red_cards INTEGER DEFAULT 0;

-- Now we copy the yellow cards
UPDATE euro2021.tb_match 
	SET home_yellow_cards = home_cards;
	
UPDATE euro2021.tb_match 
	SET visitor_yellow_cards = visitor_cards;

--And we delete the old columns
ALTER TABLE euro2021.tb_match 
	DROP COLUMN home_cards;	
	
ALTER TABLE euro2021.tb_match 
	DROP COLUMN visitor_cards;											 


-- Now we want to check if there is any duplicate value in matches played the same day with the same referee

SELECT m.*
	FROM euro2021.tb_match m
	JOIN (SELECT match_date, referee_code, COUNT(*)
	FROM euro2021.tb_match
GROUP BY match_date, referee_code

	HAVING count(*) > 1 ) mm
	ON m.match_date= mm.match_date
	AND m.referee_code = mm.referee_code
	
ORDER BY m.referee_code;


--Finally we want to update the duplicate value found. We will update the match played by Germany the 19th of June 2021 with the referee name "Jens Maer"

	
UPDATE euro2021.tb_match
	SET referee_code= 

		(SELECT r.referee_code
		FROM euro2021.tb_referee r
		WHERE r.referee_name = 'Jens Maer')

	WHERE visitor_team_code =
		(SELECT t.team_code
		FROM euro2021.tb_team t
		JOIN euro2021.tb_match m
		ON m.home_team_code = t.team_code 
		OR m.visitor_team_code = t.team_code
		JOIN euro2021.tb_country c
		ON t.country_code = c.country_code
		WHERE c.country_name = 'Germany'
		AND m.match_date = '2021-06-19')

	OR home_team_code = 
		(SELECT t.team_code
		FROM euro2021.tb_team t
		JOIN euro2021.tb_match m
		ON m.home_team_code = t.team_code 
		OR m.visitor_team_code = t.team_code
		JOIN euro2021.tb_country c
		ON t.country_code = c.country_code
		WHERE c.country_name = 'Germany'
		AND m.match_date = '2021-06-19');


