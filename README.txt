KADZI STORE — исправление перехода после пополнения

Это ZIP с точечным патчем для index.html.

Внутри функции sendTopup(method) замените старую строку:

if(tg?.openTelegramLink)tg.openTelegramLink("https://t.me/+YGOwB71cb3AzYTNi");else location.href="https://t.me/+YGOwB71cb3AzYTNi";

на:

if(tg?.openTelegramLink)tg.openTelegramLink("https://t.me/ByKadzi");else location.href="https://t.me/ByKadzi";

Меняется только переход после создания заявки на пополнение.
Ссылку на группу с инструкциями для выдачи товаров не меняйте.

Важно: это ZIP-патч, а не полный архив сайта — запись в GitHub была отклонена с ошибкой 403, поэтому актуальный полный архив репозитория получить не удалось.
