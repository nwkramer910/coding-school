import requests
from bs4 import BeautifulSoup

res = requests.get('https://autbor.com/example3.html')
res.raise_for_status()
example_soup = BeautifulSoup(res.text, 'html.parser')
print(type(example_soup))