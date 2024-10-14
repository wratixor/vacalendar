DROP SCHEMA IF EXISTS api cascade;
CREATE SCHEMA api AUTHORIZATION rmaster;


DROP FUNCTION IF EXISTS api.s_aou_user(int8, text, text, text, text, text);
CREATE OR REPLACE FUNCTION api.s_aou_user(i_user_id bigint, i_first_name text, i_last_name text, i_username text, i_upd_par text default null::text, i_upd_val text default null::text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_user boolean := false;
  l_add_user boolean := false;
  l_update_user boolean := false;
  l_check_hash boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_first_name text := coalesce(i_first_name, '');
  l_last_name text := coalesce(i_last_name, '');
  l_username text := coalesce(i_username, '');
  l_visible_name text;
  l_color bytea;
  l_upd_par text := lower(coalesce(i_upd_par, ''));
  l_upd_val text := coalesce(i_upd_val, '');

  l_hash text := l_first_name||l_last_name||l_username;

 BEGIN
  l_check_user := ((select count(1) from rmaster.staff as u where u.user_id = l_user_id) = 1);
  IF not l_check_user THEN
    l_visible_name := case when l_last_name <> '' then l_first_name||' '||l_last_name else l_first_name end;
    insert into rmaster.staff (user_id, first_name, last_name, username, visible_name)
                       values (l_user_id, l_first_name, l_last_name, l_username, l_visible_name);
    l_add_user := true;
  ELSE
    l_check_hash := ((select first_name||last_name||username as hash from rmaster.staff as u where u.user_id = l_user_id) = l_hash);
    IF not l_check_hash THEN
      update rmaster.staff set first_name = l_first_name, last_name = l_last_name, username = l_username, update_date = now() where user_id = l_user_id;
      l_update_user := true;
    END IF;
  END IF;

  IF l_check_user and l_upd_par = 'color' THEN
    l_color := case when l_upd_val <> '' then l_upd_val
                    else ('\x'::text || to_hex(trunc(random() * 200::double precision)::integer % 200 + 50)
                                     || to_hex(trunc(random() * 200::double precision)::integer % 200 + 50)
                                     || to_hex(trunc(random() * 200::double precision)::integer % 200 + 50))
                    end::bytea;
    update rmaster.staff set color = l_color, update_date = now() where user_id = l_user_id;
    l_update_user := true;
  END IF;

  IF l_check_user and l_upd_par = 'name' then
    l_visible_name := case when l_upd_val <> '' then l_upd_val
                           else case when l_last_name <> '' then l_first_name||' '||l_last_name else l_first_name end
                           end::text;
    update rmaster.staff set visible_name = l_visible_name, update_date = now() where user_id = l_user_id;
    l_update_user := true;
  END IF;

  RETURN (
    SELECT
      case when l_update_user then 'Успешно обновлено'
           when l_add_user then 'Пользователь добавлен'
           when l_check_user and l_check_hash then 'Обновление не требуется'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP FUNCTION IF EXISTS api.s_aou_group(int8, text, text);
CREATE OR REPLACE FUNCTION api.s_aou_group(i_chat_id bigint, i_chat_type text, i_chat_title text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_chat boolean := false;
  l_add_chat boolean := false;
  l_update_chat boolean := false;
  l_check_hash boolean := false;

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_chat_type text := coalesce(i_chat_type, '');
  l_chat_title text := coalesce(i_chat_title, '');

  l_hash text := l_chat_type||l_chat_title;

 BEGIN
  l_check_chat := ((select count(1) from rmaster.department as c where c.chat_id = l_chat_id) = 1);
  IF not l_check_chat THEN
    insert into rmaster.department (chat_id, chat_type, chat_title)
                       values (l_chat_id, l_chat_type, l_chat_title);
    l_add_chat := true;
  ELSE
    l_check_hash := ((select chat_type||chat_title as hash from rmaster.department as c where c.chat_id = l_chat_id) = l_hash);
    IF not l_check_hash THEN
      update rmaster.department set chat_type = l_chat_type, chat_title = l_chat_title, update_date = now() where chat_id = l_chat_id;
      l_update_chat := true;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when l_update_chat then 'Успешно обновлено'
           when l_add_chat then 'Группа добавлена'
           when l_check_chat and l_check_hash then 'Обновление не требуется'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP FUNCTION IF EXISTS api.s_aou_admin(int8, int8, text, text);
CREATE OR REPLACE FUNCTION api.s_aou_admin(i_admin_id bigint, i_chat_id bigint, i_username text, i_oper text default null::text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_chat boolean := false;
  l_check_admin boolean := false;
  l_check_user boolean := false;
  l_check_flg int4 := 0;
  l_enabled boolean := false;
  l_disabled boolean := false;


  l_admin_id bigint := coalesce(i_admin_id, 0::bigint);
  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := 0;
  l_username text := coalesce(i_username, '');
  l_oper text := lower(coalesce(i_oper, ''));

 BEGIN
  l_user_id := (select user_id from rmaster.staff as u where u.username = l_username limit 1);
  l_check_chat := ((select count(1) from rmaster.department as c where c.chat_id = l_chat_id) = 1);
  l_check_user := (l_user_id is not null);
  l_check_admin := (l_admin_id = l_user_id) or ((select count(1)
                                                   from rmaster.admin_department as ad
                                                  where ad.chat_id = l_chat_id
                                                    and ad.user_id = l_admin_id
                                                    and enable_flg = 10) = 1);
  l_check_flg := (select ad.enable_flg from rmaster.admin_department as ad where ad.user_id = l_user_id and ad.chat_id = l_chat_id limit 1);

  IF l_check_chat and l_check_user and l_check_admin THEN
    IF l_oper = 'add' THEN
      IF l_check_flg is null THEN
        insert into rmaster.admin_department (user_id, chat_id) values (l_user_id, l_chat_id);
      ELSEIF l_check_flg = 12 THEN
        update rmaster.admin_department set enable_flg = 10, update_date = now() where user_id = l_user_id and chat_id = l_chat_id;
      END IF;
      l_enabled := true;
    END IF;
    IF l_oper = 'del' and l_check_flg = 10 THEN
        update rmaster.admin_department set enable_flg = 12, update_date = now() where user_id = l_user_id and chat_id = l_chat_id;
        l_disabled := true;
    END IF;
    IF l_oper in ('swap', '') THEN
        IF l_check_flg = 12 THEN
          update rmaster.admin_department set enable_flg = 10, update_date = now() where user_id = l_user_id and chat_id = l_chat_id;
          l_enabled := true;
        ELSEIF l_check_flg = 10 THEN
          update rmaster.admin_department set enable_flg = 12, update_date = now() where user_id = l_user_id and chat_id = l_chat_id;
          l_disabled := true;
        ELSEIF l_check_flg is null THEN
          insert into rmaster.admin_department (user_id, chat_id) values (l_user_id, l_chat_id);
          l_enabled := true;
        END IF;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when         l_enabled then l_username||' назначены права администратора'
           when        l_disabled then 'У '||l_username||' отозваны права администратора'
           when not l_check_admin then 'Недостаточно прав'
           when not l_check_chat  then 'Неизвестный чат'
           when not l_check_user  then 'Неизвестный пользователь'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP FUNCTION IF EXISTS api.s_name_join(int8, int8, text);
CREATE OR REPLACE FUNCTION api.s_name_join(i_admin_id bigint, i_chat_id bigint, i_username text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_admin boolean := false;
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;
  l_check_query boolean := false;
  l_check_flg int4 := 0;

  l_user_id bigint;
  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_username text := coalesce(i_username, '');

 BEGIN
  l_user_id := (select user_id from rmaster.staff as u where u.username = l_username limit 1);
  l_check_chat := ((select count(1) from rmaster.department as c where c.chat_id = l_chat_id) = 1);
  l_check_user := (l_user_id is not null);
  l_check_admin := (l_admin_id = l_user_id) or ((select count(1)
                                                   from rmaster.admin_department as ad
                                                  where ad.chat_id = l_chat_id
                                                    and ad.user_id = l_admin_id
                                                    and enable_flg = 10) = 1);
  l_check_flg := (select uc.enable_flg from rmaster.staff_department as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id limit 1);

  IF l_check_user and l_check_chat and l_check_admin THEN
    IF l_check_flg is null THEN
      insert into rmaster.staff_department (user_id, chat_id) values (l_user_id, l_chat_id);
      l_check_query := true;
    ELSEIF l_check_flg = 12 THEN
      update rmaster.staff_department set enable_flg = 10, update_date = now() where user_id = l_user_id and chat_id = l_chat_id;
    END IF;
  END IF;

  RETURN (
    SELECT
      case when     l_check_query then 'Успешно присоединился к группе'
           when  l_check_flg = 10 then 'Уже есть в группе'
           when  l_check_flg = 12 then 'Восстановлен в группу'
           when not l_check_admin then 'Недостаточно прав'
           when not  l_check_user then 'Неизвестный пользователь'
           when not  l_check_chat then 'Неизвестная группа'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP FUNCTION IF EXISTS api.s_name_leave(int8, int8, text);
CREATE OR REPLACE FUNCTION api.s_name_leave(i_admin_id bigint, i_chat_id bigint, i_username text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_admin boolean := false;
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;
  l_check_query boolean := false;
  l_check_flg int4 := 0;

  l_user_id bigint;
  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_username text := coalesce(i_username, '');

  l_del_admin text;

 BEGIN
  l_user_id := (select user_id from rmaster.staff as u where u.username = l_username limit 1);
  l_check_chat := ((select count(1) from rmaster.department as c where c.chat_id = l_chat_id) = 1);
  l_check_user := (l_user_id is not null);
  l_check_admin := (l_admin_id = l_user_id) or ((select count(1)
                                                   from rmaster.admin_department as ad
                                                  where ad.chat_id = l_chat_id
                                                    and ad.user_id = l_admin_id
                                                    and enable_flg = 10) = 1);
  l_check_flg := (select uc.enable_flg from rmaster.staff_department as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id limit 1);

  IF l_check_user and l_check_chat and l_check_admin THEN
    IF l_check_flg = 10 THEN
      update rmaster.staff_department set enable_flg = 12, update_date = now() where user_id = l_user_id and chat_id = l_chat_id;
      l_check_query := true;
    END IF;
  END IF;

  l_del_admin := (select * from api.s_aou_admin(i_admin_id::bigint, i_chat_id::bigint, i_username::text, 'del'::text));

  RETURN (
    SELECT
      case when       l_check_query then 'Успешно покинул группу. Права: '||l_del_admin
           when    l_check_flg = 12 then 'Уже не в группе'
           when l_check_flg is null then 'Отсутствует в группе'
           when not   l_check_admin then 'Недостаточно прав'
           when not    l_check_user then 'Неизвестный пользователь'
           when not    l_check_chat then 'Неизвестная группа'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP FUNCTION IF EXISTS api.s_name_kick(int8, int8, text);
CREATE OR REPLACE FUNCTION api.s_name_kick(i_admin_id bigint, i_chat_id bigint, i_username text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
 DECLARE
  l_check_admin boolean := false;
  l_check_user boolean := false;
  l_check_chat boolean := false;
  l_check_isset boolean := false;
  l_check_query boolean := false;
  l_check_flg int4 := 0;

  l_user_id bigint;
  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_username text := coalesce(i_username, '');

 BEGIN
  l_user_id := (select user_id from rmaster.staff as u where u.username = l_username limit 1);
  l_check_chat := ((select count(1) from rmaster.department as c where c.chat_id = l_chat_id) = 1);
  l_check_user := (l_user_id is not null);
  l_check_admin := (l_admin_id = l_user_id) or ((select count(1)
                                                   from rmaster.admin_department as ad
                                                  where ad.chat_id = l_chat_id
                                                    and ad.user_id = l_admin_id
                                                    and enable_flg = 10) = 1);
  l_check_flg := (select uc.enable_flg from rmaster.staff_department as uc where uc.user_id = l_user_id and uc.chat_id = l_chat_id limit 1);

  IF l_check_user and l_check_chat and l_check_admin THEN
      delete from rmaster.staff_department where user_id = l_user_id and chat_id = l_chat_id;
      delete from rmaster.admin_department where user_id = l_user_id and chat_id = l_chat_id;
      l_check_query := true;
  END IF;

  RETURN (
    SELECT
      case when     l_check_query then 'Исключён из группы, права администратора отозваны, если были.'
           when not l_check_admin then 'Недостаточно прав'
           when not  l_check_user then 'Неизвестный пользователь'
           when not  l_check_chat then 'Неизвестная группа'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
 END
$function$
;


DROP TYPE IF EXISTS api.t_status CASCADE;
CREATE TYPE api.t_status AS (
	chat_name text,
	visible_name text,
	username text,
	user_color bytea,
	user_join text,
	user_admin text,
	year_vacation_count int4,
	now_vacation_count int4);


DROP FUNCTION IF EXISTS api.r_status(int8, int8);
CREATE OR REPLACE FUNCTION api.r_status(i_chat_id bigint default null::bigint, i_user_id bigint default null::bigint)
 RETURNS SETOF api.t_status
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 20
AS $function$
DECLARE

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);

BEGIN
  IF l_chat_id <> 0 or l_user_id <> 0 THEN
    RETURN QUERY
    select c.chat_title as chat_name
    , u.visible_name as visible_name
    , u.username as username
    , u.color as user_color
    , ucf.value as user_join
    , case when adf.value is not null then adf.value else 'disable' end as user_admin
    , count(vy.vacation_gid) as year_vacation_count
    , count(vn.vacation_gid) as now_vacation_count
    from rmaster.staff_department as uc
    join rmaster.zmtd_flag as ucf on uc.enable_flg = ucf.flag_gid
    join rmaster.department as c on uc.chat_id = c.chat_id
    join rmaster.staff as u on uc.user_id = u.user_id
    left join rmaster.admin_department as ad on ad.user_id = uc.user_id and ad.chat_id = uc.chat_id
    left join rmaster.zmtd_flag as adf on ad.enable_flg = adf.flag_gid
    join rmaster.zmtd_year as zy on current_date between zy.year_start_date and zy.year_end_date
    left join rmaster.vacation vy on vy.date_begin <= zy.year_end_date and vy.date_end >= zy.year_start_date
                                 and vy.user_id = uc.user_id and vy.enable_flg = 10
    left join rmaster.vacation vn on current_date between vn.date_begin and vn.date_end
                                 and vn.user_id = uc.user_id and vn.enable_flg = 10
    where (uc.user_id = l_user_id or l_user_id = 0)
      and (uc.chat_id = l_chat_id or l_chat_id = 0)
    group by c.chat_title, u.visible_name, u.color, ucf.value, adf.value
    order by c.chat_title, u.visible_name
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;


DROP TYPE IF EXISTS api.t_all CASCADE;
CREATE TYPE api.t_all AS (
	chat_name text,
	visible_name text,
	username text,
	user_color bytea,
	date_begin date,
	date_end date);


DROP FUNCTION IF EXISTS api.r_all(int8, int8, int4);
CREATE OR REPLACE FUNCTION api.r_all(i_chat_id bigint default null::bigint, i_user_id bigint default null::bigint, i_year int4 default null::int4)
 RETURNS SETOF api.t_all
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 50
AS $function$
DECLARE

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_year int4 := case when coalesce(i_year, 0::int4) >= 2000::int4 then i_year::int4 else EXTRACT(year FROM current_date)::int4 end;

BEGIN
  IF l_chat_id <> 0 or l_user_id <> 0 THEN
    RETURN QUERY
    with all_chat as (
      select uc.chat_id
      from rmaster.staff_department as uc
      where (uc.user_id = l_user_id or l_user_id = 0)
        and (uc.chat_id = l_chat_id or l_chat_id = 0)
        and uc.enable_flg = 10
    )
    select c.chat_title as chat_name
    , u.visible_name as visible_name
    , u.username as username
    , u.color as user_color
    , v.date_begin as date_begin
    , v.date_end as date_end
    from all_chat as a
    join rmaster.staff_department as uc on uc.chat_id = a.chat_id and uc.enable_flg = 10
    join rmaster.staff as u on u.user_id = uc.user_id
    join rmaster.department as c on c.chat_id = uc.chat_id
    join rmaster.zmtd_year as zy on zy.year_gid = l_year
    join rmaster.vacation as v on v.user_id = uc.user_id and v.enable_flg = 10
                              and zy.year_start_date <= v.date_end
                              and zy.year_end_date >= v.date_begin
    order by v.date_begin, u.visible_name
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;


DROP TYPE IF EXISTS api.t_cross CASCADE;
CREATE TYPE api.t_cross AS (
	chat_name text,
	visible_name1 text,
	username1 text,
	user_color1 bytea,
	date_begin1 date,
	date_end1 date,
	visible_name2 text,
	username2 text,
	user_color2 bytea,
	date_begin2 date,
	date_end2 date);


DROP FUNCTION IF EXISTS api.r_cross(int8, int8, int4);
CREATE OR REPLACE FUNCTION api.r_cross(i_chat_id bigint default null::bigint, i_user_id bigint default null::bigint, i_year int4 default null::int4)
 RETURNS SETOF api.t_cross
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 20
AS $function$
DECLARE

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_year int4 := case when coalesce(i_year, 0::int4) >= 2000::int4 then i_year::int4 else EXTRACT(year FROM current_date)::int4 end;

BEGIN
  IF l_chat_id <> 0 or l_user_id <> 0 THEN
    RETURN QUERY
    with all_chat as (
      select uc.chat_id
      from rmaster.staff_department as uc
      where (uc.user_id = l_user_id or l_user_id = 0)
        and (uc.chat_id = l_chat_id or l_chat_id = 0)
        and uc.enable_flg = 10
    )
    select c.chat_title as chat_name
    , u1.visible_name as visible_name1
    , u1.username as username1
    , u1.color as user_color1
    , v1.date_begin as date_begin1
    , v1.date_end as date_end1
    , u2.visible_name as visible_name2
    , u2.username as username2
    , u2.color as user_color2
    , v2.date_begin as date_begin2
    , v2.date_end as date_end2
    from all_chat as a
    join rmaster.staff_department as uc1 on uc1.chat_id = a.chat_id and uc1.enable_flg = 10
    join rmaster.staff_department as uc2 on uc2.chat_id = a.chat_id and uc2.enable_flg = 10
                                        and uc1.user_id <> uc2.user_id
    join rmaster.staff as u1 on u1.user_id = uc1.user_id
    join rmaster.staff as u2 on u2.user_id = uc2.user_id
    join rmaster.department as c on c.chat_id = uc1.chat_id
    join rmaster.zmtd_year as zy on zy.year_gid = l_year
    join rmaster.vacation as v1 on v1.user_id = uc1.user_id and v1.enable_flg = 10
                               and zy.year_start_date <= v1.date_end
                               and zy.year_end_date >= v1.date_begin
    join rmaster.vacation as v2 on v2.user_id = uc2.user_id and v2.enable_flg = 10
                               and v2.date_begin <= v1.date_end
                               and v2.date_end >= v1.date_begin
    order by v1.date_begin, u1.visible_name
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;


DROP TYPE IF EXISTS api.t_upcoming CASCADE;
CREATE TYPE api.t_upcoming AS (
	chat_name text,
	visible_name text,
	username text,
	user_color bytea,
	date_begin date,
	date_end date);


DROP FUNCTION IF EXISTS api.r_upcoming(int8, int8, int4);
CREATE OR REPLACE FUNCTION api.r_upcoming(i_chat_id bigint default null::bigint, i_user_id bigint default null::bigint, i_date date default null::date)
 RETURNS SETOF api.t_upcoming
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 20
AS $function$
DECLARE

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_date_begin date := coalesce(i_date, current_date)::date;
  l_date_end date := (l_date_begin + interval '2 month')::date;

BEGIN
  IF l_chat_id <> 0 or l_user_id <> 0 THEN
    RETURN QUERY
    with all_chat as (
      select uc.chat_id
      from rmaster.staff_department as uc
      where (uc.user_id = l_user_id or l_user_id = 0)
        and (uc.chat_id = l_chat_id or l_chat_id = 0)
        and uc.enable_flg = 10
    )
    select c.chat_title as chat_name
    , u.visible_name as visible_name
    , u.username as username
    , u.color as user_color
    , v.date_begin as date_begin
    , v.date_end as date_end
    from all_chat as a
    join rmaster.staff_department as uc on uc.chat_id = a.chat_id and uc.enable_flg = 10
    join rmaster.staff as u on u.user_id = uc.user_id
    join rmaster.department as c on c.chat_id = uc.chat_id
    join rmaster.vacation as v on v.user_id = uc.user_id and v.enable_flg = 10
                              and l_date_begin <= v.date_end
                              and l_date_end >= v.date_begin
    order by v.date_begin, u.visible_name
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;


DROP TYPE IF EXISTS api.t_calendar CASCADE;
CREATE TYPE api.t_calendar AS (
	date_gid date,
    name_weekday text,
    num_weekday int2,
    name_day_off text,
    name_holiday text,
    name_month text,
    num_day int2,
    num_month int2,
    num_quart int2,
    num_year int4,
    chat_name text,
	visible_name text,
	username text,
	user_color bytea);


DROP FUNCTION IF EXISTS api.r_calendar(int8, int8, int4);
CREATE OR REPLACE FUNCTION api.r_calendar(i_chat_id bigint default null::bigint, i_user_id bigint default null::bigint, i_year int4 default null::int4)
 RETURNS SETOF api.t_calendar
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 600
AS $function$
DECLARE

  l_chat_id bigint := coalesce(i_chat_id, 0::bigint);
  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_year int4 := case when coalesce(i_year, 0::int4) >= 2000::int4 then i_year::int4 else EXTRACT(year FROM current_date)::int4 end;

BEGIN
  IF l_chat_id <> 0 or l_user_id <> 0 THEN
    RETURN QUERY
    with all_chat as (
      select uc.chat_id
      from rmaster.staff_department as uc
      where (uc.user_id = l_user_id or l_user_id = 0)
        and (uc.chat_id = l_chat_id or l_chat_id = 0)
        and uc.enable_flg = 10
    )
    , all_vacation as (
      select c.chat_title as chat_name
      , u.visible_name as visible_name
      , u.username as username
      , u.color as user_color
      , v.date_begin as date_begin
      , v.date_end as date_end
      from all_chat as a
      join rmaster.staff_department as uc on uc.chat_id = a.chat_id and uc.enable_flg = 10
      join rmaster.staff as u on u.user_id = uc.user_id
      join rmaster.department as c on c.chat_id = uc.chat_id
      join rmaster.zmtd_year as zy on zy.year_gid = l_year
      join rmaster.vacation as v on v.user_id = uc.user_id and v.enable_flg = 10
                                and zy.year_start_date <= v.date_end
                                and zy.year_end_date >= v.date_begin
    )
    select zd.date_gid as date_gid
    , dw.value as name_weekday
    , zd.day_num_in_week as num_weekday
    , df.value as name_day_off
    , dh.value as name_holiday
    , zm.description as name_month
    , zd.day_num_in_month as num_day
    , zd.month_num_in_year as num_month
    , zd.quarter_num_in_year as num_quart
    , zd.year_gid as num_year
    , av.chat_name
    , av.visible_name
    , av.username
    , av.user_color
    from rmaster.zmtd_date as zd
    join zmtd_month as m on zd.date_gid between m.month_start_date and m.month_end_date
    join zmtd_flag as zm on zm.flag_gid = m.month_name_gid
    join zmtd_flag as dw on dw.flag_gid = zd.day_name_gid
    join zmtd_flag as df on df.flag_gid = zd.day_off_flg
    join zmtd_flag as dh on dh.flag_gid = zd.holiday_flg
    left join all_vacation as av on zd.date_gid between av.date_begin and av.date_end
    where zd.year_gid = l_year
    order by zd.date_gid, av.visible_name
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;


DROP TYPE IF EXISTS api.t_myvacation CASCADE;
CREATE TYPE api.t_myvacation AS (
	vacation_gid int8,
	date_begin date,
	date_end date,
	vac_value text,
	day_count int4,
	workday_count int4,
	holyday_count int4);


DROP FUNCTION IF EXISTS api.r_myvacation(int8, int4);
CREATE OR REPLACE FUNCTION api.r_myvacation(i_user_id bigint default null::bigint, i_year int4 default null::int4)
 RETURNS SETOF api.t_myvacation
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 10
AS $function$
DECLARE

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_year int4 := case when coalesce(i_year, 0::int4) >= 2000::int4 then i_year::int4 else EXTRACT(year FROM current_date)::int4 end;

BEGIN
  IF l_user_id <> 0 THEN
    RETURN QUERY
      with all_vacation as (
      select v.vacation_gid as vacation_gid
      , v.date_begin as date_begin
      , v.date_end as date_end
      , zfv.value as vac_value
      from rmaster.staff as u
      join rmaster.zmtd_year as zy on zy.year_gid = l_year
      join rmaster.vacation as v on v.user_id = u.user_id
                                and zy.year_start_date <= v.date_end
                                and zy.year_end_date >= v.date_begin
      join rmaster.zmtd_flag as zfv on zfv.flag_gid = v.enable_flg
      where u.user_id = l_user_id
    )
    select av.vacation_gid
    , av.date_begin
    , av.date_end
    , av.vac_value
    , count(date_gid) as day_count
    , count(date_gid) filter (where zd.day_off_flg = 500) as workday_count
    , count(date_gid) filter (where zd.holiday_flg = 503) as holyday_count
    from rmaster.zmtd_date as zd
    join all_vacation as av on zd.date_gid between av.date_begin and av.date_end
    group by av.vacation_gid, av.date_begin, av.date_end, av.vac_value
    order by av.date_begin, av.vac_value, av.vacation_gid
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;


DROP TYPE IF EXISTS api.t_myaccount CASCADE;
CREATE TYPE api.t_myaccount AS (
	user_id int8,
	first_name text,
	last_name text,
	username text,
    visible_name text,
	color bytea,
	start_date date,
	update_date date,
	chat_count int4,
	enable_chat_count int4,
	enable_admin_count int4);


DROP FUNCTION IF EXISTS api.r_myaccount(int8);
CREATE OR REPLACE FUNCTION api.r_myaccount(i_user_id bigint default null::bigint)
 RETURNS SETOF api.t_myaccount
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 1
AS $function$
DECLARE

  l_user_id bigint := coalesce(i_user_id, 0::bigint);

BEGIN
  IF l_user_id <> 0 THEN
    RETURN QUERY
    select u.user_id
    , u.first_name
    , u.last_name
    , u.username
    , u.visible_name
    , u.color
    , u.start_date
    , u.update_date
    , count(uc.chat_id) as chat_count
    , count(uc.chat_id) filter (where uc.enable_flg = 10) as enable_chat_count
    , count(ad.chat_id) filter (where ad.enable_flg = 10) as enable_admin_count
    from rmaster.staff as u
    join rmaster.staff_department as uc on uc.user_id = u.user_id
    join rmaster.department as c on c.chat_id = uc.chat_id
    left join rmaster.admin_department as ad
           on ad.user_id = u.user_id and ad.chat_id = c.chat_id
    where u.user_id = l_user_id
    group by u.user_id, u.first_name, u.last_name, u.username, u.visible_name, u.color, u.start_date, u.update_date
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;


DROP TYPE IF EXISTS api.t_check_period CASCADE;
CREATE TYPE api.t_check_period AS (
	date_begin date,
	date_end date,
	day_count int4,
	workday_count int4,
	holyday_count int4);


DROP FUNCTION IF EXISTS api.r_check_period(date, date, int4);
CREATE OR REPLACE FUNCTION api.r_check_period(i_date_begin date default null::date, i_date_end date default null::date, i_day_count int4 default null::int4)
 RETURNS SETOF api.t_check_period
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER COST 1 ROWS 1
AS $function$
DECLARE

  l_date_begin date := coalesce(i_date_begin, current_date)::date;
  l_date_end date := coalesce(i_date_end, (l_date_begin + make_interval(days => coalesce(i_day_count, 14) - 1))::date);

BEGIN
  IF l_user_id <> 0 THEN
    RETURN QUERY
    select av.date_begin
    , av.date_end
    , count(date_gid) as day_count
    , count(date_gid) filter (where zd.day_off_flg = 500) as workday_count
    , count(date_gid) filter (where zd.holiday_flg = 503) as holyday_count
    from rmaster.zmtd_date as zd
    where zd.date_gid between l_date_begin and l_date_end
    group by av.date_begin, av.date_end
    order by av.date_begin, av.date_end
    FOR READ ONLY;
  END IF;
RETURN;
END
$function$
;


DROP FUNCTION IF EXISTS api.s_add_vacation(int8, date, date, int4);
CREATE OR REPLACE FUNCTION api.s_add_vacation(i_user_id bigint, i_date_begin date default null::date, i_date_end date default null::date, i_day_count int4 default null::int4)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
DECLARE
  l_check_user boolean := false;
  l_check_date boolean := false;
  l_query boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_date_begin date := coalesce(i_date_begin, current_date)::date;
  l_date_end date := coalesce(i_date_end, (l_date_begin + make_interval(days => coalesce(i_day_count, 14) - 1))::date);

BEGIN

  l_check_user := ((select count(1) from rmaster.staff as u where u.user_id = l_user_id) = 1);
  l_check_date := ((select count(1) from rmaster.zmtd_date as d where d.date_gid in (l_date_begin, l_date_end)) = 2);

  IF l_check_user and l_check_date THEN
    insert into rmaster.vacation (user_id, date_begin, date_end) values (l_user_id, l_date_begin, l_date_end);
    l_query := true;
  END IF;

  RETURN (
    SELECT
      case when l_query then 'Успешно добавлен'
           when not l_check_user then 'Неизвестный пользователь'
           when not l_check_date then 'Неподходящие даты'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
END
$function$
;


DROP FUNCTION IF EXISTS api.s_upd_vacation(int8, int8, date, date, int4);
CREATE OR REPLACE FUNCTION api.s_upd_vacation(i_user_id bigint, i_vacation_gid bigint, i_date_begin date default null::date, i_date_end date default null::date, i_day_count int4 default null::int4)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
DECLARE
  l_check_user boolean := false;
  l_check_date boolean := false;
  l_check_vacation boolean := false;
  l_query boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_vacation_gid bigint := coalesce(i_vacation_gid, 0::bigint);
  l_date_begin date := coalesce(i_date_begin, current_date)::date;
  l_date_end date := coalesce(i_date_end, (l_date_begin + make_interval(days => coalesce(i_day_count, 14) - 1))::date);

BEGIN

  l_check_user := ((select count(1) from rmaster.staff as u where u.user_id = l_user_id) = 1);
  l_check_date := ((select count(1) from rmaster.zmtd_date as d where d.date_gid in (l_date_begin, l_date_end)) = 2);
  l_check_vacation := ((select count(1) from rmaster.vacation as v where v.user_id = l_user_id and v.vacation_gid = l_vacation_gid) = 1);

  IF l_check_user and l_check_date and l_check_vacation THEN
    update rmaster.vacation set date_begin = l_date_begin, date_end = l_date_end, update_date = now()
                          where user_id = l_user_id and vacation_gid = l_vacation_gid;
    l_query := true;
  END IF;

  RETURN (
    SELECT
      case when l_query then 'Успешно обновлено'
           when not l_check_user then 'Неизвестный пользователь'
           when not l_check_date then 'Неподходящие даты'
           when not l_check_vacation then 'Недоступный отпуск'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
END
$function$
;



DROP FUNCTION IF EXISTS api.s_sod_vacation(int8, int8, text);
CREATE OR REPLACE FUNCTION api.s_sod_vacation(i_user_id bigint, i_vacation_gid bigint, i_oper text default null::text)
 RETURNS text
 LANGUAGE plpgsql
 VOLATILE SECURITY DEFINER COST 1
AS $function$
DECLARE
  l_check_user boolean := false;
  l_check_date boolean := false;
  l_check_vacation boolean := false;
  l_check_flg int4 := 0;
  l_query boolean := false;

  l_user_id bigint := coalesce(i_user_id, 0::bigint);
  l_vacation_gid bigint := coalesce(i_vacation_gid, 0::bigint);
  l_oper text := lower(coalesce(i_oper, ''));

BEGIN

  l_check_user := ((select count(1) from rmaster.staff as u where u.user_id = l_user_id) = 1);
  l_check_flg := (select v.enable_flg from rmaster.vacation as v where v.user_id = l_user_id and v.vacation_gid = l_vacation_gid limit 1);
  l_check_vacation := (l_check_flg is not null);

  IF l_check_user and l_check_vacation THEN
    IF l_oper = 'del' THEN
      delete from rmaster.vacation where user_id = l_user_id and vacation_gid = l_vacation_gid;
      l_query := null;
    ELSEIF l_oper in ('swap', '') THEN
      IF l_check_flg = 10 THEN
        update rmaster.vacation set enable_flg = 12, update_date = now()
                              where user_id = l_user_id and vacation_gid = l_vacation_gid;
        l_query := true;
      ELSEIF l_check_flg = 12 THEN
        update rmaster.vacation set enable_flg = 10, update_date = now()
                              where user_id = l_user_id and vacation_gid = l_vacation_gid;
        l_query := true;
      END IF;
    END IF;

  END IF;

  RETURN (
    SELECT
      case when l_query then 'Видимость изменена'
           when l_query is null then 'Успешно удалён'
           when not l_check_user then 'Неизвестный пользователь'
           when not l_check_vacation then 'Недоступный отпуск'
           else 'Не выполнено' end::text as status
    FOR READ ONLY
  );
END
$function$
;
