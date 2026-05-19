insert into gleb_d.cjm

select 
(raw_data::jsonb ->> 'purchase_id')::varchar as event_id,
(raw_data::jsonb ->> 'customer_id')::varchar as customer_id,
(raw_data::jsonb ->> 'purchase_dtm')::timestamp as event_dtm,
'order' as event_name,
insert_timestamp as meta_timestamp,
'purchase' as meta_process_name
from raw.purchase 
where insert_timestamp > coalesce((
		select max(meta_timestamp) 
		from gleb_d.cjm
		where meta_process_name = 'purchase'
		), '1999-01-01')
;
