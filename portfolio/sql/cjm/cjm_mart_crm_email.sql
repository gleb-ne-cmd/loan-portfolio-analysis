insert into gleb_d.cjm

SELECT DISTINCT ON (c.customer_email, event_dtm)
md5(concat(c.customer_email, (raw_data::jsonb ->> 'dtm')::timestamp)) AS event_id,
customer_id,
(raw_data::jsonb ->> 'dtm')::timestamp AS event_dtm,
'email' AS event_name,
s.insert_timestamp AS meta_timestamp,
'crm_email' as meta_process_name
FROM raw.crm_email s
JOIN core.customers c 
ON (raw_data::jsonb ->> 'email')::varchar = c.customer_email
AND (raw_data::jsonb ->> 'dtm')::timestamp > registration_dtm
where s.insert_timestamp > coalesce((
		select max(meta_timestamp) 
		from gleb_d.cjm
		where meta_process_name = 'crm_email'
		), '1999-01-01')
ORDER BY c.customer_email, (raw_data::jsonb ->> 'dtm')::timestamp, registration_dtm desc
;
