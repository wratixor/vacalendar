import re
from datetime import date

isodata = re.compile(r'^\d\d\d\d-\d\d-\d\d$')
isodata2 = re.compile(r'^\d\d\d\d-\d\d-\d\d \d\d\d\d-\d\d-\d\d$')
isodata_day = re.compile(r'^\d\d\d\d-\d\d-\d\d \d+$')
rudata = re.compile(r'^\d\d\.\d\d\.\d\d\d\d$')
rudata2 = re.compile(r'^\d\d\.\d\d\.\d\d\d\d \d\d\.\d\d\.\d\d\d\d$')
rudata_day = re.compile(r'^\d\d\.\d\d\.\d\d\d\d \d+$')
years = re.compile(r'^\d\d\d\d$')

def covert_date(datastring: str) -> date:
    result: date
    if isodata.match(datastring):
        result = date.fromisoformat(datastring)
    elif rudata.match(datastring):
        dd = datastring.split('.')
        result = date(int(dd[2]), int(dd[1]), int(dd[0]))
    else:
        result = date.today()
    return result

def get_year(datastring: str) -> int:
    result: int = 0
    if years.match(datastring):
        result = int(datastring)
    if result > 2100 or result < 2000:
        result = date.today().year
    return result
