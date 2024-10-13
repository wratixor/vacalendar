import logging
import asyncpg

logger = logging.getLogger(__name__)

async def join(pool: asyncpg.pool.Pool, user_id: int, group_id: int, username: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_join($1::bigint, $2::bigint, $3::text)"
                                         , user_id, group_id, username)
        except Exception as e:
            result = f"s_name_join({user_id}, {group_id}, {username}) exception: {e}"
            logger.error(result)
    return result

async def leave(pool: asyncpg.pool.Pool, user_id: int, group_id: int, username: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_leave($1::bigint, $2::bigint, $3::text)"
                                         , user_id, group_id, username)
        except Exception as e:
            result = f"s_name_leave({user_id}, {group_id}, {username}) exception: {e}"
            logger.error(result)
    return result

async def kick(pool: asyncpg.pool.Pool, user_id: int, group_id: int, username: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_kick($1::bigint, $2::bigint, $3::text)"
                                         , user_id, group_id, username)
        except Exception as e:
            result = f"s_name_kick({user_id}, {group_id}, {username}) exception: {e}"
            logger.error(result)
    return result

async def aou_user(pool: asyncpg.pool.Pool, user_id: int, first_name: str, last_name: str, username: str
                   , updpar: str = '', updval: str = '') -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_aou_user($1::bigint, $2::text, $3::text, $4::text"
                                         ", $5::text, $6::text)"
                                         , user_id, first_name, last_name, username, updpar, updval)
        except Exception as e:
            result = f"s_aou_user({user_id}, {first_name}, {last_name}, {username}, {updpar}, {updval}) exception: {e}"
            logger.error(result)
    return result

async def aou_group(pool: asyncpg.pool.Pool, group_id: int, group_type: str, group_title: str) -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_kick($1::bigint, $2::text, $3::text)"
                                         , group_id, group_type, group_title)
        except Exception as e:
            result = f"s_aou_group({group_id}, {group_type}, {group_title}) exception: {e}"
            logger.error(result)
    return result

async def aou_admin(pool: asyncpg.pool.Pool, user_id: int, group_id: int, username: str, operation: str='swap') -> str:
    result: str
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchval("select * from api.s_name_kick($1::bigint, $2::bigint, $3::text, $4::text)"
                                         , user_id, group_id, username, operation)
        except Exception as e:
            result = f"s_aou_admin({user_id}, {group_id}, {username}, {operation}) exception: {e}"
            logger.error(result)
    return result

