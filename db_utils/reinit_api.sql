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

