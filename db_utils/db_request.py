import asyncio
import logging

import asyncpg

logger = logging.getLogger(__name__)

async def join(pool: asyncpg.pool.Pool, user_id: int, group_id: int) -> str:
    result: str
    val: str
    async with pool.acquire() as conn:
        try:
            val = await conn.fetchval("select * from api.join($1::bigint, $2::bigint)", user_id, group_id)
            result = f"join({user_id}, {group_id}) returned: {val}"
        except Exception as e:
            result = f"join({user_id}, {group_id}) exception: {e}"
            logger.error(result)
    return result