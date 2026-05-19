insert into gleb_d.cjm

SELECT 
md5(concat(
	(raw_data::jsonb ->> 'uid')::varchar, 
	(raw_data::jsonb -> 'registration_details' ->> 'registration_dtm')::varchar
	)) AS event_id,
(raw_data::jsonb ->> 'uid')::varchar AS customer_id,
(raw_data::jsonb -> 'registration_details' ->> 'registration_dtm')::timestamp AS event_dtm,
'registration' AS event_name,
insert_timestamp AS meta_timestamp,
'customer' as meta_process_name
FROM raw.customer c
where insert_timestamp > 
		coalesce((
		select max(meta_timestamp) 
		from gleb_d.cjm
		where meta_process_name = 'customer'
		), '1999-01-01')
;
