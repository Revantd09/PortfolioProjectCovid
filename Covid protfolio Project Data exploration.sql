
select *
from PortfolioProject..covidDeaths
where continent is not null
order by 3,4 

--select *
--from PortfolioProject..covidvaccinations
--order by 3,4

--select data that we are going to be using

select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..covidDeaths
order by 1,2

-- Looking at total cases vs total Deaths
-- Shows the likelihood of dying if you contract covid in your country
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..covidDeaths
where location Like '%India%'
order by 1,2

--looking at Total cases vs Population
--shows what percentage of population got covid
select Location, date, total_cases, Population, (total_deaths/population)*100 as PercentPopulationInfected
from PortfolioProject..covidDeaths
where location Like '%India%'
order by 1,2

-- Looking at countries with highest infection rate compared to population
select Location, Population, Max(total_cases) as HighesInfectionCount, Max((total_deaths/population))*100 as PercentPopulationInfection
from PortfolioProject..covidDeaths
--where location Like '%India%'
group by location, population
order by PercentPopulationInfection desc

-- Showing countries with highest Death count per popoulation
select Location, Max(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProject..covidDeaths
--where location Like '%India%'
where continent is not null
group by location
order by TotalDeathCount desc

-- lets break things down by continent
-- showing continents with highest death count per population

select continent, Max(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProject..covidDeaths
--where location Like '%India%'
where continent is not null
group by continent
order by TotalDeathCount desc

-- Breaking GLobal numbers
select sum(new_cases) as total_cases, sum(cast(new_Deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..covidDeaths
where continent is not null
--group by date
order by 1,2

select date,sum(new_cases) as total_cases, sum(cast(new_Deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..covidDeaths
where continent is not null
group by date
order by 1,2

-- Looking at Total Population vs Vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) Over(partition by dea.location order 
by dea.location,dea.date) as RollingPeopleVaccinated
--,(RollingPeoplevaccinated/population)*100
--cannot use a column name created in select statement to calculate a 
-- we use a "CTE" function to perform such a operation 
from PortfolioProject..covidDeaths dea
join PortfolioProject..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Use CTE
with PopvsVac (Continent, Location, Date, population,New_vaccinations, RollingPeopleVaccinated)
as
(
-- if number of columns in CTE is different than columns in select statement its gonna give you a error
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) Over(partition by dea.location order 
by dea.location,dea.date) as RollingPeopleVaccinated
from PortfolioProject..covidDeaths dea
join PortfolioProject..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select * , (RollingPeopleVaccinated/population)*100
from PopvsVac


--Temp Table

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric,
)
Insert Into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) Over(partition by dea.location order 
by dea.location,dea.date) as RollingPeopleVaccinated
from PortfolioProject..covidDeaths dea
join PortfolioProject..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

Select * ,(RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


--Creating View to store Data for later visualizations

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) Over(partition by dea.location order 
by dea.location,dea.date) as RollingPeopleVaccinated
from PortfolioProject..covidDeaths dea
join PortfolioProject..covidvaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3


select * 
from PercentPopulationVaccinated






