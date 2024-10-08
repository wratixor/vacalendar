import asyncio
import logging

from aiohttp import web
import ssl



logger = logging.getLogger(__name__)

async def handle(request):
    project = request.match_info.get('project', "all")
    s_host = 'https://localhost'
    text = f'Project: {project}:'
    match project.split():
        case ["vacalendar"]:
            text += '\n VaCalendar - a simple bot for planning vacations.'
            text += '\n https://t.me/vacalendar_bot'
        case ["all"]:
            text += f'\n {s_host}/vacalendar'
        case _:
            text += '\n Not found this project'

    text += f'\n\n All project: {s_host}/all'
    text += '\n\n Donations: https://yoomoney.ru/to/4100118849397169'
    return web.Response(text=text)


async def main():
    app = web.Application()
    app.add_routes([web.get('/', handle),
                    web.get('/{project}', handle)])

    ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ssl_context.load_cert_chain('selfsigned.crt', 'selfsigned.key')
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, 'localhost', 443, ssl_context=ssl_context)
    await site.start()
    try:
        while True:
            await asyncio.sleep(3600)
    except Exception as e:
        logger.error(f'main(): {e}')
    finally:
        await exit(0)

if __name__ == '__main__':
    host = ''
    asyncio.run(main())


