import requests
import json
import re
from datetime import datetime, timezone

"""
==============
CONFIG SECTION
==============
"""

lat = '48.53116'
lon = '37.69804'
API_key = 'c95a482bd549086fed07f8d590ad5374'
print(f'Do you want to view historical weather data or today\'s weather data?')
mode = input('Historical (H) or Today\'s (T)? ')

if mode == 'T':
    response = requests.get(f'https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={API_key}')
elif mode == 'H':
    print('What date do you wish to get historical data for?')
    print('In (YYYY, M, D, H, m) format.')
    date_str=input('> ')
    response = requests.get(f'https://history.openweathermap.org/data/2.5/history/city?lat={lat}&lon={lon}&type=hour&start={start}&appid={API_key}')
    
response_data = json.loads(response.text)
print(response_data)

response_data['main']['temp']
temp_c = round(response_data['main']['temp']-273.14, 1)
temp_f = round(response_data['main']['temp'] * (9/5) - 459.67, 1)

print(f'{temp_c}90\u00b0C')
print(f'{temp_f}90\u00b0F')