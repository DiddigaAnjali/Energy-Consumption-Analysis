CREATE DATABASE ENERGYDB;
USE ENERGYDB;

-- 1. country table
CREATE TABLE country (
    CID VARCHAR(10) PRIMARY KEY,
    Country VARCHAR(100) UNIQUE
);

SELECT * FROM COUNTRY;

-- 2. emission_3 table
CREATE TABLE emission_3 (
    country VARCHAR(100),
 energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM EMISSION_3;

-- 3. population table
CREATE TABLE population (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country(Country)
);

SELECT * FROM POPULATION;

-- 4. production table
CREATE TABLE production (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM PRODUCTION;

-- 5. gdp_3 table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country(Country)
);

SELECT * FROM GDP_3;

-- 6. consumption table
CREATE TABLE consumption (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM CONSUMPTION;
-- ********** General & Comparative Analysis *********** --
-- What is the total emission per country for the most recent year available?
SELECT country,
       SUM(emission) AS total_emission
FROM emission_3
WHERE year = (SELECT MAX(year) FROM emission_3)
GROUP BY country
ORDER BY total_emission DESC;

-- What are the top 5 countries by GDP in the most recent year? 
SELECT Country,
       Value AS GDP
FROM gdp_3
WHERE year = (SELECT MAX(year) FROM gdp_3)
ORDER BY Value DESC
LIMIT 5;

-- Compare energy production and consumption by country and year.
SELECT p.country,
       p.year,
       SUM(p.production) AS total_production,
       SUM(c.consumption) AS total_consumption
FROM production p
JOIN consumption c
ON p.country = c.country
AND p.year = c.year
GROUP BY p.country, p.year;

-- Which energy types contribute most to emissions across all countries?
SELECT energy_type,
       SUM(emission) AS total_emission
FROM emission_3
GROUP BY energy_type
ORDER BY total_emission DESC;

 -- ********** Trend Analysis Over Time ********** --
 
 -- How have global emissions changed year over year? 
SELECT year,
       SUM(emission) AS global_emission
FROM emission_3
GROUP BY year
ORDER BY year;

-- What is the trend in GDP for each country over the given years?
SELECT Country,
       year,
       Value AS GDP
FROM gdp_3
ORDER BY Country, year;

-- How has population growth affected total emissions in each country?
SELECT e.country,
       e.year,
       SUM(e.emission) AS total_emission,
       p.Value AS population
FROM emission_3 e
JOIN population p
ON e.country = p.countries
AND e.year = p.year
GROUP BY e.country, e.year, p.Value;

-- Has energy consumption increased or decreased over the years for major economies?
SELECT country,
       year,
       SUM(consumption) AS total_consumption
FROM consumption
WHERE country IN ('United States', 'China', 'India', 'Germany', 'Japan',
 'United Kingdom', 'France')
GROUP BY country, year
ORDER BY country, year;

-- What is the average yearly change in emissions per capita for each country?
SELECT e.country,
       e.year,
       SUM(e.emission) / MAX(p.Value) AS emission_per_capita
FROM emission_3 e
JOIN population p
  ON e.country = p.countries
 AND e.year = p.year
GROUP BY e.country, e.year;

--  ********** Ratio & Per Capita Analysis  **********--
-- What is the emission-to-GDP ratio for each country by year?
SELECT e.country,
       e.year,
       SUM(e.emission) / MAX(g.Value) AS emission_gdp_ratio
FROM emission_3 e
JOIN gdp_3 g
  ON e.country = g.Country
 AND e.year = g.year
GROUP BY e.country, e.year;

-- What is the energy consumption per capita for each country over the last decade?
SELECT 
    c.country,
    c.year,
    SUM(c.consumption) / MAX(p.Value) AS consumption_per_capita
FROM consumption c
JOIN population p
  ON c.country = p.countries
 AND c.year = p.year
WHERE c.year >= (
    SELECT MAX(year) - 9 FROM consumption
)
GROUP BY c.country, c.year
ORDER BY c.country, c.year;

-- How does energy production per capita vary across countries?
SELECT 
    pr.country,
    SUM(pr.production) / MAX(p.Value) AS production_per_capita
FROM production pr
JOIN population p
  ON pr.country = p.countries
 AND pr.year = p.year
WHERE pr.year = (
    SELECT MAX(year) FROM production
)
GROUP BY pr.country
ORDER BY production_per_capita DESC;

-- Which countries have the highest energy consumption relative to GDP?
SELECT 
    c.country,
    SUM(c.consumption) / MAX(g.Value) AS consumption_to_gdp_ratio
FROM consumption c
JOIN gdp_3 g
  ON c.country = g.Country
 AND c.year = g.year
WHERE c.year = (
    SELECT MAX(year) FROM consumption
)
GROUP BY c.country
ORDER BY consumption_to_gdp_ratio DESC;

-- What is the correlation between GDP growth and energy production growth?
SELECT 
    g.Country,
    g.year,
    g.Value AS GDP,
    SUM(p.production) AS total_production
FROM gdp_3 g
JOIN production p ON g.Country = p.country AND g.year = p.year
GROUP BY g.Country, g.year, g.Value
ORDER BY g.Country, g.year;

-- ******** Global Comparisons ******** --
-- What are the top 10 countries by population and how do their emissions compare?
SELECT 
    p.countries AS country,
    MAX(p.Value) AS latest_population,
    (SELECT SUM(emission) 
     FROM emission_3 e 
     WHERE e.country = p.countries 
     AND e.year = (SELECT MAX(year) FROM emission_3 WHERE country = p.countries)
    ) AS latest_emissions
FROM population p
GROUP BY p.countries
ORDER BY latest_population DESC
LIMIT 10;

-- Which countries have improved (reduced) their per capita emissions the most over the last decade?
SELECT 
    country,
    MAX(year) AS recent_year,
    MIN(year) AS start_year,
    MAX(per_capita_emission) AS max_emission,
    MIN(per_capita_emission) AS min_emission,
    ROUND(MIN(per_capita_emission) - MAX(per_capita_emission), 4) AS reduction
FROM emission_3
WHERE year >= (SELECT MAX(year) - 10 FROM emission_3)
GROUP BY country
HAVING max_emission IS NOT NULL AND min_emission IS NOT NULL
ORDER BY reduction ASC
LIMIT 10;

-- What is the global share (%) of emissions by country?
SELECT 
    country,
    SUM(emission) AS total_emissions,
    ROUND(SUM(emission) / (SELECT SUM(emission) FROM emission_3) * 100, 2) 
    AS global_share_percent
FROM emission_3
GROUP BY country
ORDER BY global_share_percent DESC;

-- What is the global average GDP, emission, and population by year?
SELECT 
    g.year,
    ROUND(AVG(g.Value), 2) AS avg_gdp,
    ROUND(AVG(e.emission), 2) AS avg_emission,
    ROUND(AVG(p.Value), 2) AS avg_population
FROM gdp_3 g
JOIN emission_3 e ON g.Country = e.country AND g.year = e.year
JOIN population p ON g.Country = p.countries AND g.year = p.year
GROUP BY g.year
ORDER BY g.year;