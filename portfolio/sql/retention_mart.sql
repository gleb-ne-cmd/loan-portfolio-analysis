create table if not exists gelb_d.retention_mart (
	cohort_month date null,
	cohort_size int8 null,
	order_month date null,
	month_offset numeric null,
	customers int8 null,
	retention_rate numeric null,
	meta_timestamp timestamp default current_timestamp
);

create temporary table paid_orders as 
select
id,
order_date::date  as order_date,
date_trunc('month', order_date)::date as order_month,
customer_id
from core.orders
where order_type = 'paid';

truncate table gleb_d.retention_mart;

insert into gleb_d.retention_mart(cohort_month, cohort_size, order_month, month_offset, customers, retention_rate)

with cohort as (
select 
customer_id, 
min(order_month) as cohort_month
from paid_orders 
group by customer_id
),

cohort_size as (
select
cohort_month,
count(distinct customer_id) as cohort_size
from cohort
group by cohort_month
)

select
c.cohort_month,
s.cohort_size,
o.order_month,
extract(month from age(o.order_month, c.cohort_month)) as month_offset,
count(distinct o.customer_id) as customers,
round(count(distinct o.customer_id)::numeric * 100 / s.cohort_size::numeric, 2) as retention_rate
from paid_orders o
join cohort c
on o.customer_id = c.customer_id
join cohort_size s
on s.cohort_month = c.cohort_month
group by 1, 2, 3, 4;

drop table if exists paid_orders;
