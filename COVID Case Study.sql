--SELECT *
--FROM CovidCaseStudy..CovidDeaths
--WHERE continent <> ''
--ORDER BY 3, 4

--SELECT *
--FROM CovidCaseStudy..CovidVaccinations
--ORDER BY 3, 4





-- Selecting data to be used

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidCaseStudy..CovidDeaths
ORDER BY 1, 2





-- Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 
AS DeathRate
FROM CovidCaseStudy..CovidDeaths
--WHERE location = 'South Africa'
ORDER BY 1, 2





-- Total Cases vs Population

SELECT location, date, population, total_cases, (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 
AS CasePercentage
FROM CovidCaseStudy..CovidDeaths
-- WHERE location = 'South Africa'
ORDER BY 1, 2





-- Countries w/ Highest Infection Rate per Population

SELECT location, population, MAX(CAST(total_cases as float)) as HighestInfectionCount, NULLIF(MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))), 0) * 100 
AS PercentPopulationInfected
FROM CovidCaseStudy..CovidDeaths
-- WHERE location = 'South Africa'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC





-- Countries w/ Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM CovidCaseStudy..CovidDeaths
WHERE continent <> ''
GROUP BY location
ORDER BY TotalDeathCount DESC





-- Continent w/ Highest Death Count per Population

-- Because of slight error in dataset, the initial script returned incorrect figures, commented below

--SELECT continent, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
--FROM CovidCaseStudy..CovidDeaths
--WHERE continent <> ''
--GROUP BY continent
--ORDER BY TotalDeathCount DESC

SELECT location, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM CovidCaseStudy..CovidDeaths
WHERE continent = '' AND location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'European Union', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC





-- Global Breakdown

SELECT /*date,*/ SUM(NULLIF(CONVERT(float, new_cases), 0)) AS TotalCases, SUM(NULLIF(CONVERT(float, new_deaths), 0)) AS TotalDeaths, SUM(NULLIF(CONVERT(float, new_deaths), 0))/SUM(NULLIF(CONVERT(float, new_cases), 0))*100 AS GlobalDeathPercentage
FROM CovidCaseStudy..CovidDeaths
WHERE continent <> ''
--GROUP BY date
ORDER BY 1, 2





-- Total Population vs Vaccinations using CTE

WITH Pop_vs_Vac (Continent, Location, Date, Population, NewVaccinations, CumulativeVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, NULLIF(vac.new_vaccinations, '') as new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidCaseStudy..CovidDeaths dea
JOIN CovidCaseStudy..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ''
--ORDER BY 2, 3
)
SELECT *, (CumulativeVaccinations/Population)*100 CumulativeVaccinePercentage
FROM Pop_vs_Vac
--WHERE location = 'South Africa'





-- Total Population vs Vaccinations using Temp Table

DROP TABLE IF exists #PopulationVaccinationPercentage
CREATE TABLE #PopulationVaccinationPercentage 
(
Continent nvarchar (255), 
Location nvarchar (255), 
Date datetime, 
Population numeric, 
NewVaccinations numeric, 
CumulativeVaccinations numeric
)

INSERT INTO #PopulationVaccinationPercentage
SELECT dea.continent, dea.location, dea.date, dea.population, NULLIF(vac.new_vaccinations, '') as new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidCaseStudy..CovidDeaths dea
JOIN CovidCaseStudy..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ''
--ORDER BY 2, 3

SELECT *, (CumulativeVaccinations/Population)*100 CumulativeVaccinePercentage
FROM #PopulationVaccinationPercentage
ORDER BY 2, 3
--WHERE location = 'South Africa'




-- Views for vizzes/dashboard

--1.

--DROP VIEW IF exists TotalDeathPercentage
CREATE VIEW TotalDeathPercentage AS
SELECT SUM(CONVERT(float, new_cases)) AS total_cases,SUM(CONVERT(float, new_deaths)) AS total_deaths, SUM(CONVERT(float, new_deaths)) / SUM(NULLIF(CONVERT(float, new_cases), 0)) * 100 
AS DeathPercentage
FROM CovidCaseStudy..CovidDeaths
--WHERE location = 'South Africa'
WHERE continent <> ''
--ORDER BY 1, 2

SELECT *
FROM TotalDeathPercentage
ORDER BY 1, 2





--2.

--DROP VIEW IF exists GlobalDeathCount
CREATE VIEW GlobalDeathCount AS
SELECT dea.location AS Location, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM CovidCaseStudy..CovidDeaths dea
WHERE continent = '' AND location NOT IN ('World', 'International', 'European Union')
GROUP BY location
--ORDER BY TotalDeathCount DESC

SELECT *
FROM GlobalDeathCount
ORDER BY TotalDeathCount DESC




--3.

CREATE VIEW PercentagePopulationInfected AS
SELECT location, population, MAX(CAST(total_cases as float)) as HighestInfectionCount, NULLIF(MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))), 0) * 100 
AS PercentPopulationInfected
FROM CovidCaseStudy..CovidDeaths
-- WHERE location = 'South Africa'
GROUP BY location, population

SELECT *
FROM PercentagePopulationInfected
ORDER BY PercentPopulationInfected DESC




--4.

CREATE VIEW PercentageInfectedOverTime AS
SELECT location, population, date, MAX(CAST(total_cases as float)) as HighestInfectionCount, NULLIF(MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))), 0) * 100 
AS PercentPopulationInfected
FROM CovidCaseStudy..CovidDeaths
-- WHERE location = 'South Africa'
GROUP BY location, population, date

SELECT *
FROM PercentageInfectedOverTime
ORDER BY PercentPopulationInfected DESC





CREATE VIEW PopulationVaccinationPercentage AS
SELECT dea.continent, dea.location, dea.date, dea.population, NULLIF(vac.new_vaccinations, '') as new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidCaseStudy..CovidDeaths dea
JOIN CovidCaseStudy..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ''

SELECT *
FROM PopulationVaccinationPercentage