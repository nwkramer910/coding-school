# UAF Strike Report Generator

Python tool with GUI and CLI interfaces that extracts data from Ukrainian Air Force Telegram posts (pasted as English translation), populates an Excel tracking sheet, and generates formatted Word document analysis.

## Features

- **User-Friendly GUI**: Easy-to-use graphical interface for pasting and processing reports
- **Text Parsing**: Automatically extracts drone counts, missile types, locations, and damage information from UAF Telegram posts
- **Excel Tracking**: Maintains a comprehensive tracking spreadsheet (`RUAF_Strikes_in_UA.xlsx`) with all strike data
- **Word Reports**: Generates professionally formatted Word documents following ISW style guidelines
- **Smart Formatting**:
  - Numbers 1-9 are spelled out, numbers 10+ use numerals
  - NULL values are highlighted in yellow for easy identification
  - Proper list formatting with semicolons and conjunctions
  - Weapon-specific location parsing from Telegram post format
  - Automatic conversion of "regions" to "oblasts"
- **Real-time Feedback**: Visual status updates and data extraction summaries

## Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

Or manually:
```bash
pip install openpyxl python-docx
```

## Usage

### GUI Mode (Recommended)

The easiest way to use the tool is through the graphical interface:

1. Run the GUI:
```bash
python uaf_strike_report_gui.py
```

2. Paste the English-translated UAF Telegram post text into the input area

3. Select which outputs to generate (Excel, Word, or both)

4. Click "Process Report"

5. The script will generate:
   - **Excel file**: `RUAF_Strikes_in_UA.xlsx` (appends new row)
   - **Word document**: `Strike_[MonthDay]_[Year].docx` (e.g., `Strike_Oct22_2024.docx`)

**GUI Features:**
- Large text area for easy pasting of multiline text
- Real-time processing status and feedback
- Visual display of extracted data
- Warning alerts for NULL/missing data fields
- Option to generate Excel only, Word only, or both

### Command Line Mode

For automation or scripting, you can also use the CLI version:

1. Run the script:
```bash
python uaf_strike_report_generator.py
```

2. When prompted, paste the English-translated UAF Telegram post text

3. Press `Ctrl+D` (Linux/Mac) or `Ctrl+Z` then `Enter` (Windows) to finish input

4. The script will generate both Excel and Word outputs

## Data Extracted

The script automatically parses and extracts:

### Drone Data
- Total drones launched
- Shahed drone count
- Drones shot down
- Launch locations

### Missile Data (by type)
- Iskander-M/KN-23 and Iskander-K
- S-300/S-400 SAMs
- Kh-101/55/555 cruise missiles
- Kh-59/69 guided air missiles
- Kh-31/32/22 cruise missiles
- Kalibr cruise missiles
- Kh-47M2 Kinzhal aeroballistic missiles

### Impact Information
- Hit counts and locations
- Debris fall locations
- Lost drones (EW interference)
- Target oblasts
- Damage descriptions

## Excel Column Structure

| Column | Data | Notes |
|--------|------|-------|
| A | Date phrase | "October 21 and 22" |
| B | Total drones launched | Integer |
| C | Total missiles launched | Sum of all missile types |
| D | Total air targets | B + C |
| E | Shahed drones count | Integer |
| F | Drones shot down | Integer |
| G | Iskanders fired | "X Isk-K, Y Isk-M/KN-23" |
| H | Iskanders shot down | "X Isk-K, Y Isk-M/KN-23" |
| I-T | Other missile types | Fired and shot down counts |
| U | Misc. munitions | Manual entry |
| V | % Intercepted Missiles | Auto-calculated |
| W | Link | Manual entry |

## Word Document Format

The generated Word document follows ISW analytical style:

1. **Opening sentence**: Strike type and date
2. **Drone launches**: Count, types, and locations
3. **Missile launches**: All missile types with counts and locations
4. **Shootdowns**: Drones and missiles intercepted
5. **Impact/Damage**: Hits, debris, targets, and damage reports

## NULL Handling

When data cannot be extracted from the input text:
- The script inserts `**NULL**` in the text
- NULL values are highlighted in yellow in the Word document
- Excel cells remain empty for NULL values
- This allows analysts to manually fill in missing data

## Example Input

```
On the night of October 21-22, Russian forces launched 75 Shahed-type drones from Kursk
and Primorsko-Akhtarsk. The Ukrainian Air Force reported that roughly 60 of these were
Shahed drones. Russian forces also launched 3 Iskander-K cruise missiles from Voronezh
Oblast and 5 Iskander-M ballistic missiles from Kursk Oblast...

The Ukrainian Air Force reported that Ukrainian forces downed 45 drones, 2 Iskander-K
cruise missiles, and 3 Iskander-M ballistic missiles...
```

## Example Output Files

- `RUAF_Strikes_in_UA.xlsx` - Updated tracking spreadsheet
- `Strike_Oct21_2024.docx` - Formatted analysis report

## Files Included

- **`uaf_strike_report_gui.py`** - GUI application (recommended)
- **`uaf_strike_report_generator.py`** - CLI version and core library
- **`requirements.txt`** - Python package dependencies
- **`test_parser.py`** - Test script for validation
- **`README.md`** - This documentation

## Notes

- The script maintains existing Excel data and appends new rows
- If the Excel file doesn't exist, it creates a new one with headers
- Manual fields (Misc. Munitions, Link) are left blank for analyst input
- The script uses regex pattern matching for robust text extraction
- Multiple instances of the same weapon type are automatically summed
- GUI requires tkinter (included with most Python installations)

## Troubleshooting

**Missing data in output**:
- Check that the input text format matches UAF Telegram post structure
- NULL values indicate the script couldn't find that data point
- Manually review and fill in NULL values as needed

**File permissions error**:
- Ensure the Excel file isn't open in another program
- Check write permissions in the directory

**Dependencies not found**:
- Run `pip install -r requirements.txt`
- Ensure you're using Python 3.6 or higher
