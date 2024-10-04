import asyncio

import asyncpg


class DB:

    def __init__(self, config: str):
        self.config = config
        self._pool = None

    async def get_pool(self):
        return self._pool

    async def create_pool(self):
        if not self._pool:
            self._pool = await asyncpg.create_pool(dsn=self.config)

    async def select(self):
        async with self._pool.acquire() as conn:
            print(await conn.fetch('''SELECT * FROM zmtd_year where year_gid = 2024'''))


async def select(pool):
    async with pool.acquire() as conn:
        print(await conn.fetch('''SELECT 2 * 7'''))


db = DB('postgresql://rmaster:rmaster@localhost:5432/locdb')


async def main():
    await db.create_pool()
    await db.select()

    pool = await db.get_pool()

    await select(pool)

if __name__ == "__main__":
    asyncio.run(main())