import logging
from datetime import date

import asyncpg
from aiogram import Router, F
from aiogram.filters import Command, CommandObject
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import StatesGroup, State
from aiogram.types import Message, InlineKeyboardMarkup, CallbackQuery
from asyncpg import Record

from keyboards.all_kb import vacation_kb, account_kb, accept_kb
from middlewares.db_middleware import DatabaseMiddleware
from middlewares.qparam_middleware import QParamMiddleware, QParamMiddlewareCallback
import db_utils.db_request as r
import handlers.utils_date as d


user_router = Router()
user_router.message.middleware(DatabaseMiddleware())
user_router.callback_query.middleware(DatabaseMiddleware())
user_router.message.middleware(QParamMiddleware())
user_router.callback_query.middleware(QParamMiddlewareCallback())
logger = logging.getLogger(__name__)

class Form(StatesGroup):
    datestart = State()
    dateend = State()
    check = State()
    replace_name = State()
    check_name = State()

@user_router.message(F.text.lower().contains('отмена'))
async def start_date(message: Message, state: FSMContext):
    await state.clear()
    await message.answer('Ввод отменён')

@user_router.message(Command('account'))
async def account(message: Message, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
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
async def vacation(message: Message, command: CommandObject, state: FSMContext, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    kb: InlineKeyboardMarkup
    answer: str = f'<b>Ваши отпуска:</b>'
    t_year: int or None
    arg = command.args
    t_year = d.get_year(arg) if arg else None
    await r.s_aou_user(db, message.from_user.id, message.from_user.first_name, message.from_user.last_name, quname)
    if isgroup:
        await message.answer('Команда доступна только в приватном чате!')
    else:
        await state.update_data(t_year=t_year)
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
    periodinfo: str = (f'C {row['date_begin'].strftime('%d.%m.%Y')} по {row['date_end'].strftime('%d.%m.%Y')}\n'
                       f'Дней: {row['day_count']}\n'
                       f'Рабочих: {row['workday_count']}\n'
                       f'Праздничных: {row['holyday_count']}\n')
    return periodinfo

@user_router.message(Command('add'))
async def add(message: Message, command: CommandObject, state: FSMContext, db: asyncpg.pool.Pool, quname: str, isgroup: bool):
    answer: str = 'Добавление отпуска:\n'
    arg: str = command.args
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
                answer += await check_period(state, db)
                answer += 'Принять?'
                await message.answer(answer, reply_markup=accept_kb())
            elif d.isodata_day.match(arg) or d.rudata_day.match(arg):
                datestring = arg.split(' ')
                await state.update_data(date_start=d.covert_date(datestring[0]))
                await state.update_data(date_end=None)
                await state.update_data(day_count=int(datestring[1]))
                await state.update_data(vacation_gid=0)
                await state.set_state(Form.check)
                answer += await check_period(state, db)
                answer += 'Принять?'
                await message.answer(answer, reply_markup=accept_kb())
            else:
                await state.update_data(vacation_gid=0)
                await state.set_state(Form.datestart)
                answer += '<b>Параметры не распознаны</b>\n'
                answer += ('Укажите <b>период отпуска</b> как %дата_с% %дата_по% или как %дата_с% %кол-во_дней%\n'
                           'Или <b>дату начала отпуска</b>\n'
                           '<i>Дата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</i>\n')
                answer += 'Или введите "отмена":'
                await message.answer(answer)
        else:
            await state.update_data(vacation_gid=0)
            await state.set_state(Form.datestart)
            answer += ('Укажите <b>период отпуска</b> как %дата_с% %дата_по% или как %дата_с% %кол-во_дней%\n'
                       'Или <b>дату начала отпуска</b>\n'
                       '<i>Дата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</i>\n')
            answer += 'Или введите "отмена":'
            await message.answer(answer)

@user_router.message(F.text, Form.datestart)
async def start_date(message: Message, state: FSMContext, db: asyncpg.pool.Pool):
    answer: str = 'Начало отпуска:\n'
    arg: str = message.text
    if d.isodata2.match(arg) or d.rudata2.match(arg):
        datestring = arg.split(' ')
        await state.update_data(date_start=d.covert_date(datestring[0]))
        await state.update_data(date_end=d.covert_date(datestring[1]))
        await state.update_data(day_count=None)
        await state.set_state(Form.check)
        answer += await check_period(state, db)
        answer += 'Принять?'
        await message.answer(answer, reply_markup=accept_kb())
    elif d.isodata_day.match(arg) or d.rudata_day.match(arg):
        datestring = arg.split(' ')
        await state.update_data(date_start=d.covert_date(datestring[0]))
        await state.update_data(date_end=None)
        await state.update_data(day_count=int(datestring[1]))
        await state.set_state(Form.check)
        answer += await check_period(state, db)
        answer += 'Принять?'
        await message.answer(answer, reply_markup=accept_kb())
    elif d.isodata.match(arg) or d.rudata.match(arg):
        await state.update_data(date_start=d.covert_date(arg))
        await state.set_state(Form.dateend)
        answer += (f'С {arg}\n'
                   f'Введите дату окончания отпуска:')
        await message.answer(answer)
    else:
        answer += '<b>Параметры не распознаны</b>\n'
        answer += ('Укажите <b>период отпуска</b> как %дата_с% %дата_по% или как %дата_с% %кол-во_дней%\n'
                   'Или <b>дату начала отпуска</b>\n'
                   '<i>Дата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</i>\n')
        answer += 'Или введите "отмена":'
        await message.answer(answer)

@user_router.message(F.text, Form.dateend)
async def end_date(message: Message, state: FSMContext, db: asyncpg.pool.Pool):
    answer: str = 'Отпуск:\n'
    arg: str = message.text
    if d.isodata.match(arg) or d.rudata.match(arg):
        await state.update_data(date_end=d.covert_date(arg))
        await state.update_data(day_count=None)
        await state.set_state(Form.check)
        answer += await check_period(state, db)
        answer += 'Принять?'
        await message.answer(answer, reply_markup=accept_kb())
    else:
        answer += '<b>Параметры не распознаны</b>\n'
        answer += ('Укажите <b>дату окончания отпуска</b>\n'
                   '<i>Дата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</i>\n')
        answer += 'Или введите "отмена":'
        await message.answer(answer)

@user_router.message(F.text, Form.replace_name)
async def end_date(message: Message, state: FSMContext):
    arg: str = message.text
    answer: str = f'Отображаемое имя: {arg}\n'
    await state.update_data(name=arg)
    await state.set_state(Form.check_name)
    answer += 'Принять?'
    await message.answer(answer, reply_markup=accept_kb())

@user_router.callback_query(F.data == 'ok', Form.check)
async def check_ok(call: CallbackQuery, state: FSMContext, db: asyncpg.pool.Pool):
    data = await state.get_data()
    date_start: date = data['date_start']
    date_end: date = data['date_end']
    day_count: int = data['day_count']
    vacation_gid: int = data['vacation_gid']
    answer: str = await r.s_aou_vacation(db, call.from_user.id, date_start, date_end, day_count, vacation_gid)
    data = await state.get_data()
    t_year: int = data['t_year'] if 't_year' in data else None
    kb: InlineKeyboardMarkup
    answer += f'\n<b>Ваши отпуска:</b>'
    res: list[Record] = await r.r_myvacation(db, call.from_user.id, t_year)
    kb = vacation_kb(res)
    await call.message.edit_text(answer, reply_markup=kb)

@user_router.callback_query(F.data == 'retype', Form.check)
async def check_retype(call: CallbackQuery, state: FSMContext):
    answer: str = 'Изменение данных\n'
    answer += ('Укажите <b>период отпуска</b> как %дата_с% %дата_по% или как %дата_с% %кол-во_дней%\n'
               'Или <b>дату начала отпуска</b>\n'
               '<i>Дата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</i>\n')
    answer += 'Или введите "отмена":'
    await state.set_state(Form.datestart)
    await call.message.edit_text(answer)


@user_router.callback_query(F.data == 'abort')
async def check_abort(call: CallbackQuery, state: FSMContext):
    answer: str = 'Отменено'
    await state.clear()
    await call.message.edit_text(answer)


@user_router.callback_query(F.data == 'retype', Form.check_name)
async def check_name(call: CallbackQuery, state: FSMContext):
    answer: str = 'Изменение данных\n'
    answer += 'Укажите новое отображаемое имя\n'
    answer += 'Или введите "отмена":'
    await state.set_state(Form.replace_name)
    await call.message.edit_text(answer)


@user_router.callback_query(F.data == 'ok', Form.check_name)
async def check_ok_name(call: CallbackQuery, state: FSMContext, db: asyncpg.pool.Pool, quname: str):
    data = await state.get_data()
    name: str = data['name']
    answer: str = await r.s_aou_user(db, call.from_user.id, call.from_user.first_name
                                     , call.from_user.last_name, quname, 'name', name)
    await call.message.edit_text(answer)
    await state.clear()

@user_router.callback_query(F.data == 'user_rename')
async def check_name(call: CallbackQuery, state: FSMContext):
    answer: str = 'Изменение данных\n'
    answer += 'Укажите новое отображаемое имя\n'
    answer += 'Или введите "отмена":'
    await state.set_state(Form.replace_name)
    await call.message.edit_text(answer)

@user_router.callback_query(F.data == 'vacation_add')
async def vacation_add(call: CallbackQuery, state: FSMContext):
    answer: str = 'Добавление отпуска\n'
    await state.update_data(vacation_gid=0)
    answer += ('Укажите <b>период отпуска</b> как %дата_с% %дата_по% или как %дата_с% %кол-во_дней%\n'
               'Или <b>дату начала отпуска</b>\n'
               '<i>Дата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</i>\n')
    answer += 'Или введите "отмена":'
    await state.set_state(Form.datestart)
    await call.message.edit_text(answer)


@user_router.callback_query(F.data.startswith('vedit_'))
async def vac_vedit(call: CallbackQuery, state: FSMContext):
    answer: str = 'Изменение данных\n'
    vacation_gid = int(call.data.replace('vedit_', ''))
    await state.update_data(vacation_gid=vacation_gid)
    answer += ('Укажите <b>период отпуска</b> как %дата_с% %дата_по% или как %дата_с% %кол-во_дней%\n'
               'Или <b>дату начала отпуска</b>\n'
               '<i>Дата может быть указана в формате ДД.ММ.ГГГГ или ГГГГ-ММ-ДД</i>\n')
    answer += 'Или введите "отмена":'
    await state.set_state(Form.datestart)
    await call.message.edit_text(answer)


@user_router.callback_query(F.data.startswith('swap_'))
async def vac_swap(call: CallbackQuery, state: FSMContext, db: asyncpg.pool.Pool):
    vacation_gid = int(call.data.replace('swap_', ''))
    answer: str = await r.s_sod_vacation(db, call.from_user.id, vacation_gid, 'swap')
    data = await state.get_data()
    t_year: int = data['t_year'] if 't_year' in data else None
    kb: InlineKeyboardMarkup
    answer += f'\n<b>Ваши отпуска:</b>'
    res: list[Record] = await r.r_myvacation(db, call.from_user.id, t_year)
    kb = vacation_kb(res)
    await call.message.edit_text(answer, reply_markup=kb)

@user_router.callback_query(F.data.startswith('del_'))
async def vac_del(call: CallbackQuery, state: FSMContext, db: asyncpg.pool.Pool):
    vacation_gid = int(call.data.replace('del_', ''))
    answer: str = await r.s_sod_vacation(db, call.from_user.id, vacation_gid, 'del')
    data = await state.get_data()
    t_year: int = data['t_year']  if 't_year' in data else None
    kb: InlineKeyboardMarkup
    answer += f'\n<b>Ваши отпуска:</b>'
    res: list[Record] = await r.r_myvacation(db, call.from_user.id, t_year)
    kb = vacation_kb(res)
    await call.message.edit_text(answer, reply_markup=kb)