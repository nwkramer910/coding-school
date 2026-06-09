# OOP in Python
import csv
from pathlib import Path
import datetime

cred_csv = Path(r"C:\Users\Nate\Documents\user_credentials.csv")

class Employee:
    
    num_of_emps = 0
    
    email_domain = '@understandingwar.org'
    raise_amount = 1.04
    
    def __init__(self, first, last, pay) -> None:
        self.first = first
        self.last = last
        self.pay = pay
        self.email = first[0].lower() + last.lower() + self.email_domain
        
        Employee.num_of_emps += 1
        
    def fullname(self) -> str:
        return '{} {}'.format(self.first, self.last)
    
    def apply_raise(self) -> int:
        self.pay = int(self.pay * self.raise_amount)
        
    @classmethod
    def set_raise_amt(cls, amount) -> int:
        cls.raise_amt = amount
        
    @classmethod
    def from_csv_row(cls, row) -> 'Employee':
        first = row['first']
        last = row['last']
        pay = 50000
        return cls(first, last, pay)

    def __repr__(self):
        return "Employee('{}', '{}', {})".format(self.first, self.last, self.pay)
    
    def __str__(self):
        return '{} - {}'.format(self.fullname(), self.email)
    
class Researcher(Employee):
    pass

class Admin(Employee):
    pass

with open(cred_csv, mode='r', newline='', encoding='utf-8-sig') as file:
    reader = csv.DictReader(file)
    rows = list(reader)    
    admin_list = [Admin.from_csv_row(row) for row in rows if row['role'] == 'superuser_administrator' or row['role'] == 'administrator']
    researcher_list = [Researcher.from_csv_row(row) for row in rows if row['role'] == 'researcher']
    
for e in researcher_list:
    # print(e.fullname() + ' || ' + e.email)
    print(e)
    
# print(len(researcher_list))
# print(len(admin_list))

# print(Admin.num_of_emps)
# print(Researcher.num_of_emps)
# print(Employee.num_of_emps)