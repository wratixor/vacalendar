import asyncio
import logging

from create_bot import bot, dp, admins
from handlers.admin_menu import admin_router
from handlers.inline_menu import inline_router
from handlers.start import start_router
from aiogram.types import BotCommand, BotCommandScopeAllPrivateChats


logger = logging.getLogger(__name__)

async def set_all_comads():
    commands = [BotCommand(command='/start', description='Инициализация'),
                BotCommand(command='/help', description='Помощь'),
                BotCommand(command='/join', description='Вступить в группу'),
                BotCommand(command='/leave', description='Покинуть группу'),
                BotCommand(command='/all', description='Все отпуска группы'),
                BotCommand(command='/upcoming', description='Ближайшие отпуска группы'),
                BotCommand(command='/cross', description='Пересечение отпусков группы'),
                BotCommand(command='/kick', description='Исключить из группы'),
                BotCommand(command='/readmin', description='Назначить/удалить админа'),
                BotCommand(command='/status', description='Статус участников')
                ]
    await bot.set_my_commands(commands)

async def set_private_comads():
    commands = [BotCommand(command='/start', description='Инициализация'),
                BotCommand(command='/help', description='Помощь'),
                BotCommand(command='/add', description='Добавить отпуск'),
                BotCommand(command='/account', description='Анкета'),
                BotCommand(command='/vacation', description='Мои отпуска'),
                BotCommand(command='/all', description='Все отпуска моих групп'),
                BotCommand(command='/upcoming', description='Ближайшие отпуска моих групп'),
                BotCommand(command='/cross', description='Пересечения моих отпусков'),
                BotCommand(command='/status', description='Статус')
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
