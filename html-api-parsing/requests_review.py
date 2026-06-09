import requests
import pydoc
from pathlib import Path

payload = {
    'username': 'madlad',
    'password': 'testing'
}
r = requests.post('https://httpbin.org/post', data=payload)
r_dict = r.json()
print(r_dict)

OUTPUT_DIR = Path(r'C:\Users\Nate\Documents\Scripts\coding-school\html-api-parsing')

# html_output = OUTPUT_DIR / "china_purges.html"
# video_output = OUTPUT_DIR / "video.mp4"
# with open(video_output, 'wb') as f: 
#     f.write(r.content)

# print(r.content)