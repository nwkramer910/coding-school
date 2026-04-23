# Coding Knowledge Bank

## Templates

### Name of Method

* parent module: 
* connected objects:
* method arguments: 
* method return value: 
* notes: 

### Name of Function

* parent module: 
* connected objects: 
* function arguments:
* function return value: 
* when to use: 
* notes:

### Term or Concept

**My Definition:**
* [Explain it in your own words, like you're teaching someone]

**Why It Matters:**
* [Why is this important for your work?]

**Example Code:**
```Language
Code Block Example
```

* name of source script (if available): 

**Common Mistakes:**
[Gotchas you encountered or want to avoid]

**Related Concepts:**
*

**Resources:**
* [Link to documentation]
* [Tutorial or article that helped]

### Name of Module

* major functions/methods: 
* main applications: 
* notes: 
* Documentation: <> 

## Functions

### ZipFile()

* parent module: zipfile
* connected objects: ZipFiles
* function arguments: Path, mode (`'w` or `'r'`), compression type (usually `.ZIP_DEFLATED`), compresslevel (0-9)
* function return value: 
* when to use: 
* notes:

### walk()

* parent module: os 
* connected objects:  
* function arguments:
* function return value: 
* when to use: 
* notes:

### iterdir()

* parent module: pathlib 
* connected objects: Paths
* function arguments:
* function return value: list of Path objects in directory
* when to use: 
* notes:

### listdir()

* parent module: os
* connected objects:  
* function arguments: Path
* function return value: list of all files in the directory
* when to use: 
* notes:

### unlink/rmdir(path)

* parent module: os
* connected objects: Paths
* function arguments: target path
* function return value: unlink = deleted single file; rmdir = deleted empty folder
* when to use: 
* notes: completely and irrevocably removes files. 

### rmtree(path)

* parent module: shutil
* connected objects: Paths
* function arguments: target path
* function return value: deleted entire folder tree
* when to use: 
* notes: completely and irrevocably removes files. 

### shutil.move()

* parent module: shutil 
* connected objects: Paths
* function arguments: source and destination paths
* function return value: the source directory gets moved to the destination path
* when to use: 
* notes:

### shutil.copy()

* parent module: shutil 
* connected objects: shutil, Paths
* function arguments: source path, destination path
* function return value: copied file at destination path
* when to use: 
* notes: shutil.copytree() copies not only the source directory, but all files and subdirectories within

### read/write()

* parent module: 
* connected objects: Files 
* function arguments: 
* function return value: reads or writes file objects 
* when to use: 
* notes:

### open()

* parent module: 
* connected objects: Files 
* function arguments: 
* function return value: returns file object 
* when to use: 
* notes: opens a file in "read mode"

### mkdir()

* parent module: pathlib
* connected objects/Classes: Paths
* function arguments: absolute path, *parents* (boolean: True = make new parent dirs)
* function return value: new directory (new parents if *parents*=True)
* when to use: When you need to make a new directory w/ one or more new parent dirs
* notes:

### makedirs()

* parent module: os 
* function arguments: absolute path
* function return value: new directory(ies)
* when to use: When you need to make a new directory w/ one or more new parent dirs
* notes:

### chdir()

* parent module: os 
* function arguments: path string (using '\\')
* function return value: new working directory
* when to use: 
* notes:

### cwd()

* parent module: pathlib 
* connected objects: Paths
* function arguments: 
* function return value: current working directory 
* when to use: 
* notes: os.getcwd() is an older way of getting the CWD

### Path()

* parent module: pathlib
* connected objects: Paths
* function arguments: string
* function return value: Windows/PosixPath string (all /)
* when to use: 
* notes: returns WindowsPath on Windows, PosixPath on Unix; run through str() to get Windows compatible path string

### str(), int(), float()

* function arguments: any value
* function return value: data type corresponding to function name
* when to use: when attempting to change data from one type to another
* notes: can be nested within other functions of this type

### type()

* function arguments: any value or variable
* function return value: the data type of the argument 
* when to use: when attempting to discern data types
* notes:

### round()

* function arguments: numeric values, number of digits (ndigits)
* function return value: rounds up (.6 - .9) or down (.1 - .4) to nearest digit specified by the ndigits argument
* when to use: 
* notes: .5 numbers round to the nearest even integer (i.e. 3.5 to 4 and 2.5 to 2)

### abs()

* function arguments: numeric values
* function return value: absolute value (dist from 0)
* when to use: 
* notes:

### range()

* function arguments: start, stop, step (ints)
* function return value: used in for loops
* when to use: in for loops 
* notes: technically a class; the range is also starting-point inclusive but end-point exclusive [i, j)

### copy() & deepcopy()

* parent module: copy 
* function arguments: variable
* function return value: copy of original value
* when to use: when trying to copy values, not just references
* notes: deepcopy() is for list values with inner list values

### ord()/chr()

* parent module: 
* function arguments: ord('str'), chr(int)
* function return value: Unicode code point for string values, string values for Unicode code point values
* when to use: 
* notes:

### copy()/paste()

* parent module: pyperclip
* function arguments: copy('str')
* function return value: copy() copies the text to the clipboard; paste() pastes the current text copied on the clipboard
* when to use: 
* notes:

## Methods

### extract/extractall()

* parent module: zipfile 
* connected objects: ZipFiles
* method arguments: Path, destination path
* method return value: extracts all or one file(s) to destination path
* notes: destination path is optional

### getinfo()

* parent module: zipfile 
* connected objects: ZipFiles, ZipInfo
* method arguments:  
* method return value: ZipInfo object
* notes: 

### namelist()

* parent module: zipfile
* connected objects: ZipFiles
* method arguments: 
* method return value: list of strings for all files and folders contained within a ZIP file.
* notes: 

### write_text()

* parent module: pathlib 
* connected objects: Paths
* method arguments: text strings
* method return value: writes or overwrites text file 
* notes: 

### read_text()

* parent module: pathlib
* connected objects: Paths
* method arguments: 
* method return value: text contents of path file
* notes: 

### exists()/is_file()/is_dir()

* parent module: pathlib 
* connected objects: Path
* method arguments: 
* method return value: 
* notes: 

### glob()

* parent module: pathlib
* connected objects: Path
* function arguments: '*' or '?'
* function return value: generator object
* when to use: 
* notes: pass Path.glob() to list()

### stat()

* parent module: pathlib 
* connected objects: Paths
* method arguments: stat_result object w/ file size and timestamp data
* method return value: 
* notes: 

### is_absolute()

* parent module: pathlib
* connected objects: Paths
* method arguments: 
* method return value: boolean
* notes: True if path is absolute, False if path is relative

### index()

* connected objects: lists 
* method arguments: value, Index range
* method return value: Index value
* notes: 

### append()

* connected objects: lists 
* method arguments: value
* method return value: new list number & index
* notes: 

### insert()

* connected objects: lists 
* method arguments: index number, value
* method return value: new list value at point of index number
* notes: does not replace value at current index number, simply pushes it right

### sort()

* connected objects: list (one data type)
* method arguments: none sorts alphanumerically; reverse=True sorts reverse alphanumerically; key to apply certain operators to the values before sorting (like str.lower)
* method return value: 
* notes: alternative to reverse=True is the reverse() method

### keys(), values(), items()

* parent module: 
* connected objects: dicts
* method arguments: 
* method return value: list-like values of a dicts keyts, values, and items
* notes: 

### get()

* parent module: 
* connected objects: dicts
* method arguments: key of desired value, fallback value if key DNE
* method return value: value from key argument, or 0
* notes: 

### setdefault()

* parent module: 
* connected objects: dicts
* method arguments: key, value (as str)
* method return value: new item pair in dict
* notes: only adds new items, does not overwrite values in item pairs

### starts/endswith()

* parent module: 
* connected objects: text
* method arguments: str
* method return value: boolean
* notes: 

### join()

* parent module: 
* connected objects: str list
* method arguments: str
* method return value: list values separated by argument
* notes: similar to concat

### split()

* parent module: 
* connected objects: str
* method arguments: default=whitespace, str
* method return value: str values separated by argument into list
* notes: similar to text-to-column

### strip()

* parent module: 
* connected objects: str
* method arguments: default=whitespace, str
* method return value: argument value removed from input string
* notes: has lstrip and rstrip versions

## Modules

### zipfile

* major functions/methods: ZipFile()
* main applications: archiving files
* notes: 
* Documentation: <https://docs.python.org/3/library/zipfile.html#module-zipfile>

### send2trash

* major functions/methods: send2trash()
* main applications: sending files to the recycle bin
* notes: 
* Documentation: <https://pypi.org/project/Send2Trash/>

### shutil

* major functions/methods: copy()
* main applications: shell utility, allowing for easy file management
* notes: 
* Documentation: <https://docs.python.org/3/library/shutil.html#module-shutil>

## Terms and Concepts

### Iterate Through Filetree

**My Definition:**
* Using pathlib, if I want to iterate through all files and subfolders in a directory, I'd use this method

**Why It Matters:**
* [Why is this important for your work?]

**Example Code:**

```Python
# Good for getting names of files and folders within a directory
for p in Path().iterdir():

# Good for finding specific files within a directory and subdirectory (glob is just current directory, rglob is recursive)

for p in Path().rglob("*text*"): 

```

* name of source script (if available): 


**Common Mistakes:**
[Gotchas you encountered or want to avoid]

**Related Concepts:**
*

**Resources:**
* [Link to documentation]
* [Tutorial or article that helped]

### Zipping Files

**My Definition:**
Compressing files in Python uses the `zipfile` module to write ZipFile objects.

**Example from My Work:**

```Python

    # Define the list of associated shapefile components (no extra .shp added)
    shapefile_components = [
        f"{output_shapefile}.shp",  # The main shapefile
        f"{output_shapefile}.shx",  # Shape index file
        f"{output_shapefile}.dbf",  # Attribute data file
        f"{output_shapefile}.prj",  # Projection file
        f"{output_shapefile}.sbn",  # Spatial index file
        f"{output_shapefile}.sbx",  # Spatial index file (alternate)
        f"{output_shapefile}.cpg",  # Character encoding file
        f"{output_shapefile}.shp.xml"  # Metadata XML
    ]

    # Check if all components exist before proceeding
    missing_files = [file for file in shapefile_components if not os.path.exists(file)]
    if missing_files:
        print(f"Error: Missing files for {output_name}: {', '.join(missing_files)}")
    else:
        # Create a zip file for the shapefile
        zip_filename = os.path.join(daily_output_folder, f"{output_name}.zip")

        # Create and write to the zip file
        with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for file in shapefile_components:
                zipf.write(file, os.path.basename(file))  # Add each file to the zip

```

**Common Mistakes:**


**Related Concepts:**
- reading and writing files

**Resources:**
- [\[Link to documentation\]](https://docs.python.org/3/library/zipfile.html#module-zipfile)
- [\[Tutorial or article that helped\]](https://automatetheboringstuff.com/3e/chapter11.html)

### `with` statements and filepaths

**My Definition:**
Instead of having to use file.close() all the time, `with` statements allow you to create a temporary file object that closes when the program leaves the code block started by the `with` statement

**Example Code:**

```Python
with Path().open() as file_variable:

# OR:

with open(Path()) as file_variable:
```

**Why It Matters:**
Cleans up otherwise messy open() / code() lines

### continue keyword

**My Definition:**
`continue` throws the code block back to the start of a loop. Think of it more like a "restart" keyword. 

**Why It Matters:**
This is useful when you have a while block with multiple conditions inside of it, where, if certain conditions are not met, the loop needs to restart.

**Example from My Work:**
[Concrete example from Russian ORBAT database or other projects]

**Common Mistakes:**
[Gotchas you encountered or want to avoid]

**Related Concepts:**
- [Related term 1]
- [Related term 2]

**Resources:**
- [Link to documentation]
- [Tutorial or article that helped]
