-- analysis of real police data (Poliec_Department_Incident_reports.csv)
-- https://data.sfgov.org/Public-Safety/Police-Department-Incident-Reports-2018-to-Present/wg3w-h783

use Portfolio_Police_Department_SF;


-- describe tables
exec sp_columns PD_Incident_Details;
exec sp_columns PD_Incident_Locations;


-- drop table if exists PD_Incident_Details;
select *
from PD_Incident_Details
order by 1, 2;

select * 
from PD_Incident_Locations;

select *
from PD_Incident_Details d
join PD_Incident_Locations l
on d.Incident_ID=l.Incident_ID;


-- Rename a column with a query
exec sp_rename 'Portfolio_Police_Department_SF.dbo.PD_Incident_Details.[IncidentDate]', 'Incident_Date', 'COLUMN';


-- Looking at daily number of incidents
select Incident_Date, count(Incident_ID) as Daily_Incidents
from PD_Incident_Details
group by Incident_Date
order by Incident_Date;


-- Looking at daily number of incidents in 2021
select Incident_Day_of_Week, count(Incident_ID) as Daily_Incidents -- 43466 total incidents
from PD_Incident_Details
where Incident_Date between '2021-01-01' and '2021-05-22'
group by Incident_Day_of_Week
order by Incident_Day_of_Week;


-- Looking at monthly number of 'Lost Property'
select datename(yyyy,Incident_Date) as Incident_Year
	, datename(MM,Incident_Date)+ ' ' + datename(YYYY,Incident_Date) as [Year_Month]
	, count(Incident_Category) as Lost_Properties
from PD_Incident_Details
where Incident_Category = 'Lost Property'
group by datename(yyyy,Incident_Date)
	, datepart(MM,Incident_Date)
	, datename(MM,Incident_Date)+ ' ' + datename(YYYY,Incident_Date)
order by Incident_Year, datepart(MM,Incident_Date);


-- Looking at hourly incidents in 'Tenderloin' in 2020
select DATEPART(HH, det.Incident_Time) as [Hour], 
count(det.Incident_ID) as cnt_incidents, loc.Analysis_Neighborhood -- 19372 total incidents
from PD_Incident_Details det
join PD_Incident_Locations loc on det.Incident_ID=loc.Incident_ID
where loc.Analysis_Neighborhood like '%Tenderloin%'
and Incident_Date between '2020-01-01' and '2020-12-31'
group by DATEPART(HH, det.Incident_Time), loc.Analysis_Neighborhood
order by [Hour]; 


-- Looking at Incidents in percents
select Incident_Category
	, count(Incident_Category) as cnt_Incidents
	, cast(count(Incident_Category)*100.0/sum(count(Incident_Category)) 
	over() as decimal(5,2)) as Percentage
from PD_Incident_Details
where Incident_Category is not null
group by Incident_Category
order by cnt_Incidents desc;


-- Temp Tables
drop table if exists #temp_Incident_Details
create table #temp_Incident_Details (
Incident_ID float(8),
Analysis_Neighborhood nvarchar(510));

-- insert only 2 columns from table PD_Incident_Locations into the temp table #temp_Incident_Details
insert into #temp_Incident_Details
select Incident_ID, Analysis_Neighborhood
from PD_Incident_Locations
where Analysis_Neighborhood is not null;

-- counting number of unique incidents in Financial District/South Beach Neighborhood
select *, count(Incident_ID) as cnt_Incidents
from #temp_Incident_Details
where Analysis_Neighborhood = 'Financial District/South Beach'
group by Incident_ID, Analysis_Neighborhood
order by Analysis_Neighborhood, cnt_Incidents desc;


-- counting number of incidents per dayweek
with cte_incidents as (select Incident_Day_of_Week, count(Incident_ID) as cnt_incidents
from PD_Incident_Details
group by Incident_Day_of_Week)
select sum(cnt_incidents) as incidents_weekend
from cte_incidents
where Incident_Day_of_Week in ('Saturday', 'Sunday');


-- counting number of incidents per weekdays and weekends for Missing Adult Incident Subcategory using self join
with cte_all as (
	select sum(a.cnt_incidents) as [Mon-Fri], 
	sum(b.cnt_incidents) as [Sat-Sun]
	from (
		select Incident_Day_of_Week, count(Incident_ID) as cnt_incidents
		from PD_Incident_Details
		where Incident_Day_of_Week in ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
		and Incident_Subcategory = 'Missing Adult'
		group by Incident_Day_of_Week) a
	full join (
		select Incident_Day_of_Week, count(Incident_ID) as cnt_incidents
		from PD_Incident_Details
		where Incident_Day_of_Week in ('Saturday', 'Sunday')
		and Incident_Subcategory = 'Missing Adult'
		group by Incident_Day_of_Week) b
	on a.Incident_Day_of_Week=b.Incident_Day_of_Week)
select [Mon-Fri],
cast([Mon-Fri]*100.0/([Mon-Fri] + [Sat-Sun]) as decimal (5,2)) as [Percentage],
[Sat-Sun],
cast([Sat-Sun]*100.0/([Mon-Fri] + [Sat-Sun]) as decimal (5,2)) as [Percentage]
from cte_all
group by [Mon-Fri], [Sat-Sun];
