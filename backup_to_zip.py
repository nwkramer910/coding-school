import zipfile, os
from pathlib import Path

def backup_to_zip(folder):
    
    folder = Path(folder)
    
    number = 1
    while True:
        zipfile_name = folder.parent / (folder.parts[-1] + '_' + str(number) + '.zip')
        
        if not zipfile_name.exists():
            break
        number = number + 1
        
    print(f'Creating {zipfile_name}...')
    backup_zip = zipfile.ZipFile(zipfile_name, 'w')
                    
    for folder_name, subfolders, filenames in os.walk(folder):
        folder_name = Path(folder_name)
        print(f'Adding files in folder {folder_name}...')
        
        for filename in filenames:
            print(f'Adding file {filename}...')
            backup_zip.write(folder_name / filename)
            
    backup_zip.close()
    print(f'Files compressed to {zipfile_name}.')
        
backup_to_zip(r'G:\My Drive\-- Projects --\Greek Archaeological Data\ADs\AD.16.1960\Lakonia\Classical')