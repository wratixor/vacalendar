import logging
from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
#from aiogram.fsm.storage.redis import RedisStorage
from aiogram.fsm.storage.memory import MemoryStorage
from decouple import config
from apscheduler.schedulers.asyncio import AsyncIOScheduler

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
storage: MemoryStorage = MemoryStorage()
#storage: RedisStorage = RedisStorage.from_url(config('REDIS_LINK_0'))

scheduler: AsyncIOScheduler = AsyncIOScheduler(timezone='Europe/Moscow')
admins: set = set(int(admin_id) for admin_id in config('ADMINS').split(','))
pg_link: str = config('PG_LINK')

bot: Bot = Bot(token=config('BOT_TOKEN'), default=DefaultBotProperties(parse_mode=ParseMode.HTML))
bot_url: str = config('BOT_URL')
dp: Dispatcher = Dispatcher(storage=storage)

