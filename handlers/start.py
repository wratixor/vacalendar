from aiogram import Router, F
from aiogram.filters import CommandStart, Command, CommandObject
from aiogram.types import Message, ReplyKeyboardRemove
from keyboards.all_kb import main_kb, mini_kb, private_kb
from middlewares.DataBaseMiddleware import DatabaseMiddleware

start_router = Router()
start_router.message.middleware(DatabaseMiddleware())

@start_router.message(CommandStart())
async def cmd_start(message: Message, command: CommandObject):
    command_args: str = command.args
    if command_args:
        await message.answer(f'Привет! {command_args}')
    else:
        await message.answer('Привет!')

@start_router.message(Command('who_am_i'))
async def who_am_i(message: Message):
    text = ''
    user = message.from_user
    if user.username: text += f"YOU: @{user.username} "
    if user.last_name: text += f"YOUR NAME: {user.full_name} "
    else: text += f"YOUR NAME: {user.first_name} "
    text += f"YOUR ID: {user.id}"
    await message.reply(text)

@start_router.message(Command('menu'))
async def menu(message: Message):
    if message.chat.type == 'private':
        kb=private_kb(message.from_user.id)
    else:
        kb=main_kb(message.from_user.id)
    await message.answer('Даём меню...', reply_markup=kb)

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