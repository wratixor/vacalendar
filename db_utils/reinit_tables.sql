drop table if exists rmaster.zmtd_year cascade;
CREATE TABLE rmaster.zmtd_year (
	year_gid integer NOT NULL,
	prev_year_gid integer NOT NULL,
	next_year_gid integer NOT NULL,
	code integer NOT NULL,
	year_name varchar(32) not NULL,
	year_start_date date not NULL,
	year_end_date date not NULL,
	CONSTRAINT "zmtd_year$pk" PRIMARY KEY (year_gid)
);

insert into rmaster.zmtd_year (year_gid, prev_year_gid, next_year_gid, code, year_name, year_start_date, year_end_date) (
select gs as year_gid
     , gs - 1 as prev_year_gid
     , gs + 1 as next_year_gid
     , gs * 10000 as code
     , gs::text as year_name
     , make_date(gs, 1, 1)
     , make_date(gs, 12, 31)
  from generate_series(2000, 2100, 1) as gs
);

-- select * from zmtd_year;

drop SEQUENCE if exists rmaster.zmtd_entity_sq cascade;
CREATE SEQUENCE rmaster.zmtd_entity_sq
INCREMENT 1
START 100
MINVALUE 100
MAXVALUE 2147483647
CACHE 1;

drop table if exists rmaster.zmtd_entity cascade;
create table rmaster.zmtd_entity (
	entity_gid integer NOT NULL DEFAULT nextval('zmtd_entity_sq'::regclass),
	table_name varchar(64) not NULL,
	field_name varchar(64) null,
	description varchar(128) null,
	CONSTRAINT "zmtd_entity$pk" PRIMARY KEY (entity_gid)
);

insert into rmaster.zmtd_entity (table_name, field_name, description) values
('zmtd_entity', null, 'self'),
('zmtd_year', null, 'календарь года'),
('zmtd_month', null, 'календарь месяца'),
('zmtd_month', 'month_name_gid', 'название месяца'),
('zmtd_date', null, 'календарь дни'),
('zmtd_date', 'day_name_gid', 'день недели'),
('zmtd_date', 'day_off_flg', 'будни/выходные'),
('zmtd_date', 'holiday_flg', 'праздничный/обычный');

-- select * from zmtd_entity;

drop SEQUENCE if exists rmaster.zmtd_flag_sq cascade;
CREATE SEQUENCE rmaster.zmtd_flag_sq
INCREMENT 1
START 500
MINVALUE 500
MAXVALUE 2147483647
CACHE 1;

drop table if exists rmaster.zmtd_flag cascade;
create table rmaster.zmtd_flag (
	flag_gid integer NOT NULL DEFAULT nextval('zmtd_flag_sq'::regclass),
	code integer not NULL,
	value varchar(32) not NULL,
	entity_gid integer references zmtd_entity(entity_gid),
	description varchar(128) NOT NULL,
	CONSTRAINT "zmtd_flag$pk" PRIMARY KEY (flag_gid)
);


insert into rmaster.zmtd_flag (flag_gid, code, value, entity_gid, description) values (0, 0, 'err', 100, 'неверное значение');
insert into rmaster.zmtd_flag (flag_gid, code, value, entity_gid, description) values (10, 10, 'enable', 100, 'переключатель да');
insert into rmaster.zmtd_flag (flag_gid, code, value, entity_gid, description) values (12, 12, 'disable', 100, 'переключатель нет');
insert into rmaster.zmtd_flag (code, value, entity_gid, description) values
(0, 'раб', 106, 'рабочий день'),
(1, 'вых', 106, 'выходной день'),
(0, '-', 107, 'обычный день'),
(1, 'прздн', 107, 'праздничный день'),
(2, 'сокр', 107, 'предпраздничный день (сокращённый)'),
(1, 'Пн', 105, 'понедельник'),
(2, 'Вт', 105, 'вторник'),
(3, 'Ср', 105, 'среда'),
(4, 'Чт', 105, 'четверг'),
(5, 'Пт', 105, 'пятница'),
(6, 'Сб', 105, 'суббота'),
(7, 'Вс', 105, 'воскресенье'),
(1, 'Янв', 103, 'январь'),
(2, 'Фев', 103, 'февраль'),
(3, 'Мар', 103, 'март'),
(4, 'Апр', 103, 'апрель'),
(5, 'Май', 103, 'май'),
(6, 'Июн', 103, 'июнь'),
(7, 'Июл', 103, 'июль'),
(8, 'Авг', 103, 'август'),
(9, 'Сен', 103, 'сентябрь'),
(10, 'Окт', 103, 'октябрь'),
(11, 'Ноя', 103, 'ноябрь'),
(12, 'Дек', 103, 'декабрь');

-- select * from zmtd_flag;

drop table if exists rmaster.zmtd_month cascade;
CREATE TABLE rmaster.zmtd_month (
	month_gid integer NOT NULL,
	prev_month_gid integer NOT NULL,
	next_month_gid integer NOT NULL,
	code integer NOT NULL,
	month_num_in_year int2 NOT NULL,
	month_name_gid integer references zmtd_flag(flag_gid),
	month_start_date date not NULL,
	month_end_date date not NULL,
	quarter_num_in_year int2 not NULL,
	year_gid integer references zmtd_year(year_gid),
	year_start_date date not NULL,
	year_end_date date not NULL,
	CONSTRAINT "zmtd_month$pk" PRIMARY KEY (month_gid)
);

insert into rmaster.zmtd_month (month_gid, prev_month_gid, next_month_gid, code, month_num_in_year, month_name_gid
                              , month_start_date, month_end_date, quarter_num_in_year, year_gid, year_start_date, year_end_date) (
select to_char(gs, 'YYYYMM')::integer as month_gid
     , to_char(gs - interval '1 month', 'YYYYMM')::integer as prev_month_gid
     , to_char(gs + interval '1 month', 'YYYYMM')::integer as next_month_gid
     , to_char(gs, 'YYYYMM')::integer * 100 as code
     , extract(month from gs)::int2 as month_num_in_year
     , zm.flag_gid as month_name_gid
     , gs::date as month_start_date
     , (gs + interval '1 month -1 day')::date as month_end_date
     , extract(quarter from gs)::int2 as quarter_num_in_year
     , y.year_gid as year_gid
     , y.year_start_date as year_start_date
     , y. year_end_date as year_end_date
  from generate_series('2000-01-01', '2100-12-31', interval '1 month') as gs
  join zmtd_year as y on gs between y.year_start_date and y.year_end_date
  join zmtd_flag as zm on extract(month from gs) = zm.code and zm.entity_gid = 103
);

/*
select zm.value, m.*
from zmtd_month as m
join zmtd_flag as zm on zm.flag_gid = m.month_name_gid;
*/

drop table if exists rmaster.zmtd_date cascade;
CREATE TABLE rmaster.zmtd_date (
    date_gid date NOT NULL,
    prev_date_gid date not null,
    next_date_gid date not null,
    code integer NOT NULL,
    day_num_in_month int2 NOT NULL,
    day_num_in_week int2 NOT NULL,
    day_name_gid integer references zmtd_flag(flag_gid),
    day_off_flg integer references zmtd_flag(flag_gid),
    holiday_flg integer references zmtd_flag(flag_gid),
    week_num_in_year int2 NOT NULL,
	month_gid integer references zmtd_month(month_gid),
	month_num_in_year int2 NOT NULL,
	month_start_date date not NULL,
	month_end_date date not NULL,
	quarter_num_in_year int2 not NULL,
    iso_year integer NOT NULL,
	year_gid integer references zmtd_year(year_gid),
	year_start_date date not NULL,
	year_end_date date not NULL,
	CONSTRAINT "zmtd_date$pk" PRIMARY KEY (date_gid)
);


insert into rmaster.zmtd_date (date_gid, prev_date_gid, next_date_gid, code, day_num_in_month, day_num_in_week, day_name_gid
                              , day_off_flg, holiday_flg, week_num_in_year, month_gid, month_num_in_year, month_start_date
                              , month_end_date, quarter_num_in_year, iso_year, year_gid, year_start_date, year_end_date) (
select gs::date as date_gid
     , (gs - interval '1 day')::date as prev_date_gid
     , (gs + interval '1 day')::date as next_date_gid
     , to_char(gs, 'YYYYMMdd')::integer as code
     , extract(day from gs)::int2 as day_num_in_month
     , extract(isodow from gs)::int2 as day_num_in_week
     , zdn.flag_gid as day_name_gid
     , case when extract(isodow from gs) in (6, 7) then 501 else 500 end as day_off_flg
     , 502 as holiday_flg
     , extract(week from gs)::int2 as week_num_in_year
     , m.month_gid as month_gid
     , m.month_num_in_year as month_num_in_year
     , m.month_start_date as month_start_date
     , m.month_end_date as month_end_date
     , m.quarter_num_in_year as quarter_num_in_year
     , extract(isoyear from gs)::integer as iso_year
     , y.year_gid as year_gid
     , y.year_start_date as year_start_date
     , y.year_end_date as year_end_date
  from generate_series('2000-01-01', '2100-12-31', interval '1 day') as gs
  join zmtd_year as y on gs between y.year_start_date and y.year_end_date
  join zmtd_month as m on gs between m.month_start_date and m.month_end_date
  join zmtd_flag as zdn on extract(isodow from gs) = zdn.code and zdn.entity_gid = 105
);

/*
select zm.value, dw.value, df.value, dh.value, d.date_gid, d.day_num_in_month, m.month_num_in_year, y.year_name
from zmtd_date as d
join zmtd_month as m on d.date_gid between m.month_start_date and m.month_end_date
join zmtd_year as y on d.date_gid between y.year_start_date and y.year_end_date
join zmtd_flag as zm on zm.flag_gid = m.month_name_gid
join zmtd_flag as dw on dw.flag_gid = d.day_name_gid
join zmtd_flag as df on df.flag_gid = d.day_off_flg
join zmtd_flag as dh on dh.flag_gid = d.holiday_flg
where m.year_gid = 2024
;
*/

-- datafiks 2024 start
update ZMTD_DATE set holiday_flg = 502 where year_gid = 2024;
-- нерабочие праздничные дни (праздники согласно ТК ст.112) 503 - праздник, 501 - выходной
update ZMTD_DATE set holiday_flg = 503, DAY_OFF_FLG = 501
where DATE_GID in (
 '2024-01-01','2024-01-02','2024-01-03','2024-01-04','2024-01-05','2024-01-06','2024-01-07','2024-01-08'
,'2024-02-23'
,'2024-03-08'
,'2024-05-01','2024-05-09'
,'2024-06-12'
,'2024-11-04'
);
-- перенос выходных дней на рабочие в т.ч. из-за совпадения праздничного дня и выходного 502 - непраздничный, 501 - выходной
update ZMTD_DATE set holiday_flg = 502, DAY_OFF_FLG = 501 where DATE_GID in (
 '2024-04-29','2024-04-30','2024-05-10','2024-12-30','2024-12-31'
);
-- перенос рабочих дней на выходные Сб и Вс 502 - непраздничный, 500 - рабочий
update ZMTD_DATE set holiday_flg = 502, DAY_OFF_FLG = 500 where DATE_GID in (
 '2024-04-27','2024-11-02','2024-12-28'
);
-- сокращение рабочего дня на час  504 - сокращённый
update ZMTD_DATE set holiday_flg = 504, DAY_OFF_FLG = 500 where DATE_GID in (
 '2024-02-22','2024-03-07', '2024-05-08', '2024-06-11', '2024-11-02'
);
-- datafiks 2024 end

/* -- datafiks 2025 start
update ZMTD_DATE set holiday_flg = 502 where year_gid = 2025;
-- нерабочие праздничные дни (праздники согласно ТК ст.112) 503 - праздник, 501 - выходной
update ZMTD_DATE set holiday_flg = 503, DAY_OFF_FLG = 501
where DATE_GID in (
 '2024-01-01','2024-01-02','2024-01-03','2024-01-04','2024-01-05','2024-01-06','2024-01-07','2024-01-08'
,'2024-02-23'
,'2024-03-08'
,'2024-05-01','2024-05-09'
,'2024-06-12'
,'2024-11-04'
);
-- перенос выходных дней на рабочие в т.ч. из-за совпадения праздничного дня и выходного 502 - непраздничный, 501 - выходной
update ZMTD_DATE set holiday_flg = 502, DAY_OFF_FLG = 501 where DATE_GID in (
 '2024-04-29','2024-04-30','2024-05-10','2024-12-30','2024-12-31'
);
-- перенос рабочих дней на выходные Сб и Вс 502 - непраздничный, 500 - рабочий
update ZMTD_DATE set holiday_flg = 502, DAY_OFF_FLG = 500 where DATE_GID in (
 '2024-04-27','2024-11-02','2024-12-28'
);
-- сокращение рабочего дня на час  504 - сокращённый
update ZMTD_DATE set holiday_flg = 504, DAY_OFF_FLG = 500 where DATE_GID in (
 '2024-02-22','2024-03-07', '2024-05-08', '2024-06-11', '2024-11-02'
);
*/ -- datafiks 2025 end


drop table if exists rmaster.staff cascade;
CREATE TABLE rmaster.staff (
    user_id bigint NOT NULL,
    first_name varchar(64) not null,
    last_name varchar(64) null,
    username varchar(64) null,
    visible_name varchar(64) not null,
    ref_id bigint null,
    phone varchar(32) null,
    color bytea not null default ('\x'||to_hex((TRUNC(RANDOM() * 200)::int % 200) + 50)||to_hex((TRUNC(RANDOM() * 200)::int % 200) + 50)||to_hex((TRUNC(RANDOM() * 200)::int % 200) + 50))::bytea,
    start_date timestamptz not null default now(),
    update_date timestamptz not null default now(),
	CONSTRAINT "staff$pk" PRIMARY KEY (user_id)
);

drop table if exists rmaster.department cascade;
CREATE TABLE rmaster.department (
    chat_id bigint NOT NULL,
    chat_type varchar(64) not null,
    chat_title varchar(64) null,
    visible_name varchar(64) not null,
    start_date timestamptz not null default now(),
    update_date timestamptz not null default now(),
	CONSTRAINT "department$pk" PRIMARY KEY (chat_id)
);

drop table if exists rmaster.staff_department cascade;
CREATE TABLE rmaster.staff_department (
    user_id bigint references staff(user_id),
    chat_id bigint references department(chat_id),
    enable_flg integer references zmtd_flag(flag_gid) default 10,
    start_date timestamptz not null default now(),
    update_date timestamptz not null default now(),
	CONSTRAINT "staff_department$pk" PRIMARY KEY (chat_id, user_id)
);

drop SEQUENCE if exists rmaster.vacation_sq cascade;
CREATE SEQUENCE rmaster.vacation_sq
INCREMENT 1
START 100
MINVALUE 100
MAXVALUE 9223372036854775807
CACHE 1;

drop table if exists rmaster.vacation cascade;
CREATE TABLE rmaster.vacation (
    vacation_gid bigint NOT NULL DEFAULT nextval('vacation_sq'::regclass),
    user_id bigint references staff(user_id),
    date_begin date not null,
    date_end date not null,
    enable_flg integer references zmtd_flag(flag_gid) default 10,
    public_flg integer references zmtd_flag(flag_gid) default 10,
    start_date timestamptz not null default now(),
    update_date timestamptz not null default now(),
    CONSTRAINT "vacation$pk" PRIMARY KEY (vacation_gid)
);

drop index if exists vacation_date_idx;
CREATE UNIQUE INDEX vacation_date_idx
ON vacation USING btree (date_begin, date_end);

drop index if exists vacation_user_idx;
CREATE UNIQUE INDEX vacation_user_idx
ON vacation USING btree (user_id);

