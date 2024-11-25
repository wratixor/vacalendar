import logging
from datetime import date

import asyncpg
from aiogram import Router
from aiogram.filters import Command, CommandObject
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import StatesGroup, State
from aiogram.types import Message, InlineKeyboardMarkup
from asyncpg import Record

from keyboards.all_kb import vacation_kb, account_kb, accept_kb
from middlewares.db_middleware import DatabaseMiddleware
from middlewares.qparam_middleware import QParamMiddleware
import db_utils.db_request as r
import utils_date as d


user_router = Router()
user_router.message.middleware(DatabaseMiddleware())
user_router.message.middleware(QParamMiddleware())
logger = logging.getLogger(__name__)

class Form(StatesGroup):
    datestart = State()
    dateend = State()
    check = State()


@user_router.message(Command('account'))
async def account(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    answer: str = f'<b>О Вас:</b>\n'
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isgroup:
        await message.answer('Команда доступна только в приватном чате!')
    else:
        res: list[Record] = await r.r_myaccount(db, message.from_user.id)
        row = res[0]
        answer += (f'<b>Имя:</b> {row['first_name']}\n'
                   f'<b>Фамилия:</b> {row['last_name']}\n'
                   f'<b>Логин:</b> {row['username']}\n'
                   f'<b>Отображаемое имя:</b> {row['visible_name']}\n'
                   f'<b>Цвет:</b> {bytes(row['color']).hex()}\n'
                   f'<b>Добавлен:</b> {row['start_date']}\n'
                   f'<b>Обновлено:</b> {row['update_date']}\n'
                   f'<b>Группы:</b> 👑 {row['enable_admin_count']} '
                   f'/ ◻ {row['enable_chat_count']} / {row['chat_count']}')
        await message.answer(answer, reply_markup=account_kb())

@user_router.message(Command('vacation'))
async def vacation(message: Message, command: CommandObject, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    kb: InlineKeyboardMarkup or None = None
    answer: str = f'<b>Ваши отпуска:</b>'
    t_year: int or None
    arg = command.args
    t_year = d.get_year(arg) if arg else None
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isgroup:
        await message.answer('Команда доступна только в приватном чате!')
    else:
        res: list[Record] = await r.r_myvacation(db, message.from_user.id, t_year)
        kb = vacation_kb(res)
        await message.answer(answer, reply_markup=kb)

async def check_period(state: FSMContext, db: asyncpg.pool.Pool) -> str:
    data = await state.get_data()
    date_start: date = data['date_start']
    date_end: date = data['date_end']
    day_count: int = data['day_count']
    res: list[Record] = await r.r_check_period(db, date_start, date_end, day_count)
    row = res[0]
    periodinfo: str = (f'C {row['date_begin'].strftime('%d.%m.%Y')} по {row['date_end'].strftime('%d.%m.%Y')}'
                       f'\nДней: {row['day_count']}'
                       f'\nРабочих: {row['workday_count']}'
                       f'\nПраздничных: {row['holyday_count']}')
    return periodinfo

@user_router.message(Command('add'))
async def add(message: Message, command: CommandObject, state: FSMContext, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    answer: str = 'Добавление отпуска:\n'
    arg = command.args
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isgroup:
        await message.answer('Команда доступна только в приватном чате!')
    else:
        if arg:
            if d.isodata2.match(arg) or d.rudata2.match(arg):
                datestring = arg.split(' ')
                await state.update_data(date_start=d.covert_date(datestring[0]))
                await state.update_data(date_end=d.covert_date(datestring[1]))
                await state.update_data(day_count=None)
                await state.update_data(vacation_gid=0)
                await state.set_state(Form.check)
                answer += check_period(state, db)
                answer += '\n Принять?'
                await message.answer(answer, reply_markup=accept_kb())
            elif d.isodata_day.match(arg) or d.rudata_day.match(arg):
                datestring = arg.split(' ')
                await state.update_data(date_start=d.covert_date(datestring[0]))
                await state.update_data(date_end=None)
                await state.update_data(day_count=int(datestring[1]))
                await state.update_data(vacation_gid=0)
                await state.set_state(Form.check)
                answer += check_period(state, db)
                answer += '\n Принять?'
                await message.answer(answer, reply_markup=accept_kb())
            else:
                await state.set_state(Form.datestart)
                answer += '<b>Параметры не распознаны</b>\n'
                answer += ('Укажите <b>период отпуска</b> как %дата_с% %дата_по% или как %дата_с% %кол-во_дней%\n'
                           'Или <b>дату начала отпуска</b>\n'
                           '<i>Дата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</i>')
                await message.answer(answer)
        else:
            await state.set_state(Form.datestart)
            answer += ('Укажите <b>период отпуска</b> как %дата_с% %дата_по% или как %дата_с% %кол-во_дней%\n'
                       'Или <b>дату начала отпуска</b>\n'
                       '<i>Дата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</i>')
            await message.answer(answer)