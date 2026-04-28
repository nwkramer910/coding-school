import os
import shutil
from pathlib import Path
from datetime import datetime
from itertools import islice
import zipfile

p = Path(r'C:\Users\Nate\Documents\Shapefiles\ISW\Ukraine\Assessed_Russian_Infiltration_Areas_in_Ukraine')

# shutil.copytree(p, output_p, dirs_exist_ok=True)

# months = {
#     'JAN': '01',
#     'FEB': '02',
#     'MAR': '03',
#     'APR': '04',
#     'MAY': '05',
#     'JUN': '06',
#     'JUL': '07',
#     'AUG': '08',
#     'SEP': '09',
#     'OCT': '10',
#     'NOV': '11',
#     'DEC': '12'
# }

folder_paths = {
    1 : 'Assessed_Russian_Infiltration_Areas_in_Ukraine',
    2 : 'Russian_Advances_Shapefile',
    3 : 'Russian_CoT_in_Ukraine_Shapefiles',
    4 : 'Claimed_Ukrainian_Counteroffensives',
    5 : 'Russian_Claimed_CoT'
}

new_output_dir = {
    1 : 'Assessed_Russian_Infiltration_Areas_in_Ukraine',
    2 : 'Assessed_Russian_Advances_in_Ukraine',
    3 : 'Assessed_Russian_Controlled_Territory_in_Ukraine',
    4 : 'Claimed_Ukrainian_Counteroffensives',
    5 : 'Claimed_Russian_CoT'
}

shapefile_names = {
    1 : 'AssessedInfiltrationAreasinUkraine',
    2 : 'AssessedRussianAdvancesinUkraine',
    3 : 'UkraineControlMap',
    4 : 'ClaimedUkrainianCounteroffensives',
    5 : 'ClaimedRussianTerritoryinUkraine'
}

print('Select which shapefiles you wish to parse today: Infils (1), Advances (2), or CoT (3): ')
shapefile = int(input('> '))
print(f'user typed: {repr(shapefile)}')
formatted_name = shapefile_names.get(shapefile, "Not in the defined range.")
print(f'You have selected {formatted_name}.')

output_p = p.parent / new_output_dir
print(f'output_p = {output_p}, {type(output_p)}')
output_p.mkdir(parents=True, exist_ok=True)


ddmonyyyy = re.compile(r'\d{1,2}(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[a-z]*\d{4}', re.I) # UACoTMap
monddyyyy = re.compile(r'(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[a-z]*\d{6}', re.I) # MONDDYYYY
mondd = re.compile(r'(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[a-z]*\d{2}', re.I)  # MONDD 

# TODO: Create date structure parsing w/ new date objects

def try_ddmonyyyy():
    
def try_monddyyyy():
    
def try_mondd():
    
# TODO: Create no-date parsing

def no_date():




# for zfile in output_p.rglob('*.zip'):
#     print(f'found: {zfile}')
#     #AssessedInfiltrationAreasinUkraineMONDDYYYY
#     shutil.copy(zfile, output_p)
    
#     # Conditionals for parsing the shapefile name
#     if shapefile == 3:
        
    
#     len(zfile.stem) < 

#     #date_part.title()
#     date_part = zfile.stem[-9:]
#     date_obj = datetime.strptime(date_part, '%b%d%Y')

#     old_date_part = zfile.stem[-5:]    
#     old_date_obj = datetime.strptime(old_date_part, '%b%d')
#     print(f'    date_part: {repr(old_date_part)}')
    
#     new_date_str = date_obj.strftime('%Y%m%d')
#     print(f'    new date: {repr(new_date_str)}')
    
#     new_filename = f'{formatted_name}_{new_date_str}.zip'
#     os.rename(zfile, zfile.parent / new_filename)
#     print(f'Renamed {date_part} file to {new_date_str}')

    