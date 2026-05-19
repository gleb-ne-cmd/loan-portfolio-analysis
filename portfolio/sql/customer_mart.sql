create table if not exists gleb_d.customer_mart (
	customer_id varchar(50) null,
	first_name text null,
	last_name text null,
	birth_date date null,
	gender varchar(1) null,
	customer_phone varchar(20) null,
	customer_email varchar null,
	phone_is_confirmed bool null,
	email_is_confirmed bool null,
	registration_dtm timestamp null,
	registration_source varchar(20) null,
	first_auth_dtm timestamp null,
	first_auth_method varchar null,
	last_auth_dtm timestamp null,
	last_auth_method varchar null,
	auth_method text[] null,
	auth_count int8 null,
	passport_series varchar null,
	passport_number varchar null,
	passport_valid_dtm varchar null,
	dl_series varchar null,
	dl_number varchar null,
	dl_valid_dtm varchar null,
	passport_all jsonb null,
	dl_all jsonb null,
	customer_delete_dtm timestamp null,
	meta_timestamp timestamp null
);

create temp table customer_id_increment as

select customer_id
from core.customers
where meta_timestamp > (select coalesce(
						max(meta_timestamp), '1900-01-01')::timestamp 
						from gleb_d.customer_mart)
union all
select customer_id
from raw.customer_auth
group by customer_id
having max(auth_date) > (select coalesce(
						max(meta_timestamp), '1900-01-01')::timestamp 
						from gleb_d.customer_mart)
union all
select raw_data::jsonb ->> 'customer_id'
from raw.customer_documents
where insert_timestamp > (select coalesce(
						max(meta_timestamp), '1900-01-01')::timestamp 
						from gleb_d.customer_mart)
union all
select customer_id
from raw.customer_delete
where customer_delete_dtm > (select coalesce(
						max(meta_timestamp), '1900-01-01')::timestamp 
						from gleb_d.customer_mart)
;

create temp table customers_increment as 

with rn_auth as (
select customer_id,
	auth_method,
	row_number() over (partition by customer_id order by auth_date) as first,
	row_number() over (partition by customer_id order by auth_date desc) as last,
	auth_date::timestamp as auth_date
from raw.customer_auth
where exists (
    select 1 from customer_id_increment inc 
    where raw.customer_auth.customer_id = inc.customer_id
    )
),

auth as (
select 
	customer_id,
	array_agg(distinct auth_method) as auth_method,
	max(auth_method) filter (where first = 1) as first_auth_method,
	max(auth_method) filter (where last = 1) as last_auth_method,
	min(auth_date)::timestamp as first_auth_dtm,
	max(auth_date)::timestamp as last_auth_dtm,
	count(distinct auth_date) as auth_count,
	bool_or(auth_method in ('sms', 'push', '2fa', 'mfa')) as phone_is_confirmed,
	bool_or(auth_method = 'email') as email_is_confirmed
from rn_auth
group by customer_id 
),

total_documents as (
select distinct on (raw_data::jsonb ->> 'customer_id', 
					raw_data::jsonb ->> 'document_type')
	raw_data::jsonb ->> 'customer_id' as customer_id,
	raw_data::jsonb ->> 'document_type' as document_type,
	raw_data::jsonb ->> 'series' as series,
	raw_data::jsonb ->> 'number' as number,
	raw_data::jsonb ->> 'valid_dtm' as valid_dtm
from raw.customer_documents
	where exists (
    select 1 from customer_id_increment inc 
    where raw.customer_documents.raw_data::jsonb ->> 'customer_id' = inc.customer_id
    )
order by raw_data::jsonb ->> 'customer_id', 
		 raw_data::jsonb ->> 'document_type', insert_timestamp desc
),

doc_passport as (
select
	customer_id,
	series as passport_series,
	number as passport_number,
	valid_dtm as passport_valid_dtm
from total_documents
where document_type = 'passport'
),

doc_driver as (
select
	customer_id,
	series as dl_series,
	number as dl_number,
	valid_dtm as dl_valid_dtm
from total_documents
where document_type = 'driver_license'
),

all_docs as (
select 
	raw_data::jsonb ->> 'customer_id' as customer_id,
	json_agg(json_build_object( 
			'series',    raw_data::jsonb ->> 'series',
        	'number',    raw_data::jsonb ->> 'number',
        	'valid_dtm', raw_data::jsonb ->> 'valid_dtm'
	)) filter (
			where raw_data::jsonb ->> 'document_type' = 'passport'
			  ) as passport_all,
	json_agg(json_build_object( 
			'series',    raw_data::jsonb ->> 'series',
        	'number',    raw_data::jsonb ->> 'number',
        	'valid_dtm', raw_data::jsonb ->> 'valid_dtm'
	)) filter (
			where raw_data::jsonb ->> 'document_type' = 'driver_license'
			  ) as dl_all
from raw.customer_documents
where exists (
    select 1 from customer_id_increment inc 
    where raw.customer_documents.raw_data::jsonb ->> 'customer_id' = inc.customer_id
    )
group by raw_data::jsonb ->> 'customer_id'
),

cust_del as (
select distinct on (customer_id)
	customer_id,
	customer_delete_dtm::timestamp
from raw.customer_delete
where exists (
    select 1 from customer_id_increment inc 
    where raw.customer_delete.customer_id = inc.customer_id
    )
order by customer_id, customer_delete_dtm desc
)

select
    c.customer_id,
    split_part(c.customer_name, ' ', 1)    as first_name,
    split_part(c.customer_name, ' ', 2)    as last_name,
    c.birth_date,
    c.gender,
    c.customer_phone,
    c.customer_email,
    a.phone_is_confirmed,
    a.email_is_confirmed,
    c.registration_dtm,
    c.registration_source,
    a.first_auth_dtm,
    a.first_auth_method,
    a.last_auth_dtm,
    a.last_auth_method,
    a.auth_method,
    a.auth_count,
    dp.passport_series,
    dp.passport_number,
    dp.passport_valid_dtm,
    dd.dl_series,
    dd.dl_number,
    dd.dl_valid_dtm,
    ad.passport_all::jsonb as passport_all,
    ad.dl_all::jsonb       as dl_all,
    cd.customer_delete_dtm,
    greatest(c.meta_timestamp, a.last_auth_dtm, cd.customer_delete_dtm) as meta_timestamp
from core.customers c
left join auth a           using (customer_id)
left join doc_passport dp  using (customer_id)
left join doc_driver dd    using (customer_id)
left join all_docs ad      using (customer_id)
left join cust_del cd      using (customer_id)
where exists (
    select 1 from customer_id_increment inc 
    where c.customer_id = inc.customer_id
    )
;

delete from gleb_d.customer_mart 
where exists (
	select 1 from customer_id_increment inc
	where inc.customer_id = customer_mart.customer_id
	)
;

insert into gleb_d.customer_mart
select *
from customers_increment
;
