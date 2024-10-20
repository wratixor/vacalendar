import logging

import asyncpg
from aiogram import Router, F
from aiogram.filters import CommandStart, Command, CommandObject
from aiogram.types import Message, ReplyKeyboardRemove

from create_bot import bot_url
from keyboards.all_kb import main_kb, mini_kb, private_kb
from middlewares.DataBaseMiddleware import DatabaseMiddleware
from middlewares.QParamMiddleware import QParamMiddleware
import db_utils.db_request as r

start_router = Router()
start_router.message.middleware(DatabaseMiddleware())
start_router.message.middleware(QParamMiddleware())
logger = logging.getLogger(__name__)

@start_router.message(CommandStart())
async def cmd_start(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool, isadmin: bool):
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isadmin:
        await r.s_aou_admin(db, message.from_user.id, message.chat.id, quname,'add')
    if isgroup:
        await r.s_aou_group(db, message.chat.id, message.chat.type, message.chat.title)
        await message.answer(f'Доброго времени суток всем в этом чатике!'
                             f'\nПолный список команд с описаниями доступен по команде /help'
                             f'\nДля присоединения к группе введите команду /join'
                             f'\nили откройте бот по ссылке {bot_url}?start={message.chat.id}')
    else:
        command_args: str = command.args
        if command_args:
            res: str = await r.s_name_join(db, message.from_user.id, int(command_args), quname)
            await message.answer(f'Привет, {quname}!'
                                 f'\nПолный список команд с описаниями доступен по команде /help'
                                 f'\nПрисоединение к группе: {res}')
        else:
            await message.answer(f'Привет, {quname}!'
                                 f'\nПолный список команд с описаниями доступен по команде /help'
                                 f'\nДля присоединения к группе добавьте бота в группу'
                                 f', активируйте (/start) и введите команду /join')

@start_router.message(Command('test'))
async def test(message: Message, command: CommandObject, quname: str, isgroup: bool, isadmin: bool):
    command_args: str = command.args
    text: str = (f'test: {command_args}'
                 f'\nquname: {quname}'
                 f'\nisgroup: {isgroup}'
                 f'\nisadmin: {isadmin}')
    await message.reply(text)
    logger.info(command_args)

@start_router.message(Command('join'))
async def join(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool, isadmin: bool):
    res: str
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isadmin:
        await r.s_aou_admin(db, message.from_user.id, message.chat.id, quname,'add')
    if isgroup:
        username: str = command.args
        if username:
            res = await r.s_name_join(db, message.from_user.id, message.chat.id, username)
        else:
            res = await r.s_name_join(db, message.from_user.id, message.chat.id, quname)
        await message.answer(f'{res}')
    else:
        await message.answer('Команда доступна только в группе!')

@start_router.message(Command('inline_menu'))
async def inline_menu(message: Message):
    await message.answer('Выбери действие:',
                         reply_markup=mini_kb())

@start_router.message(F.text.in_({'Кнопка 1', 'Кнопка 2', 'Кнопка 3', 'Кнопка 4'}))
async def remove_kb(message: Message):
    msg = await message.answer('Удаляю...', reply_markup=ReplyKeyboardRemove())
    await msg.delete()

#@start_router.message(F.text == '/start_3')
#async def cmd_start_3(message: Message):
#   await message.answer('Запуск сообщения по команде /start_3 используя магический фильтр F.text!')