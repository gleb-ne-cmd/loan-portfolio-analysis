insert into gleb_d.cjm

SELECT DISTINCT ON (c.customer_phone, event_dtm)
md5(concat(c.customer_phone, (raw_data::jsonb ->> 'dtm')::timestamp)) AS event_id,
customer_id,
(raw_data::jsonb ->> 'dtm')::timestamp AS event_dtm,
'sms' AS event_name,
s.insert_timestamp AS meta_timestamp,
'crm_sms' as meta_process_name
FROM raw.crm_sms s
JOIN core.customers c 
ON (raw_data::jsonb ->> 'phone')::varchar = c.customer_phone 
AND (raw_data::jsonb ->> 'dtm')::timestamp > registration_dtm
where s.insert_timestamp > coalesce((
		select max(meta_timestamp) 
		from gleb_d.cjm
		where meta_process_name = 'crm_sms'
		), '1999-01-01')
ORDER BY c.customer_phone, (raw_data::jsonb ->> 'dtm')::timestamp, registration_dtm DESC 
;
