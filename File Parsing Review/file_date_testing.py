from itertools import islice
from pathlib import Path
import time
import datetime
import shutil

p = Path(r'C:\Users\Nate\Documents\Shapefiles\ISW\Ukraine\Russian_CoT_in_Ukraine_Shapefiles')
output_p = p.parent / 'test_dir'
print(f'output_p = {output_p}, {type(output_p)}')
output_p.mkdir(parents=True, exist_ok=True)


for file in islice(p.rglob('*).shp'), 20):
    copy_result = Path(shutil.copy(file, output_p))
    copy2_result = Path(shutil.copy2(file, output_p))
    
    print(f'old: {datetime.datetime.fromtimestamp(file.stat().st_mtime)} || copy: {datetime.datetime.fromtimestamp(copy_result.stat().st_mtime)} || copy2: {datetime.datetime.fromtimestamp(copy2_result.stat().st_mtime)}')
    time.sleep(1)
          