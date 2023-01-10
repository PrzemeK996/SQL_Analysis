
--Average legth of the country name for each continent
SELECT Continent, AVG(CONVERT(DECIMAL(6,2), LEN(Country))) as Length FROM dbo.worldpopulation
GROUP BY Continent


--Percentage of world population for each country 
SELECT Country, [2020 Population], 
CONVERT(DECIMAL(4,2), 
[2020 Population] * 100 / SUM([2020 Population]) OVER()) as PercentageOfWorldPopulation
FROM dbo.worldpopulation
ORDER BY PercentageOfWorldPopulation DESC


--Countries with biggest population increasement
SELECT Country, [1970 Population], [2020 Population], 
CONVERT(DECIMAL(38,20), [2020 Population]) / 
CONVERT(DECIMAL(38,20), [1970 Population]) * 100 as PercentageIncreasement
FROM dbo.worldpopulation
ORDER BY ([2020 Population] / [1970 Population]) * 100 DESC

--Continent population, biggest country and population percentage of country compared to whole continent
SELECT Continent, ContinentPopulation, Country, (Population / ContinentPopulation) * 100 as [CountryPercentage]
FROM (
SELECT Country, Continent, [2020 Population] as Population, 
SUM([2020 Population]) OVER(PARTITION BY Continent) as ContinentPopulation,
ROW_NUMBER() OVER (PARTITION BY Continent ORDER BY [2020 Population] DESC) as CountryRank
FROM dbo.worldpopulation) b
WHERE CountryRank = 1
ORDER BY Population DESC


--Countries and regions with biggest GDP per capita increasement
SELECT old.[Country Name], old.[year], old.GDP_per_capita_USD, new.[year], new.GDP_per_capita_USD, (new.GDP_per_capita_USD - old.GDP_per_capita_USD) * 100/ old.GDP_per_capita_USD as PercentageIncreasement
FROM dbo.gdp old
JOIN dbo.gdp new ON old.[Country Name] = new.[Country Name]
WHERE old.[year] = '1970' AND old.GDP_per_capita_USD IS NOT NULL AND new.[year] = '2020'
ORDER BY PercentageIncreasement DESC


--Average GDP's in different continents and in which it has increased the most
WITH old
AS
(
	SELECT wp.Continent, AVG(gdp.GDP_USD) as [1970GDP]
	FROM dbo.worldpopulation wp
	JOIN dbo.gdp gdp ON gdp.[Country Name] = wp.Country
	WHERE gdp.year = '1970'
	GROUP BY wp.Continent
),

new
AS
(
	SELECT wp.Continent, AVG(gdp.GDP_USD) as [2020GDP]
	FROM dbo.worldpopulation wp
	JOIN dbo.gdp gdp ON gdp.[Country Name] = wp.Country
	WHERE gdp.year = '2020'
	GROUP BY wp.Continent
)

SELECT old.Continent, [1970GDP], [2020GDP], (([2020GDP] - [1970GDP]) * 100 / [1970GDP])  as PercentageIncreasement
FROM old
JOIN new ON old.Continent = new.Continent
ORDER BY PercentageIncreasement DESC



--Showing how many countries in each continent have GDP greather than the average of the continent
 WITH a AS
 (
 SELECT wp.Country ,wp.Continent, g.GDP_per_capita_USD, 
 AVG(g.GDP_per_capita_USD) OVER (PARTITION BY wp.Continent ORDER BY wp.Continent) as avg_gdp,
 CASE WHEN g.GDP_per_capita_USD > AVG(g.GDP_per_capita_USD) OVER (PARTITION BY wp.Continent ORDER BY wp.Continent) THEN 1 ELSE 0 END as above_avg
 FROM dbo.gdp g
 JOIN dbo.worldpopulation wp ON wp.Country = g.[Country Name]
 WHERE g.year = '2020' 
 ),
 b AS
 (
 SELECT Continent, Avg_Gdp, CONVERT(DECIMAL(4,0), COUNT(Country)) as Countries, CONVERT(DECIMAL(4,0), COUNT(CASE WHEN above_avg = '1' THEN 1 ELSE null END)) as HigherThanAvg
 FROM a
 GROUP BY Continent, avg_gdp
 )

 SELECT Continent, Avg_Gdp, Countries, HigherThanAvg, HigherThanAvg * 100/Countries as Percentage 
 FROM b
 ORDER BY Continent



--Which 5 countries were most and least damaged by Great Recession in 2007 - 2009
SELECT * FROM (SELECT TOP(5) g1.[Country Name] as Name, g1.GDP_per_capita_USD as GDP2007, g2.GDP_per_capita_USD as GDP2009, (g2.GDP_per_capita_USD - g1.GDP_per_capita_USD) * 100 / g1.GDP_per_capita_USD as IncreasementDecrement
FROM dbo.gdp g1
JOIN dbo.gdp g2 ON g1.[Country Name] = g2.[Country Name]
WHERE g1.year = '2007' AND g2.year = '2009'
ORDER BY IncreasementDecrement DESC) as x
UNION
SELECT * FROM (SELECT TOP(5) g1.[Country Name] as Name, g1.GDP_per_capita_USD as GDP2007, g2.GDP_per_capita_USD as GDP2009, (g2.GDP_per_capita_USD - g1.GDP_per_capita_USD) * 100 / g1.GDP_per_capita_USD as IncreasementDecrement
FROM dbo.gdp g1
JOIN dbo.gdp g2 ON g1.[Country Name] = g2.[Country Name]
WHERE g1.year = '2007' AND g2.year = '2009' AND g1.GDP_per_capita_USD IS NOT NULL AND g2.GDP_per_capita_USD IS NOT NULL
ORDER BY IncreasementDecrement) as y
ORDER by IncreasementDecrement DESC


---Calculating how many poor, average and rich countries includes each continent
SELECT Continent, 
COUNT([Country Name]) as Countries,
COUNT(case WHEN Wealthiness = 'Rich' THEN 1 ELSE null END) as Rich,
COUNT(case WHEN Wealthiness = 'Average' THEN 1 ELSE null END) as Average,
COUNT(case WHEN Wealthiness = 'Poor' THEN 1 ELSE null END) as Poor
FROM
(
SELECT gdp.[Country Name], wp.Continent, gdp.GDP_per_capita_USD,
CASE 
WHEN ROW_NUMBER() OVER(ORDER BY gdp.GDP_per_capita_USD DESC) <= 59 THEN 'Rich'
WHEN ROW_NUMBER() OVER(ORDER BY gdp.GDP_per_capita_USD DESC) <= 118 THEN 'Average'
ELSE 'Poor'
END AS 'Wealthiness'
FROM dbo.gdp gdp
JOIN dbo.worldpopulation wp ON wp.Country = gdp.[Country Name]
WHERE gdp.year = '2020' AND gdp.GDP_per_capita_USD IS NOT NULL
) as b
GROUP BY Continent
ORDER BY Rich DESC


---Calculating average happiness score and life expectancy in every continent
SELECT wp.Continent, AVG(h.[Ladder score]) as AverageHappinessScore, AVG(h.[Healthy life expectancy]) as LifeExpectancy FROM dbo.happiness h
JOIN dbo.worldpopulation wp ON h.[Country name] = wp.Country
GROUP BY wp.Continent
ORDER BY AverageHappinessScore DESC


--Showing relationship beetwen freedom and happiness score
SELECT HappinessScore, AVG(Freedom) as FreedomScore FROM
(
SELECT HappinessScore = '7.81 - 6.80', [Freedom to make life choices] as Freedom FROM dbo.happiness
WHERE [Ladder score] >= 6.80 AND [Ladder score] < 7.81
UNION
SELECT HappinessScore = '6.79 - 5.80', [Freedom to make life choices] as Freedom FROM dbo.happiness
WHERE [Ladder score] >= 5.80 AND [Ladder score] <= 6.79
UNION
SELECT HappinessScore = '5.79 - 4.80', [Freedom to make life choices] as Freedom FROM dbo.happiness
WHERE [Ladder score] >= 4.80 AND [Ladder score] <= 5.79
UNION
SELECT HappinessScore = '4.79 - 3.80', [Freedom to make life choices] as Freedom FROM dbo.happiness
WHERE [Ladder score] >= 3.80 AND [Ladder score] <= 4.79
UNION
SELECT HappinessScore = '3.79 - 2.80', [Freedom to make life choices] as Freedom FROM dbo.happiness
WHERE [Ladder score] >= 2.80 AND [Ladder score] <= 3.79
) b
GROUP BY HappinessScore 
ORDER BY HappinessScore DESC


---Showing the best place to live in the world. Most points receive country with the happiest population, biggest GDP, highest life expectancy and biggest freedom to make life choices
SELECT Country, Happiness + LifeExpectancy + Freedom + GDP as Score
FROM 
(SELECT h.[Country name] as Country, 
DENSE_RANK() OVER(ORDER BY h.[Ladder score]) as Happiness, 
DENSE_RANK() OVER(ORDER BY h.[Healthy life expectancy]) as LifeExpectancy,
DENSE_RANK() OVER(ORDER BY h.[Freedom to make life choices]) as Freedom,
DENSE_RANK() OVER(ORDER BY g.GDP_per_capita_USD) as GDP
FROM dbo.happiness h
JOIN dbo.gdp g ON g.[Country Name] = h.[Country name]
WHERE g.year = '2020') c
ORDER BY Score DESC


--Showing how GDP from eastern europe and western countries has increased between 2003(when many eastern countries have joined the European Union) and 2020
CREATE TABLE #Countries
( 
Country NVARCHAR(50),
WestEast NVARCHAR(50),
GDP2003 DECIMAL(10,2),
GDP2020 DECIMAL(10,2)
)

INSERT INTO #Countries
SELECT h.[Country name] as Country, [Regional indicator] as 'WestEast', g1.GDP_per_Capita_USD as GDP2003, g2.GDP_per_capita_USD as GDP2020 FROM dbo.happiness h
JOIN dbo.gdp g1 ON g1.[Country Name] = h.[Country name]
JOIN dbo.gdp g2 ON g2.[Country Name] = h.[Country name]
WHERE 
([Regional indicator] = 'Central and Eastern Europe' OR [Regional indicator] = 'Western Europe') 
AND g1.year = '2003' 
AND g1.GDP_per_capita_USD IS NOT NULL
AND g2.year = '2020'
AND g2.GDP_per_capita_USD IS NOT NULL

SELECT WestEast, AVG(GDP2003) as GDP2003, AVG(GDP2020) as GDP2020, (AVG(GDP2020) * 100)/AVG(GDP2003) as PercentageIncreasement FROM #Countries
GROUP BY WestEast 






