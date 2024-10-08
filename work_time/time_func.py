import logging

from create_bot import bot, admins

logger = logging.getLogger(__name__)


async def send_time_msg():
    logger.info('send_time_msg')
    bn = await bot.get_my_name()
    for admin_id in admins:
        try:
            await bot.send_message(admin_id, f'{bn.name} 💬 Работаю 👨‍💻')
        except Exception as e:
            logger.error(f'send_time_msg(): {e}')

