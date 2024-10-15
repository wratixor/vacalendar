import datetime
import logging
import asyncpg
from asyncpg import Record

logger = logging.getLogger(__name__)

async def s_name_join(pool: asyncpg.pool.Pool, user_id: int, group_id: int, username: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_join($1::bigint, $2::bigint, $3::text)"
                                         , user_id, group_id, username)
        except Exception as e:
            result = f"Exception s_name_join({user_id}, {group_id}, {username}): {e}"
            logger.error(result)
    return result

async def s_name_leave(pool: asyncpg.pool.Pool, user_id: int, group_id: int, username: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_leave($1::bigint, $2::bigint, $3::text)"
                                         , user_id, group_id, username)
        except Exception as e:
            result = f"Exception s_name_leave({user_id}, {group_id}, {username}): {e}"
            logger.error(result)
    return result

async def s_name_kick(pool: asyncpg.pool.Pool, user_id: int, group_id: int, username: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_kick($1::bigint, $2::bigint, $3::text)"
                                         , user_id, group_id, username)
        except Exception as e:
            result = f"Exception s_name_kick({user_id}, {group_id}, {username}): {e}"
            logger.error(result)
    return result

async def s_aou_user(pool: asyncpg.pool.Pool, user_id: int, first_name: str, last_name: str, username: str
                   , updpar: str = '', updval: str = '') -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_aou_user($1::bigint, $2::text, $3::text, $4::text"
                                         ", $5::text, $6::text)"
                                         , user_id, first_name, last_name, username, updpar, updval)
        except Exception as e:
            result = f"Exception s_aou_user({user_id}, {first_name}, {last_name}, {username}, {updpar}, {updval}): {e}"
            logger.error(result)
    return result

async def s_aou_group(pool: asyncpg.pool.Pool, group_id: int, group_type: str, group_title: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_kick($1::bigint, $2::text, $3::text)"
                                         , group_id, group_type, group_title)
        except Exception as e:
            result = f"Exception s_aou_group({group_id}, {group_type}, {group_title}): {e}"
            logger.error(result)
    return result

async def s_aou_admin(pool: asyncpg.pool.Pool, user_id: int, group_id: int, username: str, operation: str='swap') -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_kick($1::bigint, $2::bigint, $3::text, $4::text)"
                                         , user_id, group_id, username, operation)
        except Exception as e:
            result = f"Exception s_aou_admin({user_id}, {group_id}, {username}, {operation}): {e}"
            logger.error(result)
    return result

async def s_add_vacation(pool: asyncpg.pool.Pool, user_id: int
                       , date_begin: datetime.date=None, date_end: datetime.date=None, day_count: int=None) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_add_vacation($1::bigint, $2::date, $3::date, $4::integer);"
                                         , user_id, date_begin, date_end, day_count)
        except Exception as e:
            result = f"Exception s_add_vacation({user_id}, {date_begin}, {date_end}, {day_count}): {e}"
            logger.error(result)
    return result

async def s_sod_vacation(pool: asyncpg.pool.Pool, user_id: int, vacation_gid: int, operation: str='swap') -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_sod_vacation($1::bigint, $2::bigint, $3::text)"
                                         , user_id, vacation_gid, operation)
        except Exception as e:
            result = f"Exception s_sod_vacation({user_id}, {vacation_gid}, {operation}): {e}"
            logger.error(result)
    return result

async def s_upd_vacation(pool: asyncpg.pool.Pool, user_id: int, vacation_gid: int
                       , date_begin: datetime.date=None, date_end: datetime.date=None, day_count: int=None) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_upd_vacation($1::bigint, $2::bigint, $3::date, $4::date, $5::integer)"
                                         , user_id, vacation_gid, date_begin, date_end, day_count)
        except Exception as e:
            result = f"Exception s_upd_vacation({user_id}, {vacation_gid}, {date_begin}, {date_end}, {day_count}) exception: {e}"
            logger.error(result)
    return result

async def r_status(pool: asyncpg.pool.Pool, user_id: int=None, group_id: int=None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from api.r_status($1::bigint, $2::bigint)"
                                         , user_id, group_id)
        except Exception as e:
            result[0] = Record(exeption = f"Exception r_status({user_id}, {group_id}): {e}")
            logger.error(result[0])
    return result

async def r_myaccount(pool: asyncpg.pool.Pool, user_id: int) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from api.r_myaccount($1::bigint)"
                                         , user_id)
        except Exception as e:
            result[0] = Record(exeption = f"Exception r_myaccount({user_id}): {e}")
            logger.error(result[0])
    return result

async def r_check_period(pool: asyncpg.pool.Pool, date_begin: datetime.date=None, date_end: datetime.date=None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from api.r_check_period($1::date, $2::date)"
                                         , date_begin, date_end)
        except Exception as e:
            result[0] = Record(exeption = f"Exception r_check_period({date_begin}, {date_end}): {e}")
            logger.error(result[0])
    return result

async def r_myvacation(pool: asyncpg.pool.Pool, user_id: int, n_year: int=None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from api.r_myvacation($1::bigint, $2::integer)"
                                         , user_id, n_year)
        except Exception as e:
            result[0] = Record(exeption = f"Exception r_myvacation({user_id}, {n_year}): {e}")
            logger.error(result[0])
    return result

async def r_cross(pool: asyncpg.pool.Pool, group_id: int=None, user_id: int=None, n_year: int=None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from api.r_cross($1::bigint, $2::bigint, $3::integer)"
                                         , group_id, user_id, n_year)
        except Exception as e:
            result[0] = Record(exeption = f"Exception r_cross({group_id}, {user_id}, {n_year}): {e}")
            logger.error(result[0])
    return result

async def r_all(pool: asyncpg.pool.Pool, group_id: int=None, user_id: int=None, n_year: int=None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from api.r_all($1::bigint, $2::bigint, $3::integer)"
                                         , group_id, user_id, n_year)
        except Exception as e:
            result[0] = Record(exeption = f"Exception r_all({group_id}, {user_id}, {n_year}): {e}")
            logger.error(result[0])
    return result

async def r_calendar(pool: asyncpg.pool.Pool, group_id: int=None, user_id: int=None, n_year: int=None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from api.r_calendar($1::bigint, $2::bigint, $3::integer)"
                                         , group_id, user_id, n_year)
        except Exception as e:
            result[0] = Record(exeption = f"Exception r_calendar({group_id}, {user_id}, {n_year}): {e}")
            logger.error(result[0])
    return result

async def r_upcoming(pool: asyncpg.pool.Pool, group_id: int=None, user_id: int=None, date_begin: datetime.date=None) -> list[Record]:
    result: list[Record]
    async with pool.acquire() as conn:
        try:
            result = await conn.fetch("select * from api.r_upcoming($1::bigint, $2::bigint, $3::date)"
                                         , group_id, user_id, date_begin)
        except Exception as e:
            result[0] = Record(exeption = f"Exception r_upcoming({group_id}, {user_id}, {date_begin}): {e}")
            logger.error(result[0])
    return result