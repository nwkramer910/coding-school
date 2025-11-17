# Concept Library

A growing glossary of technical terms, concepts, and patterns you're learning. Add to this as you encounter new ideas.

**Last Updated:** [Date]  
**Total Entries:** [Count]

---

## How to Use This Library

1. **Add entries as you learn** - Don't wait until you "fully understand"
2. **Write in your own words** - This isn't copy/paste from documentation
3. **Include examples** - Concrete examples from your work
4. **Link to resources** - Where you learned this
5. **Update as understanding deepens** - Mark initial entry date, update with new insights

**Entry Format:**
```
## Term or Concept

**Category:** [Python | SQL | Database | Git | General]
**Date Added:** [Date]
**Last Updated:** [Date]

**My Definition:**
[Explain it in your own words, like you're teaching someone]

**Why It Matters:**
[Why is this important for your work?]

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
```

---

## Python Concepts

### Function

**Category:** Python  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
A reusable block of code that performs a specific task. Takes inputs (parameters), does something with them, and optionally returns a result.

**Why It Matters:**
Functions let me avoid repeating the same code. If I need to change how something works, I only update it in one place.

**Example from My Work:**
In position_update_v3.py, I have a function that connects to the database. Instead of writing the connection code every time I need the database, I just call `connect_to_db()`.

**Common Mistakes:**
- Forgetting to return a value when I need one
- Not handling errors inside the function
- Making functions do too many things (should do one thing well)

**Related Concepts:**
- Parameters/Arguments
- Return values
- Scope
- Docstrings

**Resources:**
- Automate the Boring Stuff, Chapter 3

---

### List Comprehension

**Category:** Python  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
[Add your definition when you learn this]

**Why It Matters:**
[Why this matters]

**Example from My Work:**
[Your example]

**Common Mistakes:**
[Mistakes to avoid]

**Related Concepts:**
- [Related terms]

**Resources:**
- [Links]

---

## SQL Concepts

### JOIN

**Category:** SQL  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
A way to combine data from multiple tables based on a related column. Like saying "give me data from table A and matching data from table B where they share a common value."

**Why It Matters:**
My database is normalized - information is split across tables to avoid duplication. JOINs let me bring that information back together for analysis.

**Example from My Work:**
```sql
SELECT u.unit_key, u.name, p.location
FROM russian_units u
JOIN unit_positions p ON u.unit_key = p.unit_key
```
This gets me unit names from `russian_units` and their locations from `unit_positions`.

**Common Mistakes:**
- Using INNER JOIN when I need LEFT JOIN (missing data I wanted)
- Forgetting the ON clause (cross product disaster)
- Joining on wrong columns (getting garbage results)

**Related Concepts:**
- INNER JOIN vs LEFT JOIN vs RIGHT JOIN
- Foreign Keys
- Cartesian Product
- ON vs WHERE

**Resources:**
- PostgreSQL docs: https://www.postgresql.org/docs/current/tutorial-join.html

---

### Foreign Key

**Category:** SQL / Database  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
A column in one table that references the primary key of another table. It's like a pointer that ensures data integrity - you can't reference something that doesn't exist.

**Why It Matters:**
Foreign keys prevent me from creating orphan records. For example, I can't create a position for a unit that doesn't exist in `russian_units` if I have a foreign key constraint.

**Example from My Work:**
```sql
unit_key VARCHAR(10) REFERENCES russian_units(unit_key)
```
This ensures every position must reference a valid unit.

**Common Mistakes:**
- Trying to delete a parent record when children exist
- Not creating foreign keys and ending up with orphan data
- Using wrong data type for foreign key column

**Related Concepts:**
- Primary Key
- Referential Integrity
- CASCADE options
- Constraints

**Resources:**
- Database Design for Mere Mortals, Chapter [X]

---

### CTE (Common Table Expression)

**Category:** SQL  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
[Add when you learn this in Phase 2]

**Why It Matters:**

**Example from My Work:**

**Common Mistakes:**

**Related Concepts:**
- Subqueries
- WITH clause
- Temporary tables

**Resources:**

---

## Database Concepts

### Normalization

**Category:** Database  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
The process of organizing database tables to reduce redundancy and dependency. Instead of storing the same information multiple times, you store it once and reference it.

**Why It Matters:**
If I store a unit's name in multiple places and it changes, I have to update it everywhere. With normalization, I store it once in `russian_units` and reference it by unit_key everywhere else.

**Example from My Work:**
Bad (denormalized):
```
unit_positions: unit_key | unit_name | lat | long
                x00001   | 36th MRB  | ... | ...
                x00001   | 36th MRB  | ... | ...  (duplicate name)
```

Good (normalized):
```
russian_units: unit_key | unit_name
               x00001   | 36th MRB

unit_positions: unit_key | lat | long
                x00001   | ... | ...
                x00001   | ... | ...  (just references the key)
```

**Common Mistakes:**
- Over-normalizing (too many tables for simple data)
- Under-normalizing (duplicating data everywhere)
- Not knowing when to denormalize for performance

**Related Concepts:**
- 1NF, 2NF, 3NF
- Foreign Keys
- Referential Integrity
- Denormalization

**Resources:**
- Database Design for Mere Mortals

---

### Index

**Category:** Database  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
A database structure that improves query speed by creating a fast lookup for specific columns. Like an index in a book - instead of reading every page to find a topic, you check the index.

**Why It Matters:**
Queries on my MAID data (millions of records) would be painfully slow without indexes on columns I search frequently.

**Example from My Work:**
```sql
CREATE INDEX idx_maid_unit ON maid_data(unit_key);
```
Now when I search for a specific unit's MAID records, PostgreSQL can jump directly to them instead of scanning millions of rows.

**Common Mistakes:**
- Creating indexes on every column (wastes space and slows writes)
- Not indexing foreign keys (common search columns)
- Forgetting to index columns used in WHERE and JOIN

**Related Concepts:**
- B-Tree Index
- GiST Index (spatial)
- Query Planner
- EXPLAIN

**Resources:**
- PostgreSQL Performance docs

---

## Git Concepts

### Commit

**Category:** Git  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
A snapshot of your code at a specific point in time. It's like a save point in a video game - you can always go back to it.

**Why It Matters:**
If I break something, I can roll back to the last working commit. Commits also document what changed and why.

**Example from My Work:**
```
git commit -m "Add error handling to position update script"
```
This saves my changes with a message explaining what I did.

**Common Mistakes:**
- Committing broken code
- Vague commit messages ("fixed stuff")
- Committing too much at once (hard to understand what changed)
- Committing passwords or secrets

**Related Concepts:**
- Git add (staging)
- Commit messages
- Commit hash
- Git log

**Resources:**
- Pro Git, Chapter 2

---

### Branch

**Category:** Git  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
[Add when you learn this]

**Why It Matters:**

**Example from My Work:**

**Common Mistakes:**

**Related Concepts:**

**Resources:**

---

## General Programming Concepts

### Error Handling

**Category:** General  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
Code that handles when things go wrong instead of just crashing. Like having a backup plan.

**Why It Matters:**
My scripts process real intelligence data. If one record has a problem, I want to log the error and keep processing, not crash and lose the whole batch.

**Example from My Work:**
```python
try:
    # Try to insert position
    cursor.execute(insert_query, data)
except psycopg2.Error as e:
    # If it fails, log the error but keep going
    print(f"Error inserting position: {e}")
    error_count += 1
```

**Common Mistakes:**
- Catching all errors blindly (hiding real problems)
- Not logging what went wrong
- Continuing when I should stop (database connection lost)

**Related Concepts:**
- try/except/finally (Python)
- Exceptions
- Logging
- Graceful degradation

**Resources:**
- Automate the Boring Stuff, Chapter [X]

---

### DRY (Don't Repeat Yourself)

**Category:** General  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
[Add when you fully grasp this]

**Why It Matters:**

**Example from My Work:**

**Common Mistakes:**

**Related Concepts:**

**Resources:**

---

## ArcGIS/GIS Concepts

### Feature Class

**Category:** ArcGIS  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
A collection of geographic features (points, lines, polygons) with the same geometry type and attributes. Like a database table, but spatial.

**Why It Matters:**
My unit positions are stored as feature classes in ArcGIS. Understanding feature classes helps me move data between PostgreSQL and ArcGIS.

**Example from My Work:**
`unit_positions` feature class contains point features for each unit position, with attributes like unit_key, date, status, etc.

**Common Mistakes:**
- Mixing geometry types in one feature class
- Not setting spatial reference correctly
- Forgetting to create spatial indexes

**Related Concepts:**
- Geometry
- Spatial Reference
- Geodatabase
- Feature Layer

**Resources:**
- ArcGIS Pro documentation

---

### Coordinate System / Projection

**Category:** GIS  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
The mathematical framework for representing 3D Earth on a 2D map. Different projections distort different things (distance, area, shape).

**Why It Matters:**
70% of my spatial data issues come from coordinate system mismatches. If my local map is in one projection but my hosted layer is in another, things won't align.

**Example from My Work:**
- My database uses WGS84 (EPSG:4326) - lat/long coordinates
- Some ArcGIS maps use Web Mercator (EPSG:3857)
- Ukrainian military maps use their own system

**Common Mistakes:**
- Assuming all data is in same projection
- Not defining projection on import
- Not transforming between projections correctly

**Related Concepts:**
- WGS84 / EPSG:4326
- Web Mercator / EPSG:3857
- Spatial Reference
- Transformation vs Projection

**Resources:**
- ArcGIS Pro projection docs
- PostGIS spatial reference documentation

---

## Pattern Library

### Safe Database Schema Modification

**Category:** Pattern  
**Date Added:** [Date]  
**Last Updated:** [Date]

**The Pattern:**
1. Add new column/table (don't drop old one)
2. Backfill data from old to new structure
3. Dual-write period (update both old and new)
4. Validate new structure works correctly
5. Switch applications to use new structure only
6. Archive (don't drop immediately) old structure
7. After monitoring period, drop old structure

**Why This Works:**
Lets me roll back if something goes wrong. No data loss. Can test thoroughly before committing.

**When to Use:**
Any production schema change that affects live data.

**Example from My Work:**
When I added the `tactical_area_id` column to positions table, I kept the old settlement reference for a week to make sure the new system worked.

**Variations:**
- For critical data, keep old structure even longer
- For dev/test, can be more aggressive

**Related Patterns:**
- Blue-Green Deployment
- Feature Flags
- Gradual Rollout

---

### Database Connection in Python

**Category:** Pattern  
**Date Added:** [Date]  
**Last Updated:** [Date]

**The Pattern:**
```python
import psycopg2
from contextlib import closing

def get_db_connection():
    """Create database connection with error handling"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            database="russian_orbat",
            user="username",
            password="password"  # Never hardcode in real script!
        )
        return conn
    except psycopg2.Error as e:
        print(f"Database connection failed: {e}")
        return None

# Usage
with closing(get_db_connection()) as conn:
    if conn:
        cursor = conn.cursor()
        # do work
        conn.commit()
```

**Why This Works:**
- Context manager automatically closes connection
- Error handling prevents crashes
- Commit only if work succeeds

**When to Use:**
Every time I need database access in Python.

**Common Mistakes I Made:**
- Forgetting to close connections (connection leak)
- Not committing changes
- Committing partial work when errors occur

---

## Template for New Entries

### [Term or Concept]

**Category:** [Python | SQL | Database | Git | GIS | General]  
**Date Added:** [Date]  
**Last Updated:** [Date]

**My Definition:**
[Your explanation]

**Why It Matters:**
[Relevance to your work]

**Example from My Work:**
[Concrete example]

**Common Mistakes:**
[Gotchas]

**Related Concepts:**
- [Related term]

**Resources:**
- [Links]

---

*This library grows with you. Keep it updated and refer back often.*
