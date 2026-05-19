insert into gleb_d.cjm

SELECT 
md5(concat(customer_id,customer_delete_dtm)) AS event_id,
customer_id,
customer_delete_dtm AS event_dtm,
'delete' AS event_name,
customer_delete_dtm AS meta_timestamp,
'customer_delete' as meta_process_name
FROM raw.customer_delete
where customer_delete_dtm > coalesce((
		select max(meta_timestamp) 
		from gleb_d.cjm
		where meta_process_name = 'customer_delete'
		), '1999-01-01')
;
