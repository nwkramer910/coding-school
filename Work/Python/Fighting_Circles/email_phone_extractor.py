import pyperclip
import re

text = pyperclip.paste() # pyperclip

email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b' # email regex
email_matches = re.finditer(email_pattern, text)


emails = []
phone_numbers = []

for match in email_matches:
    emails.append(match.group())
    
phone_pattern = r'(\+\d{1,2}\s*)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b'  # phone number regex
phone_matches = re.finditer(phone_pattern, text)

for match in phone_matches:
    phone_numbers.append(match.group())

print('List of valid emails: ')
print(', '.join(emails))


print('\nList of valid phone numbers: ') 
print(', '.join(phone_numbers))
