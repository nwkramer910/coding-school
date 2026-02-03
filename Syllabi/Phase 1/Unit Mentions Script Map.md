# Script Map

## High-Level Flow

START
↓
Import libraries
↓
Connect to the database
↓
Determine if the unit is unknown
↓
If yes, execute SELECT query on database function to generate unknown unit key
↓
Determine date of observation using datetime library
↓
Determine which source is being used
↓
Generate location data from either tactical_area_id, adm4_pcode, or coordinate data
↓
If from coordinate data, configure how to read and transform coordinate data
↓
Build notes field from inputs
↓
Execute the INSERT by selecting data from variables with inputs
↓
Run the function with test data
↓
END

## Variables & Their Purpose

* `parts` is the ambiguous variable that is run through the if/elif statement, which determines if it is actually the `lat` or `long` variable
* `conn` is the variable defined by the dictionary that contains the connection details to PostgreSQL
* `cur` is a variable defined by a function `cursor()` to make calling the database connection simpler
* `results` is the variable that stores the completion or error message for each inputted data point
* `unit` is the variable defined by the user-inputted dictionary of attributes
* `location_geom` is the variable that stores the geometry data for the point
* `adm4_pcode` is the variable to store the adm4_pcode attribute from the data
* `location_note` is a variable built out to display to the user where the unit they just inputted is located
* `category` is the variable that defines whether a unit_key should start with za or zb
* `generated_key` is that unit_key
* `obs_date` is the mention's observation date
* `source_url` is the link to the source data
* `coords` is the combination of the `lat` and `lon` coordinates parsed in `parse_coords`
* `analyst_notes` is the field where the analyst inputs their comments on the unit
* `full_notes` is the combo of analyst and location notes
* `unit_test` is the actual user-inputted data

## Database Operations

* `INSERT INTO unit_mentions()` is the main operation the script is built around--inserting data into the database. Everything else is window dressing.
* `SELECT functions.generate_unknown_unit_key()` runs the SQL function generate_unknown_unit_key, which builds out a unit key for the unknown unit based on the input of either za or zb

## Configuration & Secrets

* It will need to import the libraries psycopg2, datetime, and re (superfluos)
* It needs the credential data to be hardcoded, which introduces vulnerability as the code is uploaded to GitHub.

## Logs & Monitoring

* It logs to results, where it also lets the user know if an error occurred.

## Error Scenarios & Recovery

### Scenario 1: Coordinate Data doesn't parse

* **When it happens:** At the 6th operation within the main function
* **Error message:** "Error parsing coordinates '{coord_string}': {e}"
* **Root cause:** The data wasn't presented in one of the three ways it recognizes (lat, long without 'N/S' or 'E/W'; lat, long data with 'N/S' or 'E/W'; lat, long data with 'n/s' or 'e/w'
* **How to recover:** Properly input the coordinate data

### Scenario 2: Database Connection Fails
- **When it happens:** at the beginning of the script execution when it calls on cursor
- **Error message:** Database connection failure FATAL
- **Root cause:** incorrect credentials
- **How to recover:** input proper hardcoded credentials

### Scenario 3: Foreign Key Violation
**When:** On `INSERT INTO unit_mentions`
**Error:** psycopg2.IntegrityError: insert or update on table "unit_mentions" violates foreign key constraint
**Root cause:** unit_key or unknown_unit_key references a unit that doesn't exist
**Recovery:** Verify the unit exists in the database first
**Prevention:** Add validation before INSERT

### Scenario 4: Required Field Missing
**When:** On `INSERT INTO unit_mentions`
**Error:** psycopg2.IntegrityError: null value in column violates not-null constraint
**Root cause:** A required field wasn't provided in the input
**Recovery:** Provide the required field
**Prevention:** Validate all required fields before INSERT



## Questions Still Unanswered


