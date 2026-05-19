insert into gleb_d.cjm

select 
md5(concat(customer_id, auth_date)) as event_id,
customer_id,
auth_date as event_dtm,
concat('auth', auth_method) as event_name,
auth_date as meta_timestamp,
'customer_auth' as meta_process_name
from raw.customer_auth ca 
where auth_date > coalesce((select max(meta_timestamp) 
					from gleb_d.cjm
					where meta_process_name = 'customer_auth'), '1999-01-01')
;
