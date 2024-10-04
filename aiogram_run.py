import asyncio
import logging

from create_bot import bot, dp, scheduler, admins
from db_utils import db_class
from handlers.admin_menu import admin_router
from handlers.inline_menu import inline_router
from handlers.start import start_router
# from work_time.time_func import send_time_msg
from aiogram.types import BotCommand, BotCommandScopeAllPrivateChats

from utils import simple_https_server

logger = logging.getLogger(__name__)

async def set_all_comads():
    commands = [BotCommand(command='/start', description='Запуск'),
                BotCommand(command='/menu', description='Меню'),
                BotCommand(command='/inline_menu', description='Мини меню')
                ]
    await bot.set_my_commands(commands)

async def set_private_comads():
    commands = [BotCommand(command='/start', description='Запуск'),
                BotCommand(command='/who_am_i', description='Узнать о себе'),
                BotCommand(command='/menu', description='Меню'),
                BotCommand(command='/inline_menu', description='Мини меню')
                ]
    await bot.set_my_commands(commands, BotCommandScopeAllPrivateChats())

async def start_bot():
    logger.warning('Bot running')
    bn = await bot.get_my_name()
    for admin_id in admins:
        try:
            await bot.send_message(admin_id, f'{bn.name} запущен! 🥳')
        except Exception as e:
            logger.error(f'start_bot(): {e}')

async def stop_bot():
    logger.warning('Bot stopping')
    bn = await bot.get_my_name()
    for admin_id in admins:
        try:
            await bot.send_message(admin_id, f'{bn.name} остановлен. За что? 😔')
        except Exception as e:
            logger.error(f'stop_bot(): {e}')

async def main():
    # scheduler.add_job(send_time_msg, 'interval', seconds=10)
    # scheduler.start()

    dp.include_router(start_router)
    dp.include_router(inline_router)
    dp.include_router(admin_router)

    dp.startup.register(set_all_comads)
    dp.startup.register(set_private_comads)

    dp.startup.register(start_bot)
    dp.shutdown.register(stop_bot)


    try:
        await bot.delete_webhook(drop_pending_updates=True)
        await dp.start_polling(bot, allowed_updates=dp.resolve_used_update_types())
    except Exception as e:
        logger.error(f'main(): {e}')
    finally:
        await bot.session.close()
        await exit(0)

if __name__ == "__main__":
    asyncio.run(main())
