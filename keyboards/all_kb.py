from aiogram.types import KeyboardButton, ReplyKeyboardMarkup, KeyboardButtonPollType, InlineKeyboardMarkup, \
    InlineKeyboardButton
from aiogram.utils.keyboard import InlineKeyboardBuilder

from create_bot import admins


def accept_kb()  -> InlineKeyboardMarkup:
     kb_list = [
         [InlineKeyboardButton(text='OK ✅', callback_data='ok')
             , InlineKeyboardButton(text='Заново ⚠', callback_data='retype')
             , InlineKeyboardButton(text='Отмена ❌', callback_data='abort')]
     ]
     keyboard = InlineKeyboardMarkup (
         inline_keyboard=kb_list
     )
     return keyboard

def account_kb() -> InlineKeyboardMarkup:
    kb_list = [
        [InlineKeyboardButton(text='Сменить отображаемое имя', callback_data='user_rename')]
        #, [InlineKeyboardButton(text='Сменить цвет', callback_data='abort')]
    ]
    keyboard = InlineKeyboardMarkup(
        inline_keyboard=kb_list
    )
    return keyboard

def vacation_kb(vacations: list) -> InlineKeyboardMarkup:
    builder = InlineKeyboardBuilder()
    for row in vacations:
        builder.row(
            InlineKeyboardButton(
                text=f"✏ {row['date_begin'].strftime('%d.%m.%Y')} - {row['date_end'].strftime('%d.%m.%Y')}",
                callback_data=f"vedit_{row['vacation_gid']}"
            )
            , InlineKeyboardButton(
                text='◻' if row['vac_value'] == 'enable' else '◼',
                callback_data=f"swap_{row['vacation_gid']}"
            )
            , InlineKeyboardButton(
                text='🗑❌',
                callback_data=f"del_{row['vacation_gid']}"
            )
        )
    builder.row(
        InlineKeyboardButton(
                text='Добавить новый',
                callback_data='vacation_add'
            )
    )

    return builder.as_markup()