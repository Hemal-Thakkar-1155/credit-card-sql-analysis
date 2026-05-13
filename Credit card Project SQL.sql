
--**Credit card transaction analysis

/* # Project Overview
This project analyzes credit card transaction data to identify:
- Spending patterns
- Card usage trends
- Customer behavior
- City-wise transaction insights

# Skills Used
- SQL
- Window Functions
- CTEs
- Aggregate Functions
- Ranking Functions */

--Business Problems

select  * from credit_card_transcations$

--1. Top 5 cities by spend contribution

select top 5 city,
sum(amount) as total_sepnd,
ROUND((sum(amount)*100)/(select sum(amount)
from credit_card_transcations$),2) as per_amount
from credit_card_transcations$
group by city
order by total_sepnd desc


--2. Highest spend month by card type

with monthly_spend as (select card_type,
DATEPART(YEAR,transaction_date) as yearr,
DATENAME(month,transaction_date) as monthh,
sum(amount) as total_spend
from credit_card_transcations$
group by DATEPART(YEAR,transaction_date),DATENAME(month,transaction_date),card_type),

highest_spent_month as (select *,Rank() over (partition by 
card_type order by total_spend desc) as rn from monthly_spend)

select card_type,yearr, monthh, total_spend
from highest_spent_month
where rn = 1


--3. Million cumulative spend transaction

select * from credit_card_transcations$

with cum_table as (select *,sum(amount) over (partition by card_type ORDER BY transaction_date, transaction_id) as 
cumilative_spend
from credit_card_transcations$),

numbers as (select *,ROW_NUMBER() over (partition by card_type
order by cumilative_spend) as rn from cum_table
where cumilative_spend >= 100000)

select * from numbers
where rn = 1


--4. Lowest Gold card spend city

with total_spend as (select sum(amount) as total_spend from credit_card_transcations$
where card_type = 'Gold'
group by card_type),

gold_spend as (select city,card_type,sum(amount) as total_spend_gold from
credit_card_transcations$
where card_type = 'Gold'
group by city,card_type)


select top 1
g.city,
g.card_type,
ROUND(total_spend_gold/total_spend ,2) as per_total
from gold_spend g
cross join 
total_spend t
order by per_total asc

--5. Highest and lowest expense type by city


with cte as (select city,exp_type,sum(amount) as total_amt from credit_card_transcations$
group by city,exp_type),

columns as (select *,RANK() over (partition by city order by total_amt desc) as highest_rank,
RANK() over (partition by city order by total_amt asc) as lowest_rank
from cte)

select city,max(case when highest_rank = 1 then exp_type end) as highest_exp_type
,max(case when lowest_rank = 1 then exp_type end) as lowest_exp_type
from columns
group by city


--6. Female spend contribution

with female_spend as (select exp_type,sum(amount) as total_female_spend
from
credit_card_transcations$
where gender = 'F'
group by exp_type),

total_spend as (select exp_type,sum(amount) as total_spend
from
credit_card_transcations$
group by exp_type)

select t.exp_type,round((f.total_female_spend*100)/t.total_spend,2) as per_spent
from female_spend f
join total_spend t
on t.exp_type = f.exp_type


--7. Highest MoM growth in Jan-2014



with monthly_spend as (select card_type,exp_type,sum(amount) as total_amt,
DATEpart(month,transaction_date) as month,
DATEpart(YEAR,transaction_date) year
from credit_card_transcations$
group by card_type,exp_type,DATEpart(month,transaction_date),DATEpart(YEAR,transaction_date)),

mom_spend as (select card_type,exp_type,year,month,total_amt,

LAG(total_amt) over (partition by card_type,exp_type order by year,month) as pre_month
from monthly_spend)

select top 1
card_type,exp_type,pre_month,total_amt,(total_amt - pre_month) as month_growth
from mom_spend
where year = 2014
and MONTH = 1
and pre_month is not null
order by month_growth desc

--8. Weekend spend efficiency 

with weekend as(select 
city, 
sum(amount) as total_spend,
count(*) as total_transcations
from credit_card_transcations$
where DATENAME(WEEKDAY,transaction_date) in ('Saturaday','Sunday')
group by city)

select top 1
city,
total_spend,
total_transcations,
ROUND((total_spend*1.0)/total_transcations,2) as tran_ratio
from
weekend
group by city,total_spend,total_transcations
order by tran_ratio desc

--9. Fastest city to reach 500 transactions

with total_tran as (select city,transaction_date,
row_number() over (partition by city order by transaction_date) as rn 
from 
credit_card_transcations$),

first_tarn as ( select city,min(transaction_date) as first_trans
from
credit_card_transcations$
group by city),

fiveh_trans as (select city,transaction_date as fiveh_tran
from total_tran
where rn = 500)

select top 1
f.city,
f.first_trans,
t.fiveh_tran,
datediff(day,f.first_trans , t.fiveh_tran) as days_taken
from first_tarn f join fiveh_trans t
on f.city = t.city
order by days_taken desc















