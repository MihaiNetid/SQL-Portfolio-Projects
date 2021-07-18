use PortfolioProject;

select * 
from PortfolioProject.dbo.CovidDeaths
order by 3,4;

select * 
from PortfolioProject.dbo.CovidVaccination
order by 3,4;


--Select Data that we are going to be using

select [Location], [date], total_cases, new_cases, total_deaths, [population]
from PortfolioProject..CovidDeaths
order by 1,2;


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid

select [Location], [date], total_cases, total_deaths, 
cast((total_deaths/total_cases)*100.0 as decimal(5,2)) as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%moldova%'
and continent is not null
order by 1,2;


-- Looking at the Total Cases vs Population
-- Shows what percentage of population got Covid

select [Location], [date], [population], total_cases, 
cast((total_cases/population)*100.0 as decimal(5,2)) as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2;


-- Looking at countries with Higher Infection Rate compared to population

select [Location], [population], max(total_cases)as HighestInfectionCount, 
max(cast((total_cases/population)*100.0 as decimal(5,2))) as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
group by [Location], [population]
order by PercentPopulationInfected desc;


-- Showing countries with Highest Death Count per Population

select [location], max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by [Location]
order by TotalDeathCount desc;


-- LET"S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc;


-- GLOBAL NUMBERS
-- cast((total_deaths/total_cases)*100.0 as decimal(5,2)) as DeathPercentage
select sum(new_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, 
cast(sum(cast(new_deaths as int))/sum(new_cases)*100.0 as decimal(5,2)) as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
--group by date
order by 1,2;


-- Looking at Total Population vs Vaccinations
-- Using CAST
select dea.continent, dea.[location], dea.[date], dea.[population], vac.new_vaccinations 
, sum(cast(new_vaccinations as int)) over 
(partition by dea.[location]  order by dea.[location], dea.[date]) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.[location]=vac.[location]
	and dea.[date] = vac.[date]
where dea.continent is not null
order by 2,3;

-- Using CONVERT
select dea.continent, dea.[location], dea.[date], dea.[population], vac.new_vaccinations 
, sum(convert(int, new_vaccinations)) over 
(partition by dea.[location] order by dea.[location], dea.[date]) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.[location]=vac.[location]
	and dea.[date] = vac.[date]
where dea.continent is not null
order by 2,3;


-- Using CTE
with PopvsVac (continent, [location], [date], [population], new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.[location], dea.[date], dea.[population], vac.new_vaccinations 
, sum(convert(int, new_vaccinations)) over 
(partition by dea.[location] order by dea.[location], dea.[date]) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.[location]=vac.[location]
	and dea.[date] = vac.[date]
where dea.continent is not null
--order by 2,3
)
select *, cast((RollingPeopleVaccinated/[population])*100 as decimal(5,2)) as Percentage
from PopvsVac;


-- TEMP TABLE
Drop table if exists #PercentPopulationVaccinated;

Create table #PercentPopulationVaccinated
(
continent nvarchar(255),
[location] nvarchar(255),
[date] datetime,
[population] numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
);

Insert into #PercentPopulationVaccinated
select dea.continent, dea.[location], dea.[date], dea.[population], vac.new_vaccinations 
, sum(convert(numeric,vac.new_vaccinations)) over 
(partition by dea.[location] order by dea.[location], dea.[date]) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.[location]=vac.[location]
	and dea.[date] = vac.[date];


select *, cast((RollingPeopleVaccinated/[population])*100 as decimal(5,2)) as Percentage
from #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

drop view if exists PercentPopulationVaccinated;
Create view PercentPopulationVaccinated as
select dea.continent, dea.[location], dea.[date], dea.[population], vac.new_vaccinations 
, sum(convert(numeric,vac.new_vaccinations)) over 
(partition by dea.[location] order by dea.[location], dea.[date]) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccination vac
	on dea.[location]=vac.[location]
	and dea.[date] = vac.[date]
where dea.continent is not null
--order by 2,3;
;

select *
from PercentPopulationVaccinated;
















