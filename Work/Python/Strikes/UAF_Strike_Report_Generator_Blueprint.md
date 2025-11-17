# Python Script Blueprint: Ukrainian Air Force Strike Report Generator

## Overview
Script extracts data from Ukrainian Air Force Telegram posts (pasted as English translation), populates an Excel tracking sheet, and generates formatted Word document analysis.

## Input/Output
- **Input**: User pastes English-translated UAF Telegram post text
- **Output 1**: `RUAF_Strikes_in_UA.xlsx` (appends new row)
- **Output 2**: `Strike_[MonthDay]_[Year].docx` (e.g., `Strike_Oct22_2024.docx`)

## Excel Column Structure

| Column | Data | Format/Notes |
|--------|------|--------------|
| A | Date phrase | "October 21 and 22" |
| B | Total drones launched | Integer |
| C | Total missiles launched | Integer (sum of all missile types) |
| D | Total air targets | Integer (B + C) |
| E | Shahed drones count | Integer |
| F | Drones shot down | Integer |
| G | Iskanders fired | "X Isk-K, Y Isk-M/KN-23" |
| H | Iskanders shot down | "X Isk-K, Y Isk-M/KN-23" |
| I | S-300/400 fired | Integer |
| J | S-300/400 shot down | Integer |
| K | Kh-101/55/555 fired | Integer |
| L | Kh-101/55/555 shot down | Integer |
| M | Kh-59/69 fired | Integer |
| N | Kh-59/69 shot down | Integer |
| O | Kh-31/32/22 fired | Integer |
| P | Kh-31/32/22 shot down | Integer |
| Q | Kalibr fired | Integer |
| R | Kalibr shot down | Integer |
| S | Kh-47 Kinzhal fired | Integer |
| T | Kh-47 Kinzhal shot down | Integer |
| U | Misc. munitions | Text (analyst adds manually if needed) |
| V | % Intercepted Missiles | Formula: SUM(J,L,N,P,R,T,H_parsed)/C |
| W | Link | Text (analyst adds manually) |

## Text Template Structure

### Sentence 1: Opening
**Format**: "Russian forces conducted a [large combined drone and missile strike / series of drone strikes] against Ukraine on the night of {Column A}."

**Logic**: 
- If Column C > 0 → "large combined drone and missile strike"
- If Column C = 0 or NULL → "series of drone strikes"

### Sentence 2: Drone Launch
**Format**: "The Ukrainian Air Force reported that Russian forces launched {Column B} Shahed-type, Gerbera-type, and other drones -- roughly {Column E} of which were Shahed drones -- from {parsed launch locations}."

### Sentence 3: Missile Launches
**Format**: "The Ukrainian Air Force reported that Russian forces also launched {list of missile systems with semicolons, 'and' before last}."

**Order and grouping**:
1. Iskander-M/KN-23 (from Column G)
2. Iskander-K (from Column G)
3. Kh-47M2 Kinzhal (Column S)
4. Kh-59/69 (Column M)
5. Kh-101/55/555 (Column K)
6. Kh-31/32/22 (Column O)
7. Kalibr (Column Q)

**Each missile entry format**: "{number} {weapon name} from {parsed locations}"

**Separate sentence for S-300/400**: "Russian forces also launched {Column I} S-300/S-400 SAMs from {parsed locations}."

### Sentence 4: Shootdowns
**Format**: "The Ukrainian Air Force reported that Ukrainian forces downed {Column F} drones, {list all missile shootdowns with semicolons, 'and' before last}."

**Missile shootdown order**:
- Iskander-K (from Column H)
- Iskander-M/KN-23 (from Column H)
- Kh-59/69 (Column N)
- Kh-47M2 Kinzhal (Column T)
- Kh-101/55/555 (Column L)
- Kh-31/32/22 (Column P)
- Kalibr (Column R)
- S-300/400 (Column J)

### Sentence 5+: Impact/Damage
**Parse from original text**:
- Hits: "that X missiles and Y drones hit Z locations"
- Debris: "that drone debris fell on X locations"
- Lost drones: "that X drones did not reach their targets as they were 'lost in location' (likely referring to Ukrainian electronic warfare [EW] interference)"
- Target areas: "that the Russian strikes primarily targeted {oblast} and also affected {list of oblasts}"
- Damage: "Ukrainian officials reported that the strikes damaged {type} infrastructure in {oblasts}"

## Formatting Rules

### Number Formatting
- **≤12**: Spell out (one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve)
- **>12**: Use numerals (13, 250, 405)

### NULL Handling
- Insert text: "**NULL**"
- Apply yellow highlight to NULL text
- Keep full sentence structure even with NULL values

### Text Parsing Requirements
Script must extract from pasted text:
- Launch locations (by weapon system)
- Impact locations
- Target oblasts
- Damage descriptions
- Hit counts
- Debris locations
- Lost drone counts

## Key Script Functions Needed

1. **Text parser**: Regex/pattern matching to extract numerical data and location strings
2. **Number formatter**: Convert integers to spelled-out words (1-12) or numerals (>12)
3. **Excel handler**: 
   - Open existing file or create new
   - Append row with data
   - Auto-calculate Column V
4. **Word generator**:
   - Create formatted paragraphs
   - Apply yellow highlighting to NULL
   - Handle weapon system conditionals
   - Smart conjunction insertion (semicolons + final "and")
5. **Iskander parser**: Split "9 Isk-K, 11 Isk-M/KN-23" format into separate counts

## Dependencies
- `openpyxl` or `pandas` for Excel
- `python-docx` for Word document generation
- `re` for text parsing

## Error Handling
- If data point not found in text → NULL
- If Excel file doesn't exist → create with headers
- Validate date format before file naming
