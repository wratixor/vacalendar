import logging

import asyncpg
from aiogram import Router, F
from aiogram.filters import CommandStart, Command, CommandObject
from aiogram.types import Message, ReplyKeyboardRemove
from asyncpg import Record

from create_bot import bot_url
from keyboards.all_kb import main_kb, mini_kb, private_kb
from middlewares.db_middleware import DatabaseMiddleware
from middlewares.qparam_middleware import QParamMiddleware
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
                             f'\nили откройте бот по ссылке {bot_url}?start={message.chat.id}'
                             f'\n')
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

@start_router.message(Command('status'))
async def status(message: Message, isgroup: bool):
    answer: str = (f'Доброго времени суток!'
                   f'\n<b>Всегда доступны команды:</b>'
                   f'\n/start - Инициализация бота в группе | в приватном чате'
                   f'\n/help - Справка по командам группы | приватного чата'
                   f'\n/status - Статус участников | групп пользователя'
                   f'\n/all - Все отпуска участников группы | всех групп пользователя'
                   f'\n/upcoming - Ближайшие отпуска группы | всех групп пользователя'
                   f'\n/cross - Пересечения отпусков группы | отпусков пользователя во всех группах'
                   f'\n<code>В параметрах команд отображенния отпусков можно указать год'
                   f', если требуется информация за год отличный от текущего.'
                   f'\n Например: /all 2023</code>')
    if isgroup:
        answer += (f'\n\n<b>В группе доступны команды:</b>'
                   f'\n/join - Присоединиться к группе'
                   f'\n<code>Администратор 👑 группы может присоединить к группе ранее вышедшего ◼ участника'
                   f'\nнабрав команду /join @username</code>'
                   f'\n/leave - Покинуть группу'
                   f'\n<code>Права администратора, при наличии, будут отозваны.'
                   f'\nОтпуска пользователя перестанут отображаться для группы'
                   f'\nАдминистратор 👑 группы может исключить из группы присоединённого ◻ участника'
                   f'\nнабрав команду /leave @username</code>'
                   f'\n/kick - Удалиться из группы'
                   f'\n<code>Права администратора, при наличии, будут отозваны.'
                   f'\nПользователь будет полностью удалён из группы'
                   f'\nАдминистратор 👑 группы может удалить из группы присоединённого ◻ участника'
                   f'\nнабрав команду /kick @username</code>'
                   f'\n/readmin - Переключение прав администратора'
                   f'\n<code>Присоединившиеся ◻ администраторы чата всегда являются администраторами 👑 группы.'
                   f'\nАдминистратор 👑 группы может выдать/отозвать права администратора другому участнику группы'
                   f'\nнабрав команду: /readmin @username - для переключения да/нет'
                   f'\n/readmin @username add - для выдачи прав'
                   f'\n/readmin @username del - для отзыва прав</code>')
    else:
        answer += (f'\n\n<b>В приватном чате доступны команды:</b>'
                   f'\n/account - Информация о пользователе'
                   f'\n<code>Выводит информацию об аккаунте'
                   f', а так же позваляет изменить цвет и отображаемое имя пользователя</code>'
                   f'\n/vacation - Все отпуска пользователя'
                   f'\n<code>Выводит информацию обо всех отпусках пользователя '
                   f', а так же позваляет редактировать, переключать видимость и удалять их</code>'
                   f'\n/add - Добавить новый отпуск'
                   f'\n<code>Поддерживаемые форматы команды:'
                   f'\n/add - поэтапный ввод информации'
                   f'\n/add %дата_с% %дата_по% или /add %дата_с% %кол-во_дней% - сокращнный ввод'
                   f'\nдата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</code>')

    answer += (f'\n\n<i>Присоединение к группе доступно в чате группы'
               f', добавление отпусков доступно в приватном чате с ботом.</i>')
    await message.answer(f'{answer}')

@start_router.message(Command('join'))
async def join(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool, isadmin: bool):
    res: str
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isadmin:
        await r.s_aou_admin(db, message.from_user.id, message.chat.id, quname,'add')
    if isgroup:
        await r.s_aou_group(db, message.chat.id, message.chat.type, message.chat.title)
        username: str = command.args
        if username:
            res = await r.s_name_join(db, message.from_user.id, message.chat.id, username)
        else:
            res = await r.s_name_join(db, message.from_user.id, message.chat.id, quname)
        await message.answer(f'{res}')
    else:
        await message.answer('Команда доступна только в группе!')

@start_router.message(Command('leave'))
async def leave(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool, isadmin: bool):
    res: str
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isadmin:
        await r.s_aou_admin(db, message.from_user.id, message.chat.id, quname,'add')
    if isgroup:
        await r.s_aou_group(db, message.chat.id, message.chat.type, message.chat.title)
        username: str = command.args
        if username:
            res = await r.s_name_leave(db, message.from_user.id, message.chat.id, username)
        else:
            res = await r.s_name_leave(db, message.from_user.id, message.chat.id, quname)
        await message.answer(f'{res}')
    else:
        await message.answer('Команда доступна только в группе!')

@start_router.message(Command('kick'))
async def kick(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool, isadmin: bool):
    res: str
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isadmin:
        await r.s_aou_admin(db, message.from_user.id, message.chat.id, quname, 'add')
    if isgroup:
        await r.s_aou_group(db, message.chat.id, message.chat.type, message.chat.title)
        username: str = command.args
        if username:
            res = await r.s_name_kick(db, message.from_user.id, message.chat.id, username)
        else:
            res = await r.s_name_kick(db, message.from_user.id, message.chat.id, quname)
        await message.answer(f'{res}')
    else:
        await message.answer('Команда доступна только в группе!')

@start_router.message(Command('readmin'))
async def readmin(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool, isadmin: bool):
    res: str
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isgroup:
        args: list[str] = command.args.split(' ')
        if args.__len__() == 0:
            args.append(quname)
        if args.__len__() == 1:
            args.append('swap')
        if isadmin and args[0] == quname:
            args[1] = 'add'
        await r.s_aou_group(db, message.chat.id, message.chat.type, message.chat.title)
        res = await r.s_aou_admin(db, message.from_user.id, message.chat.id, args[0], args[1])
        await message.answer(f'{res}')
    else:
        await message.answer('Команда доступна только в группе!')

@start_router.message(Command('status'))
async def status(message: Message, db: asyncpg.pool.Pool, isgroup: bool):
    res: list[Record]
    answer: str = f'<code>Отпуск? В группе? Админ?: Имя - Отпусков в году</code>\n'
    if isgroup:
        res = await r.r_status(db, None, message.chat.id)
        for row in res:
            answer += (f'{'🌴' if row['now_vacation_count'] > 0 else '💼'}'
                       f'|{'◻' if row['user_join'] == 'enable' else '◼'}'
                       f'|{'👑' if row['user_admin'] == 'enable' else '🎓'}'
                       f': {row['visible_name']} - {row['year_vacation_count']}\n')
    else:
        res = await r.r_status(db, message.from_user.id, None)
        for row in res:
            answer += (f'{'🌴' if row['now_vacation_count'] > 0 else '💼'}'
                       f'|{'◻' if row['user_join'] == 'enable' else '◼'}'
                       f'|{'👑' if row['user_admin'] == 'enable' else '🎓'}'
                       f': {row['chat_name']} - {row['year_vacation_count']}\n')
    await message.answer(f'{answer}')


@start_router.message(Command('inline_menu'))
async def inline_menu(message: Message):
    await message.answer('Выбери действие:',
                         reply_markup=mini_kb())

@start_router.message(F.text.in_({'Кнопка 1', 'Кнопка 2', 'Кнопка 3', 'Кнопка 4'}))
async def remove_kb(message: Message):
    msg = await message.answer('Удаляю...', reply_markup=ReplyKeyboardRemove())
    await msg.delete()
