<H1>VaCalendar</H1>
<h2>VaCalendar - a simple bot for planning vacations.</h2>
<h2>Site: </h2>
<h2>TG: https://t.me/vacalendar_bot</h2>

<h3>Requirements:</h3>
 - aiogram<br>
 - python-decouple<br>
 - redis<br>
 - asyncpg<br>

<h3>Install:</h3>
- <code>git clone https://github.com/wratixor/vacalendar</code><br>
- <code>python3 -m venv .venv</code><br>
- <code>source .venv/bin/activate</code><br>
- <code>pip install -r requirements.txt</code><br>
- Edit template.env and rename to .env<br>
- Create postgres db and schemas "api" and "rmaster"<br>
- Run <code>db_utils/reinit_tables.sql</code> into PostgreSQL CLI<br>
- Run <code>db_utils/datafixes.sql</code> into PostgreSQL CLI<br>
- Run <code>db_utils/reinit_api.sql</code> into PostgreSQL CLI<br>

