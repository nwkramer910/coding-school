from pathlib import Path
import shutil
import os

"""
This program walks through a file tree, identifies .pdf extensions, and copies those files to a new folder.

Creator: nkramer
Creation Date: 04/16/2026
Editor: 
Last Edited Date: 
"""

# TODO: Define folder path

file_tree = Path(r'C:\Users\Nate\OneDrive - Institute of the Study of War\ISW Files')

# TODO: Walk through folder and ID exts

for filename, subfolder in file_tree:
    
    rglob('*.pdf')

# TODO: Copy to a new folder