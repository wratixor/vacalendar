import logging
from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
#from aiogram.fsm.storage.redis import RedisStorage
from aiogram.fsm.storage.memory import MemoryStorage
from decouple import config
from apscheduler.schedulers.asyncio import AsyncIOScheduler

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
storage = MemoryStorage()
#storage = RedisStorage.from_url(config('REDIS_LINK_0'))

scheduler = AsyncIOScheduler(timezone='Europe/Moscow')
admins = set(int(admin_id) for admin_id in config('ADMINS').split(','))
pg_link = config('PG_LINK')

bot = Bot(token=config('BOT_TOKEN'), default=DefaultBotProperties(parse_mode=ParseMode.HTML))
dp = Dispatcher(storage=storage)

