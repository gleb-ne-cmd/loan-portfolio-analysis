insert into gleb_d.ym_mart
with full_visits_ids as (
select
visitid,
unnest(string_to_array(trim(watchids, '[]'), ',')) as watchid,
isnewuser::bool,
starturl,
endurl,
pageviews,
visitduration,
regioncountry,
regioncity
from raw.ym_visits
),

clean_url as (
select 
watchid,
counteruseridhash,
datetime,
referer,
split_part(url, '?', 1) as url,
devicecategory,
ispageview,
link,
artificial,
insert_dtm
from raw.ym_hits
),

full_hits as (
select 
watchid,
counteruseridhash,
datetime,
referer,
url,
case 
	when url like '%t.me%' then 'tg'
	when url like '%google.com/forms' then 'google forms'
	when url like '%github%' then 'github'
	when url like '%disk.yandex%' then 'yandex disk'
	when url like '%vk.com/data_study%' then 'vk group'
	when url like '%instagram.com%' then 'instagram'
	when url like '%youtube%' then 'youtube'
	when url like '%drive.google%' then 'google drive'
	else 'other'
end as external_resource,
case
	when url like 'https://datastudy.ru/1%' then 'ОАД'
	when url like 'https://datastudy.ru/webinars%' then 'Вебинары'
	when url like 'https://datastudy.ru/oferta%' then 'Оферта'
	when url like '%#rec1771710121%' then 'SQL программа'
	when url like '%#rec1774936751%' then 'SQL оплата'
	when url like '%#rec1774669311%' then 'SQL формат занятий'
	when url like '%#rec1774786221%' then 'SQL отзывы'
	when url like '%#rec1771710081%' then 'SQL преимущества'
	when url like '%#rec1774944811%' then 'SQL стоимость'
	when url like 'https://datastudy.ru/quiz%' then 'Квиз'
	when url like 'https://datastudy.ru/check_list%' then 'Чек-лист'
	when url like 'https://datastudy.ru/' then 'Главная'
	else 'Другое'
end as page_title,
case
	when devicecategory = '1' then 'laptop'
	else 'phone'
end as device_type,
case
	when ispageview = '1' then 'view'
	when link = '1' then 'click'
	else 'artificial'
end as event_type,
insert_dtm
from clean_url
)

select 
fh.watchid,
fh.counteruseridhash,
fh.datetime,
fh.referer,
fh.url,
fh.external_resource,
fh.page_title,
fh.device_type,
fh.event_type,
fh.insert_dtm,
fv.visitid,
fv.isnewuser,
fv.starturl,
fv.endurl,
fv.pageviews,
fv.visitduration,
fv.regioncountry,
fv.regioncity
from full_hits fh
join full_visits_ids fv
on fv.watchid = fh.watchid
where fh.insert_dtm > coalesce((select max(insert_dtm) 
						from gleb_d.ym_mart), '1999-01-01')
						
