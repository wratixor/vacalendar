from typing import Callable, Dict, Any, Awaitable

from aiogram import BaseMiddleware
from aiogram.types import Message

class QParamMiddleware(BaseMiddleware):
    def __init__(self):
        self.group_set: set = {'group', 'supergroup', 'channel'}

    async def __call__(
            self,
            handler: Callable[[Message, Dict[str, Any]], Awaitable[Any]],
            event: Message,
            data: Dict[str, Any]
    ) -> Any:
        tmp_uname: str = event.from_user.username
        if tmp_uname is None:
            tmp_uname = f'@{event.from_user.id}'
        else:
            tmp_uname = f'@{tmp_uname}'
        data['quname']: str = tmp_uname
        data['isgroup']: bool = event.chat.type in self.group_set
        data['isadmin']: bool = False
        if data['isgroup']:
            data['isadmin']: bool = (await event.chat.get_member(event.from_user.id)) in (await event.chat.get_administrators())
        return await handler(event, data)

