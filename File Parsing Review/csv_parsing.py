import csv
from pathlib import Path

CSV_PATH = Path(r"C:\Users\Nate\OneDrive - Institute of the Study of War\ISW Files\Database\user_credentials_SECURE.csv")

html_output = ''
names = []

with open(CSV_PATH, 'r') as cf:
    csv_reader = csv.DictReader(cf)
    field_names = csv_reader.fieldnames
    
#     for line in csv_reader:
#         names.append(f"{line["last"]}, {line["first"]}")
        
# for name in names:
#     print(f"{name} \n")

    # for key in csv_reader:
    #     field_names.append(key)
        
print(field_names)