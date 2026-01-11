use hospital_db

Objective 1
Encounters overview
Your first objective is to become familiar with the encounters table by slicing the data by years, encounter class and encounter length.

Task

How many total encounters occurred each year?
select year(start) as yr, count(id) as total_encounters
from encounters
group by yr
order by 1

For each year, what percentage of all encounters belonged to each encounter class
(ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?

select year(start) as yr,
       round(avg(case when encounterclass = 'ambulatory' then 1 else 0 end)*100,1) as ambulatory,
       round(avg(case when encounterclass = 'outpatient' then 1 else 0 end)*100,1) as outpatient,
       round(avg(case when encounterclass = 'wellness' then 1 else 0 end)*100,1) as wellness,
       round(avg(case when encounterclass = 'urgentcare' then 1 else 0 end)*100,1) as urgentcare,
       round(avg(case when encounterclass = 'emergency' then 1 else 0 end)*100,1) as emergency,
       round(avg(case when encounterclass = 'inpatient' then 1 else 0 end)*100,1) as inpatient,
       count(*) as num_encounters
from encounters
group by yr
order by yr

What percentage of encounters were over 24 hours versus under 24 hours?

select 
      round(avg(case when timestampdiff(hour, start, stop) >= 24 then 1 else 0 end)*100,1) as over_24_hrs,
      round(avg(case when timestampdiff(hour, start, stop) < 24 then 1 else 0 end)*100,1) as under_24_hrs
from encounters

Objective 2

Cost & coverage insights

Your next objective is to analyze payer coverage, top procedures by frequency and cost, and average claim costs by payer.
Task

How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
select sum(case when payer_coverage = 0.00 then 1 else 0 end) as num_encounters,
       round(avg(case when payer_coverage = 0.00 then 1 else 0 end)*100,1) as total_encunters
from encounters

What are the top 10 most frequent procedures performed and the average base cost for each?
select * from
(
select code,description, count(*) as num_procedures, avg(base_cost) as avg_base_cost,
       rank() over(order by count(*) desc) as rnk
from procedures
group by code,description
order by 3 desc
)x
where x.rnk between 1 and 10

What are the top 10 procedures with the highest average base cost and the number of times they were performed?
select * from
(
select code,description, count(*) as num_procedures, avg(base_cost) as avg_base_cost,
       rank() over(order by avg(base_cost) desc) as rnk
from procedures
group by code,description
order by 4 desc
)x
where x.rnk <= 10

What is the average total claim cost for encounters, broken down by payer?
select p.name as payer_name, round(avg(total_claim_cost),2) as avg_tcc
from encounters e right join payers p on e.payer = p.id
group by payer_name
order by 2 

Objective 3
Patient behavior analysis
Your final objective is to analyze patient behavior by tracking quarterly admissions and 30-day readmissions.

Task

How many unique patients were admitted each quarter over time?
select quarter(start) as quarter, count(distinct patient) as num_unique_patients
from encounters e
group by quarter
order by 1

How many patients were readmitted within 30 days of a previous encounter?
with cte as
 (
 select patient, start, stop,
        lead(start) over(partition by patient order by start) as next_start_date
 from encounters
 )
 select count( distinct patient) as num_patients
 from cte
 where datediff(next_start_date, stop) < 30

Which patients had the most readmissions?

with cte as
 (
 select patient, start, stop,
        lead(start) over(partition by patient order by start) as next_start_date
 from encounters
 )
 select patient, count(*) as num_admissions
 from cte
 where datediff(next_start_date, stop) < 30
 group by patient
 order by 2 desc
