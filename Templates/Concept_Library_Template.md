# Concept Library & Glossary

**Purpose:** Running glossary of technical terms and concepts you learn  
**Last Updated:** [Date]  
**Status:** Living document - add entries as you learn

---

## How to Use This Document

**When to Add an Entry:**
- You encounter a new technical term
- You finally understand something that was confusing
- You learn a concept worth remembering
- You make a breakthrough in understanding

**Entry Format:**
```
### Term or Concept
**Category:** [Python / SQL / Git / Web / General Programming]
**Phase Learned:** [1 / 2 / 3]
**Date Added:** [Date]

**Definition:**
[Your explanation in your own words]

**Why It Matters:**
[How it applies to your work or learning]

**Example:**
[Concrete example, ideally from your own code]

**Related Concepts:**
- [Link to related entry]
- [Link to related entry]

**Resources:**
- [Where you learned it]
```

---

## General Programming Concepts

### Variable
**Category:** General Programming  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
A container that stores a value with a name. Like a labeled box that holds data.

**Why It Matters:**
Fundamental building block of all programming. Lets you store and reuse data.

**Example:**
```python
unit_name = "36th Separate Guards Motor Rifle Brigade"
unit_key = "x00001"
```

**Related Concepts:**
- Data types
- Assignment operator (=)

---

### Function
**Category:** General Programming  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
A reusable block of code that performs a specific task. Takes inputs (parameters), does something, returns output.

**Why It Matters:**
Avoids repeating code. Makes programs modular and easier to maintain.

**Example:**
```python
def search_units(search_term):
    # Function body
    results = query_database(search_term)
    return results
```

**Related Concepts:**
- Parameters vs. Arguments
- Return values
- Scope

---

### Loop
**Category:** General Programming  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Repeats a block of code multiple times. Two main types: `for` (iterate over items) and `while` (continue until condition false).

**Why It Matters:**
Process large datasets without writing repetitive code.

**Example:**
```python
# Process each row from database
for row in cursor:
    unit_key = row[0]
    process_unit(unit_key)
```

**Related Concepts:**
- Iteration
- Break and continue
- List comprehensions

---

## Python-Specific Concepts

### List
**Category:** Python  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Ordered collection of items. Items can be different types. Enclosed in square brackets `[]`.

**Why It Matters:**
Store multiple values in single variable. Iterate over collections of data.

**Example:**
```python
unit_keys = ["x00001", "x00002", "x00003"]
for key in unit_keys:
    print(key)
```

**Related Concepts:**
- Indexing (list[0])
- Slicing (list[1:3])
- List methods (append, extend, etc.)

---

### Dictionary
**Category:** Python  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Collection of key-value pairs. Like a real dictionary where you look up a word (key) to find its definition (value). Enclosed in curly braces `{}`.

**Why It Matters:**
Store structured data. Map one value to another. Similar to database row.

**Example:**
```python
unit = {
    "unit_key": "x00001",
    "name": "36th Separate Guards Motor Rifle Brigade",
    "echelon": "X"
}
print(unit["name"])  # Access value by key
```

**Related Concepts:**
- JSON (very similar structure)
- Database rows (conceptual similarity)
- Keys must be unique

---

### Try-Except Block
**Category:** Python  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Error handling mechanism. "Try" to do something, if it fails, "except" (catch) the error and handle it gracefully instead of crashing.

**Why It Matters:**
Prevents scripts from crashing on unexpected errors. Essential for production code.

**Example:**
```python
try:
    position = fetch_unit_position(unit_key)
except Exception as e:
    print(f"Error fetching position: {e}")
    position = None
```

**Related Concepts:**
- Exception types
- Finally clause
- Raising exceptions

---

### Import Statement
**Category:** Python  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Brings in code from other files or libraries so you can use their functions.

**Why It Matters:**
Reuse existing code instead of reinventing the wheel. Access powerful libraries.

**Example:**
```python
import psycopg2  # PostgreSQL library
import geopandas as gpd  # GeoPandas with alias
from datetime import datetime  # Import specific function
```

**Related Concepts:**
- Libraries vs. modules
- Aliases (as)
- Installing packages (pip)

---

## SQL/Database Concepts

### Primary Key
**Category:** SQL  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Column (or combination of columns) that uniquely identifies each row in a table. No duplicates allowed, never null.

**Why It Matters:**
Foundation of database integrity. Allows other tables to reference this table reliably.

**Example:**
```sql
CREATE TABLE russian_units (
    unit_key VARCHAR(10) PRIMARY KEY,  -- Each unit has unique key
    name VARCHAR(255),
    echelon VARCHAR(10)
);
```

**Related Concepts:**
- Foreign key
- Unique constraint
- Composite keys

---

### Foreign Key
**Category:** SQL  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Column that references the primary key of another table. Creates relationship between tables. Enforces referential integrity.

**Why It Matters:**
Prevents orphaned data. Ensures relationships stay valid. Core of relational database design.

**Example:**
```sql
CREATE TABLE unit_positions (
    position_id SERIAL PRIMARY KEY,
    unit_key VARCHAR(10) REFERENCES russian_units(unit_key),  -- FK
    latitude NUMERIC,
    longitude NUMERIC
);
```

**Related Concepts:**
- Primary key
- Referential integrity
- ON DELETE/UPDATE actions

---

### JOIN
**Category:** SQL  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Combines rows from two or more tables based on related column. Different types: INNER, LEFT, RIGHT, FULL.

**Why It Matters:**
Access data spread across multiple tables. Foundation of relational database queries.

**Example:**
```sql
SELECT u.name, p.latitude, p.longitude
FROM russian_units u
INNER JOIN unit_positions p ON u.unit_key = p.unit_key
WHERE p.observation_date > '2024-01-01';
```

**Related Concepts:**
- Table aliases
- JOIN types
- WHERE vs. ON

---

### Index
**Category:** SQL  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Database structure that speeds up data retrieval. Like an index in a book - helps find data faster without scanning entire table.

**Why It Matters:**
Critical for query performance on large tables. Can make queries 100x+ faster.

**Example:**
```sql
CREATE INDEX idx_positions_date 
ON unit_positions(observation_date);

-- Now queries filtering by observation_date are faster
```

**Related Concepts:**
- B-tree indexes
- Spatial indexes (GIST)
- Index maintenance cost

---

### View
**Category:** SQL  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Saved query that acts like a virtual table. Doesn't store data itself, runs the query each time you reference it.

**Why It Matters:**
Simplify complex queries. Provide different perspectives on data. Hide complexity from users.

**Example:**
```sql
CREATE VIEW current_orbat AS
SELECT 
    u.unit_key,
    u.name,
    p.latitude,
    p.longitude
FROM russian_units u
LEFT JOIN unit_positions p ON u.unit_key = p.unit_key
    AND p.is_current = TRUE;

-- Now can query: SELECT * FROM current_orbat;
```

**Related Concepts:**
- Materialized views
- Query performance
- Abstraction

---

### Trigger
**Category:** SQL  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Automated action that fires when specific event happens (INSERT, UPDATE, DELETE). Like a "if this happens, automatically do that" rule.

**Why It Matters:**
Maintain data integrity automatically. Enforce business rules. Keep related data in sync.

**Example:**
```sql
CREATE TRIGGER update_unit_coordinates
AFTER INSERT ON unit_positions
FOR EACH ROW
EXECUTE FUNCTION sync_unit_location();
```

**Related Concepts:**
- BEFORE vs. AFTER triggers
- Row-level vs. statement-level
- Trigger functions

---

## Git/Version Control Concepts

### Commit
**Category:** Git  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Snapshot of your code at a point in time. Like saving a version with a description of what changed.

**Why It Matters:**
Track history of changes. Can revert to previous versions. Document your progress.

**Example:**
```bash
git add position_update_v3.py
git commit -m "Fixed coordinate transformation bug"
```

**Related Concepts:**
- Commit messages
- Git history
- SHA hashes

---

### Branch
**Category:** Git  
**Phase Learned:** 2  
**Date Added:** [Date]

**Definition:**
Separate line of development. Like a parallel universe where you can make changes without affecting main code.

**Why It Matters:**
Work on features without breaking main code. Experiment safely. Collaborate with others.

**Example:**
```bash
git branch feature/china-orbat
git checkout feature/china-orbat
# Make changes...
git commit -m "Add China ORBAT schema"
```

**Related Concepts:**
- Main/master branch
- Merging
- Branch strategies

---

## Web Development Concepts

### HTML
**Category:** Web  
**Phase Learned:** 3  
**Date Added:** [Date]

**Definition:**
HyperText Markup Language. Structure and content of web pages. Uses tags to define elements.

**Why It Matters:**
Foundation of all websites. Defines what appears on the page.

**Example:**
```html
<h1>Russian ORBAT Database</h1>
<p>Track Russian military units in Ukraine</p>
<button>Search Units</button>
```

**Related Concepts:**
- Tags and elements
- Attributes
- Semantic HTML

---

### CSS
**Category:** Web  
**Phase Learned:** 3  
**Date Added:** [Date]

**Definition:**
Cascading Style Sheets. Controls appearance and layout of HTML elements. Separates content from presentation.

**Why It Matters:**
Makes websites look good. Responsive design. User experience.

**Example:**
```css
button {
    background-color: blue;
    color: white;
    padding: 10px;
}
```

**Related Concepts:**
- Selectors
- Box model
- Responsive design

---

## GIS-Specific Concepts

### Coordinate Reference System (CRS)
**Category:** GIS  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Mathematical framework for defining how coordinates map to locations on Earth. Different CRS represent Earth differently.

**Why It Matters:**
~70% of your spatial data issues stem from CRS mismatches. Critical to get right.

**Example:**
```python
# EPSG:4326 = WGS84 (lat/long)
# EPSG:3857 = Web Mercator (web maps)
gdf = gdf.to_crs("EPSG:4326")
```

**Related Concepts:**
- Projection
- EPSG codes
- Geographic vs. projected CRS

---

### Spatial Join
**Category:** GIS  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Join tables based on spatial relationship (intersects, contains, within) rather than matching values.

**Why It Matters:**
Assign units to tactical areas. Find what's near what. Core GIS operation.

**Example:**
```python
# Which tactical area is each unit in?
units_with_areas = gpd.sjoin(
    units_gdf, 
    tactical_areas_gdf, 
    how='left',
    predicate='within'
)
```

**Related Concepts:**
- Spatial predicates
- PostGIS ST_Within
- Buffer operations

---

## Data Design Concepts

### Normalization
**Category:** Database Design  
**Phase Learned:** 2  
**Date Added:** [Date]

**Definition:**
Process of organizing data to reduce redundancy. Breaks data into related tables with foreign keys.

**Why It Matters:**
Prevents data anomalies. Makes updates easier. Foundation of good database design.

**Example:**
**Bad (denormalized):**
```
unit_positions: unit_key, unit_name, echelon, lat, long
# unit_name repeated for every position
```

**Good (normalized):**
```
russian_units: unit_key, unit_name, echelon
unit_positions: position_id, unit_key (FK), lat, long
# unit_name stored once
```

**Related Concepts:**
- Normal forms (1NF, 2NF, 3NF)
- Denormalization (when to break rules)
- Data redundancy

---

### Foreign Key Constraint
**Category:** Database Design  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Database rule that enforces referential integrity. Prevents inserting invalid references.

**Why It Matters:**
Data quality. Prevents orphaned records. Catches errors at database level.

**Example:**
```sql
-- This will fail if unit_key doesn't exist in russian_units
INSERT INTO unit_positions (unit_key, latitude, longitude)
VALUES ('x99999', 48.5, 37.2);
-- ERROR: foreign key constraint violation
```

**Related Concepts:**
- Referential integrity
- ON DELETE CASCADE
- Constraint validation

---

## Performance Concepts

### Query Optimization
**Category:** Database Performance  
**Phase Learned:** 2  
**Date Added:** [Date]

**Definition:**
Process of making queries run faster. Involves indexes, query rewriting, understanding execution plans.

**Why It Matters:**
Difference between 1 second and 1 minute queries. User experience. Server resources.

**Example:**
```sql
-- Slow: scans entire table
SELECT * FROM unit_positions WHERE observation_date > '2024-01-01';

-- Fast: uses index on observation_date
-- (after CREATE INDEX idx_positions_date ON unit_positions(observation_date))
```

**Related Concepts:**
- EXPLAIN ANALYZE
- Index usage
- Query planning

---

### Partitioning
**Category:** Database Performance  
**Phase Learned:** 1  
**Date Added:** [Date]

**Definition:**
Splitting large table into smaller physical pieces while appearing as single table. PostgreSQL can use hash, range, or list partitioning.

**Why It Matters:**
Query performance on huge tables. Maintenance. You use this for MAID data (16 partitions).

**Example:**
```sql
-- Your MAID table uses hash partitioning
-- Data automatically distributed across 16 partitions
-- Queries only scan relevant partitions
```

**Related Concepts:**
- Hash partitioning
- Partition pruning
- Partition management

---

## Common Acronyms & Abbreviations

### CRUD
**Definition:** Create, Read, Update, Delete - basic database operations

### API
**Definition:** Application Programming Interface - way for programs to communicate

### JSON
**Definition:** JavaScript Object Notation - data format for storing/transmitting data

### CTE
**Definition:** Common Table Expression - temporary result set in SQL query

### ORM
**Definition:** Object-Relational Mapping - converts between database tables and code objects

### REPL
**Definition:** Read-Eval-Print Loop - interactive programming environment

---

## Learning Milestones

### Concepts I Struggled With But Now Understand
- [Date] - [Concept] - [What clicked for me]

### Concepts I'm Still Working On
- [Concept] - [What's confusing] - [Resources I'm using]

---

## Quick Reference Patterns

### Common Code Patterns I Use

**PostgreSQL Connection:**
```python
import psycopg2

conn = psycopg2.connect(
    dbname="orbat_db",
    user="username",
    password="password",
    host="localhost"
)
cursor = conn.cursor()
```

**Error Handling Template:**
```python
try:
    # Risky operation
    result = dangerous_function()
except SpecificError as e:
    # Handle specific error
    print(f"Specific error: {e}")
except Exception as e:
    # Catch-all
    print(f"Unexpected error: {e}")
finally:
    # Always runs
    cleanup()
```

---

## Notes

**Remember:** Explain concepts in YOUR words. If you can't explain it simply, you don't understand it yet.

**Update Strategy:**
- Add entry immediately when you learn something new
- Review and refine explanations as understanding deepens
- Link related concepts together
- Add real examples from your code

---

**This is YOUR knowledge base. Make it useful for future you!**
