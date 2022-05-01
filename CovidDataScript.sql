-- Exploratory Data Analysis for CovidDeaths data


USE PortfolioProject

-- Exploring the full table
SELECT *
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Finding the percentage of cases that led to deaths
-- Percentage deaths relative to cases per day
SELECT 
	continent,
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS death_percentage
FROM dbo.CovidDeaths$
ORDER BY location, date


--Finding the percentage of the population that has gotten covid per day
SELECT 
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS case_percentage
FROM dbo.CovidDeaths$
-- Specifying location
WHERE location LIKE '%Africa%'
ORDER BY location, date


-- What country has the highest infection rate compared to their population?
SELECT 
	location,
	population,
	-- Highlight the maximum number of cases in each location
	MAX(total_cases) AS HighestInfectionCount,
	-- Highlight the highest percentage of infected people relative to the population in each location
	MAX((total_cases/population))*100 AS Percent_Infected
FROM dbo.CovidDeaths$
GROUP BY location, population
ORDER BY Percent_Infected DESC


-- What countries have the highest death count?
SELECT 
	location,
	population,
	MAX(cast(Total_deaths AS INT)) as TotalDeaths
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY TotalDeaths Desc


-- What countries have the highest death count per population?
SELECT 
	location,
	population,
	MAX(cast(Total_deaths AS INT)) as TotalDeaths,
	MAX(cast(Total_deaths AS INT))/population as PercentageDeaths
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY PercentageDeaths DESC


-- Death count by continent
-- What continent has the highest death count?
SELECT 
	continent, 
	MAX(cast(Total_deaths AS INT)) as TotalDeaths
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent 
order by TotalDeaths DESC


-- ANALYZING GLOBAL NUMBERS;
--1. The total number of cases and deaths in the world
SELECT 
	SUM(new_cases) as TotalCases,
	SUM(cast (new_deaths AS INT)) as TotalDeaths,
	SUM(cast (new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL

----2. The total number of new cases and new deaths per day
SELECT 
	date,
	SUM(new_cases) as NewCases,
	SUM(cast (new_deaths AS INT)) as NewDeaths,
	SUM(cast (new_deaths AS INT))/SUM(new_cases) * 100 AS death_percentage_per_day
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date



-- JOINING Covid Deaths and Covid Vaccinations

-- Creating a temporary table to calculate percentage population vaccinated per day in each location
DROP Table if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar (255),
	Location nvarchar (255),
	Date datetime,
	Population numeric,
	new_vaccinations numeric,
	CummulativeVaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,
		dea.location, 
		dea.date, 
		dea.population,	
		vac.new_vaccinations,
		-- Find the cummulative new vaccinations per day by location
		SUM((CAST (vac.new_vaccinations AS BIGINT))) OVER 
			(Partition by dea.location ORDER BY dea.location, dea.date) AS CummulativeVaccinations
	FROM CovidVaccinations$ vac
	JOIN CovidDeaths$ dea 
		ON vac.location = dea.location
		AND vac.date = dea.date
	WHERE vac.continent IS NOT NULL
SELECT *,
	(CummulativeVaccinations/population)*100 AS PercentageVaccinated
FROM #PercentPopulationVaccinated


--Creating Views to store data for visualizations
--View: Cummulative Vaccinations in each location per day
CREATE VIEW CummulativePopulation as
SELECT dea.continent,
		dea.location, 
		dea.date, 
		dea.population,	
		vac.new_vaccinations,
		SUM((CAST (vac.new_vaccinations AS BIGINT))) OVER 
			(Partition by dea.location ORDER BY dea.location, dea.date) AS CummulativeVaccinations
	FROM CovidVaccinations$ vac
	JOIN CovidDeaths$ dea 
		ON vac.location = dea.location
		AND vac.date = dea.date
	WHERE vac.continent IS NOT NULL

SELECT * FROM CummulativePopulation


-- View: cummulative cases in each location per day 
CREATE VIEW CummulativeCases as
SELECT dea.continent,
		dea.location, 
		dea.date, 
		dea.population,	
		dea.new_cases,
		SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CummulativeCases
	FROM CovidVaccinations$ vac
	JOIN CovidDeaths$ dea 
		ON vac.location = dea.location
		AND vac.date = dea.date
	WHERE vac.continent IS NOT NULL
SELECT * FROM CummulativeCases


-- View: cummulative deaths in each location per day 
CREATE VIEW CummulativeDeaths as
SELECT dea.continent,
		dea.location, 
		dea.date, 
		dea.population,	
		dea.new_deaths,
		SUM(CAST(dea.new_deaths AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CummulativeDeaths
	FROM CovidVaccinations$ vac
	JOIN CovidDeaths$ dea 
		ON vac.location = dea.location
		AND vac.date = dea.date
	WHERE vac.continent IS NOT NULL
SELECT * FROM CummulativeDeaths

