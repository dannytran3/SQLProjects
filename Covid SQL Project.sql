
SELECT * 
FROM SQLProjects.dbo.CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 3, 4


-- Data of CovidDeaths Table
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM SQLProjects.dbo.CovidDeaths$
ORDER BY 1, 2

-- Total Cases vs Total Deaths
-- Shows death rates if you contract covid in specified country
SELECT Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / CONVERT(float, total_cases))*100 AS Death_Rate
FROM SQLProjects.dbo.CovidDeaths$
WHERE Location LIKE '%states%'
ORDER BY 1, 2

-- Total Cases vs Population
-- Shows percentage of a population that contracted covid
SELECT Location, date, population, total_cases, (CONVERT(float, total_cases) / CONVERT(float, population))*100 AS Covid_Rate_Per_Population
FROM SQLProjects.dbo.CovidDeaths$
WHERE Location LIKE '%states%'
ORDER BY 1, 2

-- Countries with Highest Infection Rate compared to Population
SELECT Location, population, MAX(CONVERT(float, total_cases)) AS Highest_Infection_Count, MAX(CONVERT(float, total_cases) / CONVERT(float, population))*100 AS Percent_Population_Infected
FROM SQLProjects.dbo.CovidDeaths$
GROUP BY Location, population
ORDER BY Percent_Population_Infected DESC

-- Countries with Highest Death Count per Population
-- Death per Population percentage
SELECT Location, population, MAX(CONVERT(float, total_deaths)) AS Death_Count, MAX(CONVERT(float, total_deaths) / CONVERT(float, population)) * 100 AS Highest_Death_Rate
FROM SQLProjects.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY Death_Count DESC

-- Continents with Highest Death Count
SELECT continent, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM SQLProjects.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC

-- Global Numbers
-- Every day deaths per population
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths,
CASE 
    WHEN SUM(New_cases) = 0 THEN 0 -- Handle divide by zero scenario
    ELSE SUM(cast(new_deaths AS INT)) / SUM(New_cases) * 100 
END AS Death_Rate
FROM SQLProjects.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Total deaths worldwide and death rate
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths,
CASE 
    WHEN SUM(New_cases) = 0 THEN 0 -- Handle divide by zero scenario
    ELSE SUM(cast(new_deaths AS INT)) / SUM(New_cases) * 100 
END AS Death_Rate
FROM SQLProjects.dbo.CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2


-- USE CTE HERE
WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
From SQLProjects..CovidDeaths$ dea
JOIN SQLProjects..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (Rolling_People_Vaccinated/Population) * 100
FROM PopvsVac


-- Making Temp Table
DROP TABLE IF EXISTS #Percent_Population_Vaccinated
CREATE TABLE #Percent_Population_Vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT INTO #Percent_Population_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
From SQLProjects..CovidDeaths$ dea
JOIN SQLProjects..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (Rolling_People_Vaccinated/Population) * 100
FROM #Percent_Population_Vaccinated


-- Creating View to store data for future visualizations

CREATE VIEW Percent_Population_Vaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
From SQLProjects..CovidDeaths$ dea
JOIN SQLProjects..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM Percent_Population_Vaccinated
