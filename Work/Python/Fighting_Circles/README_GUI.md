# Fighting Circles Generator - GUI Version

A graphical user interface for processing UA GEN STAFF sitreps and generating fighting circles with spatial matching.

## Features

✨ **User-Friendly Interface**: No more command-line operations!
💾 **Persistent Settings**: All your configurations are saved between sessions
🗺️ **Smart Mapping**: Interactive heading-to-bucket polygon mapping
📊 **Results Display**: View unmatched settlements in a dedicated pane
⚡ **Progress Tracking**: Real-time processing status with logs

## Installation

### Prerequisites

Make sure you have Python 3.7+ installed with the following packages:

```bash
pip install python-docx pandas geopandas rapidfuzz shapely numpy
```

### Files Required

- `fcs_gui.py` - The GUI application
- `fcs.py` - The core processing functions
- `citypoints.shp` - City points shapefile (and associated .dbf, .shx files)
- `frontline_frontline.shp` - Frontline shapefile
- `Collection Buckets.shp` - Collection buckets shapefile

## Usage

### 1. Launch the Application

```bash
python fcs_gui.py
```

Or on Windows:
```bash
python.exe fcs_gui.py
```

### 2. Select Your Document and Output

- Click **Browse** next to "Daily Collect Document"
- Navigate to your daily collect document (.docx file)
- The path will be saved for future sessions

**Optional - Custom Output Directory:**
- By default, output files are saved to the same directory as your document
- To save elsewhere, click **Browse** next to "Output Directory"
- Select your preferred output folder
- This setting is remembered for future sessions

### 3. Configure Shapefile Paths (First Time Only)

If your shapefiles are **not** in the same folder as `fcs_gui.py`:

- Click **Browse** next to each shapefile path
- Select the correct shapefile location
- These paths will be saved and auto-populated in future sessions

**Default locations** (if files exist in script directory):
- `citypoints.shp`
- `frontline_frontline.shp`
- `Collection Buckets.shp`

### 4. Map Document Sections to Buckets

This is a **one-time setup** that saves for all future sessions:

1. After selecting a document, click **Configure Mappings**
2. The GUI will automatically scan your document for **bold bullet sections with UA GEN STAFF sitrep mentions**
3. A dialog will appear showing:
   - **Left side**: Document sections (composite of Heading 1 + bold bullet direction, e.g., "Kharkiv Oblast - Kupyansk direction")
   - **Right side**: Dropdown menus with bucket polygon names from your shapefile
4. Map each document section to its corresponding shapefile bucket polygon
5. Click **Save Mappings**

**What are "document sections"?**
- The script looks for **bold bullet points** under Heading 1 sections
- Only includes sections **between "Axis-Specific Kinetic Collect" and "Crimea" heading**
- Only includes sections that **contain "UA GEN STAFF sitrep" callouts**
- These get combined into bucket names like "Kharkiv Oblast - Kupyansk direction"
- You map these to the corresponding polygon names in your shapefile

**Example Mappings:**
```
Document Section                          →  Shapefile Bucket Polygon
──────────────────────────────────────────────────────────────────────
Kharkiv Oblast - General                  →  Kharkiv Oblast
Kharkiv Oblast - Kupyansk direction       →  Kupyansk
Donetsk Oblast - Lyman direction          →  Lyman
Donetsk Oblast - Siversk direction        →  Siversk
```

These mappings are saved to `.fcs_config.json` and will be used for all future processing.

**Important Note:**
If your document's bold bullet sections change (e.g., someone uses "Kupyansk area" instead of "Kupyansk direction"), you don't need new shapefiles! Just open the mapping dialog again and create the new mapping.

### 5. Run Processing

1. Click **Run Processing**
2. Watch the progress bar and processing log
3. Review results in the tabs:
   - **Processing Log**: Full execution details
   - **Unmatched Settlements**: Settlements that couldn't be matched (if any)

### 6. Output Files

Files are saved to your selected output directory (or the document's directory if not specified):

- `FC_MMDDYYYY.shp` - Fighting circles shapefile (with .dbf, .shx, etc.)
- `FC_MMDDYYYY.csv` - Fighting circles data in CSV format

**Note:** The date format is MMDDYYYY (e.g., `FC_01152025.shp` for January 15, 2025)

## Configuration File

Settings are automatically saved to `.fcs_config.json` in the script directory:

```json
{
  "shapefile_paths": {
    "city_shp": "citypoints.shp",
    "frontline_shp": "frontline_frontline.shp",
    "bucket_shp": "Collection Buckets.shp"
  },
  "bucket_field": "Name",
  "heading_to_bucket_map": {
    "Kharkiv Oblast": "Kharkiv Oblast",
    "Kupyansk": "Kupyansk"
  },
  "last_docx_dir": "/path/to/last/directory",
  "last_output_dir": "/path/to/output/directory",
  "distance_threshold": 15000
}
```

**To reset all settings**: Simply delete `.fcs_config.json`

## Understanding the Results

### Processing Log Tab

Shows detailed processing information:
- Number of settlements extracted
- Matching statistics
- Output file locations
- Summary by heading/oblast

### Unmatched Settlements Tab

Lists all settlements that could not be matched, including:
- Settlement name
- Direction/heading where it appeared
- Source text from document

**Common reasons for unmatched settlements:**
- Settlement name spelling differs from shapefile
- Settlement outside 15km from frontline
- Settlement not in specified bucket polygon
- Heading not mapped to a bucket

You can use this list to manually add settlements to your feature class in ArcGIS/QGIS.

## Tips

### Updating Mappings

- To change mappings, just click **Configure Mappings** again
- Previous mappings will be pre-populated
- Only save when you're done making changes

### Multiple Documents

- Process multiple documents without restarting
- Just browse to a new document and click Run
- All settings persist between runs

### Document Structure Requirements

For the script to work properly, your document needs this structure:

```
[Earlier content...]

Bold, Underlined, Centered: Axis-Specific Kinetic Collect

Heading 1: Kharkiv Oblast
  • Bold bullet: Kupyansk direction
    - Regular text: "UA GEN STAFF sitrep reported attacks IVO settlement1, settlement2..."
  • Bold bullet: Lyman direction
    - Regular text: "UA GEN STAFF sitrep reported attacks toward settlement3..."

Heading 1: Donetsk Oblast
  • Bold bullet: Siversk direction
    - Regular text: "UA GEN STAFF sitrep reported..."

Heading 1: Crimea
[End of processing range]
```

The script extracts:
- **Sections between** "Axis-Specific Kinetic Collect" and "Crimea" heading
- **Heading 1** (e.g., "Kharkiv Oblast")
- **Bold bullets** (e.g., "Kupyansk direction")
- **Only sections with** "UA GEN STAFF sitrep" mentions
- Combines them into **buckets** (e.g., "Kharkiv Oblast - Kupyansk direction")

### Troubleshooting

**"No bucket sections found with UA GEN STAFF sitrep callouts"**
- Ensure your document has "Axis-Specific Kinetic Collect" section marker
- Ensure your document uses **Heading 1** styles for major sections (oblasts/axes)
- Ensure your document has **bold bullet points** for directions/areas
- The bold bullets should appear under Heading 1 sections
- Make sure paragraphs contain "UA GEN STAFF sitrep" text
- Processing stops at "Crimea" Heading 1 (if present)

**"Field 'Name' not found in bucket shapefile"**
- Check your bucket shapefile field name
- Edit `bucket_field` in `.fcs_config.json` if different

**"No settlements found"**
- Verify document contains "UA GEN STAFF sitrep" text
- Check that text follows pattern: "IVO settlement" or "toward settlement"

## Advanced Configuration

Edit `.fcs_config.json` to adjust:

- `distance_threshold`: Maximum distance (meters) from frontline (default: 15000)
- `bucket_field`: Field name in bucket shapefile containing polygon names

## Comparison with CLI Version

| Feature | CLI (fcs.py) | GUI (fcs_gui.py) |
|---------|--------------|------------------|
| File selection | Manual typing | Browse dialogs |
| Settings persistence | None | Automatic |
| Heading mapping | Manual code edit | Interactive dialog |
| Unmatched display | Console list | Dedicated pane with full details |
| Progress tracking | Console output | Progress bar + logs |
| Multi-document | Restart each time | Seamless switching |

## Support

For issues or questions:
1. Check the Processing Log tab for detailed error messages
2. Verify all shapefiles exist and are valid
3. Check `.fcs_config.json` for configuration issues
4. Try deleting `.fcs_config.json` to reset to defaults

## License

Internal use only - ISW workflow tool
