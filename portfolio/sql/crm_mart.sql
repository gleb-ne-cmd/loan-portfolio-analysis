create table if not exists gleb_d.crm_mart (
    com_id          text null,
    com_type        text null,
    dtm             text null,
    contact         text null,
    status          text null,
    provider        text null,
    type            text null,
    rate            text null,
    customer_id     varchar null,
    cost            float8 null,
    meta_timestamp  timestamp null
);

create temp table crm_contacts as
select
	md5(concat(
		'sms', 
		raw_data::jsonb ->> 'phone', 
		raw_data::jsonb ->> 'dtm'
	)) as com_id,
	'sms' as com_type,
	raw_data::jsonb ->> 'dtm' as dtm,
	raw_data::jsonb ->> 'phone' as contact,
	raw_data::jsonb ->> 'status' as status,
	raw_data::jsonb ->> 'provider' as provider,
	raw_data::jsonb ->> 'type' as type,
	raw_data::jsonb ->> 'rate' as rate,
	c.customer_id,
	cc.price as cost,
	insert_timestamp
from raw.crm_sms cs
left join core.customers c
	on cs.raw_data::jsonb ->> 'phone' = c.customer_phone
left join gleb_d.crm_costs cc
	on 'sms' = cc.com_type
	and cs.raw_data::jsonb ->> 'provider' = cc.provider
	and cs.raw_data::jsonb ->> 'type'     = cc.send_type
	and cs.raw_data::jsonb ->> 'rate'     = cc.rate
	and extract(quarter from (cs.raw_data::jsonb ->> 'dtm')::timestamp) = split_part(cc.quarter, 'Q', 2)::numeric
	and extract(year from (cs.raw_data::jsonb ->> 'dtm')::timestamp) = split_part(cc.quarter, 'Q', 1)::numeric
where insert_timestamp > (select coalesce(max(meta_timestamp), '2000-01-01') 
                          from gleb_d.crm_mart
                          where com_type = 'sms')

union all 

select
	md5(concat(
		'email', 
		raw_data::jsonb ->> 'email', 
		raw_data::jsonb ->> 'dtm'
	)) as com_id,
	'email' as com_type,
	raw_data::jsonb ->> 'dtm' as dtm,
	raw_data::jsonb ->> 'email' as contact,
	raw_data::jsonb ->> 'status' as status,
	raw_data::jsonb ->> 'provider' as provider,
	raw_data::jsonb ->> 'type' as type,
	raw_data::jsonb ->> 'rate' as rate,
	c.customer_id,
	cc.price as cost,
	insert_timestamp
from raw.crm_email ce
left join core.customers c
	on ce.raw_data::jsonb ->> 'email' = c.customer_email
left join gleb_d.crm_costs cc
	on 'email' = cc.com_type
	and ce.raw_data::jsonb ->> 'provider' = cc.provider
	and ce.raw_data::jsonb ->> 'type'     = cc.send_type
	and extract(quarter from (ce.raw_data::jsonb ->> 'dtm')::timestamp) = split_part(cc.quarter, 'Q', 2)::numeric
	and extract(year from (ce.raw_data::jsonb ->> 'dtm')::timestamp) = split_part(cc.quarter, 'Q', 1)::numeric
where insert_timestamp > (select coalesce(max(meta_timestamp), '2000-01-01') 
                          from gleb_d.crm_mart
                          where com_type = 'email')
;

insert into gleb_d.crm_mart
select 
	com_id,
	com_type,
	dtm,
	contact,
	status,
	provider,
	type,
	rate,
	customer_id,
	cost,
	insert_timestamp as meta_timestamp
from crm_contacts c
;
