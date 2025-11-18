# Focus Area 2: PostgreSQL Fundamentals for DBAs
## Weeks 2-6 Detailed Lesson Plan

**Student:** Nate Kramer  
**Phase:** Phase 1 - Consolidation & Confidence  
**Focus Area:** PostgreSQL Fundamentals for DBAs (Weeks 2-6)  
**Total Duration:** 5 weeks × 15 hours/week = 75 hours  
**Learning Mode:** TEACHING MODE (default) | EXPLAINER MODE (when needed)  
**Start Date:** November 24, 2025  

---

## Strategic Context

### Why This Focus Area Now

You're transitioning from "someone who writes queries" to "someone who manages database infrastructure." This focus area builds that foundation:

- **Week 1:** You understood your scripts and how they interact with the database
- **Weeks 2-6:** You'll understand the *database itself*—how it works, how to manage it, how to fix it when things break
- **By Week 6:** You'll own your database with confidence, not rely on someone else to maintain it

### Your Russian ORBAT Database

Your database contains:
- **Schemas:** orbat, maid, facilities, geolocations, reference, spatial_ref, functions
- **Key tables:** units, mentions, positions, unit_hierarchy, material_associations (and many more)
- **Spatial data:** PostGIS integration for geographic queries
- **Functions:** Custom PostgreSQL functions for business logic

This real database is your learning laboratory. Every concept connects to actual problems you face.

### What "DBA Fundamentals" Means

As a DBA, you need to understand:
1. **Connection management:** Who can access what? How do you connect as different users?
2. **Permissions and security:** What can each user do? How do you restrict access?
3. **Schema modification:** How do you safely change the structure? What breaks if you're not careful?
4. **Backup and recovery:** What happens if the database crashes? Can you recover?
5. **Query performance:** Why are some queries slow? How do you fix them?
6. **Logs and diagnostics:** When something goes wrong, where do you look?

---

## Five-Week Overview

| Week | Primary Focus | Secondary Focus | Deliverable |
|------|---|---|---|
| **Week 2** | Server architecture & connection management | Schema exploration | Connection runbook |
| **Week 3** | Users, roles, and permissions | Security best practices | Permissions audit |
| **Week 4** | Backup strategy & disaster recovery | Point-in-time recovery | Backup procedures document |
| **Week 5** | Schema modification & safe changes | Understanding constraints | Schema change procedures |
| **Week 6** | EXPLAIN plans & query optimization | Reading PostgreSQL logs | Database optimization guide |

---

## Week 2: Server Architecture & Connection Management

**Dates:** November 24-28, 2025  
**Total Hours:** 15 hours (3-4 per day Tue-Thu, 2-3 fri)  
**Primary Goal:** Understand how PostgreSQL works and how to connect to it securely  
**Deliverable:** Connection Management Runbook  

### Learning Objectives

By the end of Week 2, you should be able to answer:
1. What is a PostgreSQL server and what does it manage?
2. What are the key directories and configuration files?
3. How do you connect as different users?
4. What connection parameters matter?
5. What is a database, a schema, and how do they relate?

### Tuesday Session (3-4 hours): PostgreSQL Architecture Deep Dive

**Session Theme:** "How does PostgreSQL actually work?"

#### Part 1: PostgreSQL Architecture (1 hour)

**Guiding questions to research:**

Before I explain, explore these:

1. **What is a PostgreSQL instance?** 
   - (Hint: It's not one database—it's a server that manages multiple databases)
   - Look at your server: how many databases does your instance have? What are they?

2. **What are the key components?**
   - What is the "data directory"? Where is yours located?
   - What is the "configuration file" (postgresql.conf)? What does it control?
   - What are "log files"? What information do they capture?

**Research assignment:**
- Open PostgreSQL documentation (https://www.postgresql.org/docs/)
- Search for "Server Administration" → "Starting the Database Server"
- Read: "What is PostgreSQL?"
- Read: "File Locations"
- Write in your Concept Library:
  - Definition: "PostgreSQL Instance"
  - Definition: "Data Directory"
  - Definition: "postgresql.conf"

**In-session exploration (with my guidance):**
- If you have local PostgreSQL access, explore your data directory structure
- Open postgresql.conf and identify 5 important settings (don't change them, just read)
- Add your own observations to your Concept Library

#### Part 2: Your Specific Database Setup (1.5 hours)

**Guiding questions about YOUR Russian ORBAT database:**

1. **Connection parameters:**
   - Where does your database live? (localhost? remote server? cloud?)
   - What's the hostname? Port? Database name?
   - Do you know which credentials you use? (Don't share them, but know they exist)

2. **Database structure:**
   - How many databases exist on your instance?
   - How many schemas are in your Russian ORBAT database?
   - What are they? (orbat, maid, facilities, geolocations, reference, spatial_ref, functions)

3. **Exploring your database:**
   - Can you connect using a query tool (pgAdmin, DBeaver, or psql)?
   - Can you list all databases? (Hint: `\l` in psql)
   - Can you list all schemas in your main database? (Hint: `\dn` in psql)
   - Can you describe one table? (Hint: `\d orbat.units`)

**Research + hands-on:**
- Pick ONE table from your Russian ORBAT database (maybe orbat.units)
- Use your query tool to describe it: what columns does it have? What types?
- Look at the schema file (complete_russianorbat_schema.sql)
- Find the CREATE TABLE statement for that table
- Compare: does it match what your tool showed?

**Document in your Concept Library:**
- Definition: "Schema"
- Definition: "Relation"
- Real example: "The orbat.units table contains these columns: [list them]"

#### Part 3: Connection Methods (1-1.5 hours)

**Guiding questions about how you connect:**

1. **Different connection tools:**
   - What tools have you used to connect? (psql? Python? PgAdmin?)
   - What's the difference between using a command-line tool vs. a GUI?
   - When would you use each?

2. **Connection strings:**
   - What information do you need to connect? (host, port, database, user, password)
   - Where do you find this information?
   - How do you store credentials safely? (Hint: NOT in code!)

3. **Connection problems:**
   - What errors have you seen? ("Connection refused"? "Password authentication failed"?)
   - What do these errors mean?
   - How do you troubleshoot?

**Hands-on exploration:**
- Try connecting in multiple ways:
  - If you have psql: `psql -h localhost -U [user] -d russianorbatukraine`
  - If you have Python: write a test connection script
  - If you have DBeaver: set up a connection and test it
- For each method, identify: what connection parameters did you need?
- Create a test "connection matrix": which tools can you use? Which users can you connect as?

**Document:**
- Connection runbook entry: "How to connect with [Tool 1]"
- Connection runbook entry: "How to connect with [Tool 2]"
- Troubleshooting: "If I get 'Connection refused', what should I check?"

### Wednesday Session (3-4 hours): Schema Exploration & Database Navigation

**Session Theme:** "Getting comfortable navigating your database"

#### Part 1: Understanding Your Database Structure (1.5 hours)

**Your Russian ORBAT database has these schemas:**
- `orbat` - ORBAT analysis tables (units, positions, mentions)
- `maid` - MAID tracking tables
- `facilities` - Military facilities
- `geolocations` - Geographic data
- `reference` - Lookup tables
- `spatial_ref` - PostGIS reference system
- `functions` - Custom PostgreSQL functions

**Guiding questions:**

1. **What's in each schema?**
   - Pick TWO schemas (maybe `orbat` and `reference`)
   - List all tables in each: how many? What are they?
   - Can you make a simple diagram? (Doesn't have to be fancy—just visual)

2. **What tables matter most for your automation?**
   - Your scripts mention "units," "positions," "mentions"
   - Which schema are these in?
   - What columns do they have?
   - Which tables do your scripts read from? Write to?

3. **What relationships exist?**
   - Are there foreign keys? (Links between tables)
   - Which tables reference which?
   - How does data flow through your database?

**Hands-on assignment:**
- Use a query tool to explore:
  ```sql
  -- List all schemas
  SELECT schema_name FROM information_schema.schemata;
  
  -- List all tables in a schema
  SELECT table_name FROM information_schema.tables 
  WHERE table_schema = 'orbat';
  
  -- Describe a table
  \d orbat.units  -- or equivalent in your tool
  ```
- Create a visual map (simple text or diagram) showing:
  - Your schemas
  - Key tables in each
  - Which ones your scripts use

**Document in Concept Library:**
- "Schema definition and purpose"
- "Three most important tables in my database and what they store"
- "What foreign keys are and where I see them in my database"

#### Part 2: Table Structure & Constraints (1.5 hours)

**Guiding questions about table design:**

1. **What is a primary key and why does it matter?**
   - Look at `orbat.units`: what's the primary key?
   - Why would a table need one?
   - What would happen if you didn't have one?

2. **What are constraints and what do they do?**
   - Look for PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL constraints
   - For each type, ask: what's it preventing?
   - In your tables, find examples of each

3. **What are indexes and why do they exist?**
   - Your tables probably have indexes—what are they on?
   - Why index some columns and not others?
   - What happens when you query an indexed column vs. a non-indexed one?

**Hands-on exploration:**
- Pick two important tables (maybe `orbat.units` and `orbat.mentions`)
- For each, understand:
  - Primary key: what identifies a unique row?
  - Foreign keys: what other tables does this reference?
  - NOT NULL constraints: which columns must have values?
  - Indexes: which columns are indexed? Why?
- Create a simple table showing this structure

**Document:**
- "How to read table structure in PostgreSQL"
- "What primary key does in orbat.units"
- "What foreign key relationships exist in my database"
- "Which tables have indexes and why (I think)"

### Thursday Session (3-4 hours): Connection Safety & Credential Management

**Session Theme:** "How to connect safely without breaking security"

#### Part 1: Connection Credentials & Security (1 hour)

**Critical guiding questions:**

1. **Where are your database credentials?**
   - Username? Password?
   - Are they stored in code? (Bad idea—why?)
   - Are they stored in environment variables? (Better idea—why?)
   - Are they stored in a config file? (Depends—what should be there and what shouldn't?)

2. **What makes a connection secure?**
   - Should you use localhost vs. remote connections?
   - What's the difference? When would you use each?
   - What's SSL/TLS? Do you need it?

3. **What could go wrong?**
   - What if someone gets your password?
   - What if credentials are in a Git repository?
   - What if a script logs connection strings with passwords?

**Reflection exercise:**
- Review your current setup (don't share credentials, just think about it):
  - Where are your database credentials stored right now?
  - Are they visible to others? Should they be?
  - If someone stole the credentials, what could they access?
  - How long would you wait before realizing they were stolen?

**Research assignment:**
- PostgreSQL documentation: "Client Connections" section
- Read about: .pgpass files, environment variables, connection URI
- Add to Concept Library:
  - "Safe ways to store database credentials"
  - "What .pgpass file does and when to use it"
  - "Environment variables for database connections"

#### Part 2: Testing Your Connections (1.5 hours)

**Guiding questions about YOUR specific connections:**

1. **What users exist in your database?**
   - How many database users do you have?
   - What can each one do?
   - Which one do your scripts use?
   - Which one do YOU use for administration?

2. **Can you connect as different users?**
   - Can you connect as yourself?
   - Can you connect as a service account (if you have one)?
   - What's the difference in what you can see/do?

3. **What happens when connection fails?**
   - Try connecting with a wrong password
   - Try connecting to wrong host
   - Try connecting to wrong port
   - For each, what's the error message?
   - How would you troubleshoot each?

**Hands-on assignment:**
- Create a simple test script in Python:
  ```python
  import psycopg2
  
  connection_params = {
      'host': 'localhost',  # Your host
      'database': 'russianorbatukraine',
      'user': 'your_username',
      'password': '***',  # Your password
  }
  
  try:
      conn = psycopg2.connect(**connection_params)
      print("Connected successfully!")
      conn.close()
  except Exception as e:
      print(f"Connection failed: {e}")
  ```
- Test it with correct credentials (should succeed)
- Test with wrong password (what error?)
- Test with wrong host (what error?)
- Document each error: what it means, how to fix it

**Document in Connection Runbook:**
- "How to test if my database connection works"
- "What these common errors mean and how to fix them"
- "Three ways to pass credentials to Python scripts"
- "Why NOT to put passwords in code"

#### Part 3: Connection Runbook Creation (1 hour)

**Create your Connection Management Runbook:**

```markdown
# Connection Management Runbook

## Overview
[Brief explanation of your database setup]

## Server Information
- Server name/host: [your info]
- Port: [your port, usually 5432]
- Database instance: [your database name]
- PostGIS enabled: [yes/no]

## Connection Methods

### Method 1: Command Line (psql)
**When to use:** Quick queries, testing, administration
**How to connect:** [Your specific command]
**What it looks like when successful:** [Example output]
**Common issues:** [Errors you've seen]

### Method 2: Python
**When to use:** Automation, scripts
**Libraries needed:** [psycopg2 or similar]
**How to connect:** [Your specific code]
**Example test script:** [Simple working example]

### Method 3: [Other tools you use]
...

## Database Users
| Username | Purpose | Can Connect? |
|----------|---------|-------------|
| [user1] | [scripts/admin/data analyst] | [yes/no] |
| [user2] | [scripts/admin/data analyst] | [yes/no] |

## Credential Storage
- Where credentials are stored: [your location]
- How to access them safely: [your method]
- Who has access: [who should know?]
- Security considerations: [important warnings]

## Troubleshooting Connection Problems

### Error: "Connection refused"
- Means: [what this indicates]
- Check: [what to verify]
- Fix: [how to resolve]

### Error: "Password authentication failed"
- Means: [what this indicates]
- Check: [what to verify]
- Fix: [how to resolve]

### Error: [Other common errors from your experience]
...

## Testing Your Connection
[Your test script or command to verify connection works]

## Last Updated
[Date]
```

### Friday Session: Review & Week 2 Wrap-up (2 hours)

**What you accomplished:**
- [ ] Understand PostgreSQL server architecture
- [ ] Mapped your database structure (schemas, tables)
- [ ] Tested connections in multiple ways
- [ ] Created security-conscious connection runbook
- [ ] Added 10+ entries to Concept Library

**Update Progress_Week_02.md:**
1. Time log (actual hours spent)
2. What you understand about PostgreSQL now
3. What's still confusing
4. Connection runbook: complete? comprehensive?
5. Next week preview

**Deliverable status:**
- [ ] Connection Management Runbook (complete)
- [ ] Concept Library entries (10+)
- [ ] All files committed to Git

---

## Week 3: Users, Roles, and Permissions

**Dates:** December 1-5, 2025  
**Total Hours:** 15 hours  
**Primary Goal:** Understand who can access what and how to control it  
**Deliverable:** Permissions Audit Document  

### Learning Objectives

By the end of Week 3, you should be able to answer:
1. What is a role and how does it differ from a user?
2. What permissions (GRANT/REVOKE) exist in PostgreSQL?
3. What does your current user setup look like?
4. How would you add a new user safely?
5. How would you restrict access to sensitive tables?

### Why This Matters

Your Russian ORBAT database contains sensitive intelligence data. Understanding permissions means you can:
- Ensure only authorized users can access data
- Prevent accidental damage (read-only vs. read-write access)
- Support team members with appropriate access levels
- Audit who did what when
- Recover from mistakes without exposing data

### Tuesday Session (3-4 hours): Understanding Roles & Permissions

**Session Theme:** "Who can do what in your database?"

#### Part 1: Roles vs Users (1 hour)

**Guiding questions:**

1. **What is a role?**
   - Is it the same as a user?
   - What can a role do that a user can't?
   - Can you have roles that aren't users?

2. **What roles exist in your database?**
   - List all roles: how many?
   - Which are users (can log in)?
   - Which are group roles (manage permissions)?

3. **Hierarchy and inheritance:**
   - Can a role be a member of another role?
   - If so, what does the member inherit?
   - How does this help manage permissions?

**Research assignment:**
- PostgreSQL docs: "Database Roles"
- Read about: Creating roles, Predefined roles, Role Attributes
- Hands-on: List your roles
  ```sql
  SELECT rolname, rolcanlogin FROM pg_roles;
  ```
- For each, note: can login? member of what?

**Document in Concept Library:**
- "Difference between role and user"
- "What role inheritance means"
- "Three roles that exist in my database and their purposes"

#### Part 2: PostgreSQL Permissions (GRANT/REVOKE) (1.5 hours)

**Guiding questions:**

1. **What can you grant or revoke?**
   - Permissions on databases? (yes, but rarely needed)
   - Permissions on schemas? (yes, important)
   - Permissions on tables? (yes, very important)
   - Permissions on columns? (yes, granular control)

2. **What are the permission types?**
   - SELECT: can read data
   - INSERT: can add data
   - UPDATE: can modify data
   - DELETE: can remove data
   - EXECUTE: can call functions
   - USAGE: can access a schema
   - Others?

3. **What does "public" schema access mean?**
   - What's the default? Can anyone access everything?
   - Is that a problem in your database?
   - How would you restrict it?

**Hands-on exploration:**
- Pick a table (maybe `orbat.units`)
- Find its current permissions:
  ```sql
  SELECT grantee, privilege_type 
  FROM information_schema.role_table_grants 
  WHERE table_name = 'units' AND table_schema = 'orbat';
  ```
- For each permission, ask: why does this user have this permission?
- Try creating a test scenario:
  ```sql
  -- Create a test role (don't do this in production!)
  CREATE ROLE test_reader LOGIN;
  
  -- Grant it permission to read a table
  GRANT SELECT ON orbat.units TO test_reader;
  
  -- Try connecting as that user—what can you see? Can you modify?
  ```

**Document:**
- "What GRANT and REVOKE do"
- "The five main permission types"
- "Current permissions on [table name] and why they exist"

#### Part 3: Your Current Permission Setup (1.5 hours)

**Guiding questions about YOUR database:**

1. **Who has access to your database?**
   - How many users can connect?
   - For each, what can they do?
   - Is this intentional or happened by accident?

2. **What's the schema access like?**
   - Can users see all schemas?
   - Are some schemas restricted?
   - Should they be?

3. **Data sensitivity:**
   - Is some data more sensitive than other data?
   - Should all users access all tables?
   - What would happen if you accidentally gave write access to everyone?

**Audit assignment:**
- Create a permissions matrix:
  ```
  User             | Can Connect? | Can See orbat Schema? | Can Write? | Can Execute Functions?
  [user1]          | [yes/no]     | [yes/no]              | [yes/no]   | [yes/no]
  [user2]          | ...
  ```
- For each user, trace their permissions
- Try this query:
  ```sql
  SELECT 
      grantee,
      privilege_type,
      table_schema,
      table_name
  FROM information_schema.role_table_grants
  WHERE table_schema IN ('orbat', 'maid', 'facilities')
  ORDER BY grantee, table_schema, table_name;
  ```
- Review the output: does this make sense? Are there surprises?

**Document:**
- "Current user and permission setup"
- "Who can do what in my database"
- "Potential security concerns"

### Wednesday Session (3-4 hours): Safe User Management

**Session Theme:** "How to add users without breaking anything"

#### Part 1: Creating Users Safely (1.5 hours)

**Guiding questions:**

1. **What makes a good database user?**
   - Does every person need their own user? (vs. shared account)
   - Should users have strong passwords?
   - Should users have password expiration?
   - Should you limit what they can do?

2. **What's the principle of least privilege?**
   - Give users only what they NEED, not what you COULD give them
   - Why is this important?
   - How do you implement it?

3. **How would you create a new user?**
   - Create the role
   - Set a password
   - Give appropriate permissions
   - What could go wrong at each step?

**Hands-on exercise (in test environment if possible):**
- Create a test scenario:
  ```sql
  -- Create a new user who can ONLY read from orbat.units
  CREATE ROLE analyst LOGIN PASSWORD 'test_password';
  GRANT USAGE ON SCHEMA orbat TO analyst;
  GRANT SELECT ON orbat.units TO analyst;
  
  -- What can they NOT do?
  -- Can they see other tables? SELECT orbat.positions?
  -- Can they modify data? UPDATE orbat.units?
  -- Can they create tables? DROP anything?
  ```
- Test each permission—what works and what fails?
- Document your findings

**Document:**
- "Steps to safely create a new database user"
- "Permissions I should grant by default"
- "Security checklist before giving someone database access"

#### Part 2: Function Permissions & Schema Access (1.5 hours)

**Guiding questions:**

1. **What about function execution?**
   - Your database has custom functions (in the `functions` schema)
   - Should all users be able to call them?
   - What functions exist and what do they do?
   - Who should be able to call them?

2. **How does schema access work?**
   - If you grant USAGE on a schema, what can the user do?
   - Do they automatically see all tables?
   - Do they automatically have permission to read/write?
   - What's the relationship between schema permission and table permission?

3. **What about public schema?**
   - Some databases put public data in `public` schema
   - Some restrict it heavily
   - What's best practice?

**Hands-on exploration:**
- Look at your functions schema:
  ```sql
  SELECT routine_name FROM information_schema.routines 
  WHERE routine_schema = 'functions';
  ```
- Pick one function—what does it do?
- Who should be able to call it?
- Grant appropriate permissions
- Document the reasoning

**Document:**
- "What functions exist in my database"
- "Who should have permission to execute them"
- "How to grant schema vs. table permissions"

### Thursday Session (3-4 hours): Permissions Audit & Documentation

**Session Theme:** "Documenting your permissions so you remember why you did this"

#### Part 1: Comprehensive Permissions Audit (2 hours)

**Create a complete picture of who can do what:**

**Audit script (or use your query tool):**
```sql
-- All users and their attributes
SELECT rolname, rolcanlogin, rolsuper FROM pg_roles;

-- Schema access
SELECT grantee, privilege_type, table_schema
FROM information_schema.role_table_grants
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY grantee, privilege_type, table_schema;

-- Table-level permissions
SELECT grantee, privilege_type, table_schema, table_name
FROM information_schema.role_table_grants
WHERE table_schema IN ('orbat', 'maid', 'facilities')
ORDER BY grantee, table_schema, table_name;
```

**For each result:**
1. Write it down
2. Ask: is this intentional?
3. Ask: should it be this way?
4. Note any surprises

#### Part 2: Create Permissions Audit Document (1.5 hours)

**Document your findings:**

```markdown
# Permissions Audit Report

**Date:** [Today]
**Database:** russianorbatukraine
**Auditor:** [Your name]

## Executive Summary
[Brief overview: how many users? What's the permission model?]

## All Database Users

| Username | Can Login | Role | Purpose | Last Check |
|----------|-----------|------|---------|-----------|
| [user1] | Yes/No | [what role] | [scripts/admin/etc] | [date] |
| [user2] | ... | ... | ... | ... |

## Schema Access

| Schema | User | Permission | Notes |
|--------|------|-----------|-------|
| orbat | [user] | USAGE | Can see/access tables |
| orbat | [user] | - | Cannot access |

## Table-Level Permissions

### orbat.units (Critical Operations Table)
| User | SELECT | INSERT | UPDATE | DELETE | Notes |
|------|--------|--------|--------|--------|-------|
| [user] | ✓ | ✗ | ✗ | ✗ | Read-only |

### orbat.positions (Operational Data)
| User | SELECT | INSERT | UPDATE | DELETE | Notes |
|------|--------|--------|--------|--------|-------|
| [user] | ✓ | ✓ | ✓ | ✗ | Can add/update but not delete |

### orbat.mentions (Critical)
[Same structure for other tables]

## Function Access

| Function | Purpose | Users with Access | Notes |
|----------|---------|-------------------|-------|
| [function1] | [what it does] | [who can call it] | [purpose] |

## Sensitive Data Access

**Critical tables (should restrict access):**
- [Table name]: Currently accessible to [who?]

**Concern:** [Is this a security issue? Why/why not?]

## Audit Findings

### ✓ What's Good
- [Something working well]
- [Another good practice]

### ⚠ What Needs Attention
- [Potential issue]
- [Security concern?]
- [Accidental permission?]

### 🔧 Recommendations
- [If you were setting this up fresh, what would you do differently?]
- [Any permissions you should add?]
- [Any permissions you should remove?]

## Next Steps
[What should happen with these findings?]
```

### Friday Session: Review & Week 3 Wrap-up (2 hours)

**Completed:**
- [ ] Understand role vs user distinction
- [ ] Know all permission types (SELECT, INSERT, UPDATE, DELETE, USAGE, EXECUTE)
- [ ] Complete permissions audit of your database
- [ ] Create safe user management procedures
- [ ] Document recommendations for permission improvements

**Update Progress_Week_03.md**

**Deliverable:**
- [ ] Permissions Audit Document (complete)
- [ ] Concept Library additions
- [ ] Commit to Git

---

## Week 4: Backup Strategy & Disaster Recovery

**Dates:** December 8-12, 2025  
**Total Hours:** 15 hours  
**Primary Goal:** Know how to protect your data and recover if disaster strikes  
**Deliverable:** Backup & Recovery Procedures Document  

### Learning Objectives

By end of Week 4, you should be able to answer:
1. What does a "backup" actually mean in PostgreSQL?
2. What backup strategies exist (full dump? WAL archiving? point-in-time recovery)?
3. How often should you back up?
4. How do you test that backups work?
5. Could you restore your database if the current one crashed?

### Why This Matters

A backup that doesn't work is worse than no backup—it gives false confidence. By the end of this week, you'll understand:
- How to create backups your team can trust
- How to test them
- How to recover if something goes wrong
- How long recovery takes (and what that means for your work)

### Tuesday Session (3-4 hours): PostgreSQL Backup Concepts

**Session Theme:** "What does 'backup' mean and why does it matter?"

#### Part 1: Types of Backups (1 hour)

**Guiding questions:**

1. **What are the main backup approaches?**
   - Logical backup (pg_dump): dumps SQL commands
   - Physical backup (file-based): copies the data files
   - Combined (logical + WAL): dump + recovery logs
   - Which is best? (Depends!)

2. **What's the difference between full and incremental?**
   - Full backup: entire database
   - Incremental: only what changed since last backup
   - Which does PostgreSQL do natively?

3. **What is WAL and why should you care?**
   - WAL = Write-Ahead Logging
   - Every change is logged
   - You can use WAL to recover to a specific point in time
   - When would you need this?

**Research assignment:**
- PostgreSQL docs: "Backup and Restore"
- Read: "Overview"
- Read: "SQL Dump" section
- Read: "File System Level Backup" section (may be advanced—that's okay)
- Read: "Continuous Archiving and Point-in-Time Recovery (PITR)"

**Document in Concept Library:**
- "Logical backup vs physical backup"
- "What WAL (Write-Ahead Log) is and why it matters"
- "pg_dump: what it does and when to use it"

#### Part 2: Your Backup Situation (1.5 hours)

**Guiding questions:**

1. **Do you currently have backups?**
   - How often?
   - Where are they stored?
   - Who maintains them?
   - How do you know they're working?

2. **What's your recovery objective?**
   - If the database crashes tomorrow, how long can you be without it?
   - Is 1 hour acceptable? 1 day? Not at all?
   - How much recent data could you afford to lose?

3. **What would you back up?**
   - Just the data tables?
   - Also the schema (table definitions)?
   - Also the custom functions?
   - Also the permissions setup?

**Reflection exercise:**
- Write down: "If my Russian ORBAT database crashed today, I would..."
- What's the impact?
- What would you need to restore?
- How quickly?

**Research + hands-on:**
- If you have backup system, explore it:
  - Where are backups stored?
  - How often do they run?
  - How large are they?
  - How old is the most recent one?
- If you don't have one, that's important to know

**Document:**
- "Current backup status of my database"
- "What I would lose if the database crashed today"
- "Recovery time objective (how quickly I need to be back online)"

#### Part 3: Creating Your First Backup (1 hour)

**Hands-on: Create a logical backup**

**Using pg_dump (if you have command-line access):**
```bash
# Backup entire database
pg_dump -h localhost -U your_user -d russianorbatukraine > backup.sql

# Or with a bit more detail
pg_dump -h localhost -U your_user -d russianorbatukraine \
  --verbose --format=plain > backup_detailed.sql
```

**Using Python (if you prefer):**
```python
import subprocess
import datetime

timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
backup_file = f"orbat_backup_{timestamp}.sql"

cmd = [
    'pg_dump',
    '-h', 'localhost',
    '-U', 'your_user',
    '-d', 'russianorbatukraine',
    '-f', backup_file,
    '--verbose'
]

try:
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    print(f"Backup created: {backup_file}")
    print(f"Size: {os.path.getsize(backup_file)} bytes")
except subprocess.CalledProcessError as e:
    print(f"Backup failed: {e}")
```

**Document your experience:**
- How long did it take?
- How large is the file?
- What's in it? (Open it and look at a few lines)
- Could you restore from this? (Try! But on a test database)

### Wednesday Session (3-4 hours): Backup Procedures & Testing

**Session Theme:** "Making backup routine and trustworthy"

#### Part 1: Designing Your Backup Strategy (1.5 hours)

**Guiding questions:**

1. **What's a reasonable backup schedule?**
   - Daily? Weekly? Monthly?
   - Should it be automated or manual?
   - What time of day? (During low activity?)

2. **Where should backups be stored?**
   - Same server? (Bad—if server fails, backup fails)
   - Different location? (Better—cloud? external drive?)
   - How many copies?
   - How long to keep?

3. **What should be included?**
   - Full database dump?
   - Just data (not schema)?
   - Compressed?
   - Encrypted?

**Design exercise:**
Create your backup strategy plan:
```markdown
## My Backup Strategy

**Frequency:** [daily/weekly/etc.]
**Schedule:** [when—day/time]
**Type:** Full database dump using pg_dump
**Storage location:** [where—local/cloud/external]
**Retention:** [how many backups to keep—e.g., last 30 days]
**Automation:** [manual/cron/other scheduling]
**Testing:** [when do you restore and verify?]
**Documentation:** [where do you document this?]
**Owner:** [who's responsible for backups?]
```

**Document:**
- "Backup strategy I'm implementing"
- "Why this approach for my situation"
- "What it does and doesn't protect against"

#### Part 2: Backup Automation (1.5 hours)

**Guiding questions:**

1. **Should backups be automated?**
   - Manual backups: you remember to do them (risky)
   - Automated: script runs on schedule (better)
   - How do you automate on your system?

2. **What's a good backup script?**
   - Creates timestamped backup file
   - Logs success/failure
   - Cleans up old backups
   - Emails you if it fails
   - Verifies backup integrity

**Create a backup script (Python or bash):**

```python
#!/usr/bin/env python3
"""
Automated backup script for Russian ORBAT database
Run this daily via cron or Windows Task Scheduler
"""

import subprocess
import os
import datetime
import logging
from pathlib import Path

# Configuration
DB_NAME = "russianorbatukraine"
DB_USER = "your_user"
DB_HOST = "localhost"
BACKUP_DIR = Path("/backups/orbat")  # Change this
RETENTION_DAYS = 30  # Keep 30 days of backups

# Set up logging
logging.basicConfig(
    filename=BACKUP_DIR / "backup.log",
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def backup_database():
    """Create a database backup"""
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = BACKUP_DIR / f"orbat_{timestamp}.sql"
    
    cmd = [
        'pg_dump',
        '-h', DB_HOST,
        '-U', DB_USER,
        '-d', DB_NAME,
        '-f', str(backup_file),
        '--verbose'
    ]
    
    try:
        logging.info(f"Starting backup: {backup_file}")
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        
        file_size = backup_file.stat().st_size
        logging.info(f"Backup completed successfully. Size: {file_size} bytes")
        return True
        
    except subprocess.CalledProcessError as e:
        logging.error(f"Backup failed: {e}")
        return False

def cleanup_old_backups():
    """Remove backups older than RETENTION_DAYS"""
    cutoff = datetime.datetime.now() - datetime.timedelta(days=RETENTION_DAYS)
    
    for backup_file in BACKUP_DIR.glob("orbat_*.sql"):
        mtime = datetime.datetime.fromtimestamp(backup_file.stat().st_mtime)
        if mtime < cutoff:
            try:
                backup_file.unlink()
                logging.info(f"Deleted old backup: {backup_file}")
            except Exception as e:
                logging.warning(f"Could not delete {backup_file}: {e}")

if __name__ == "__main__":
    if not BACKUP_DIR.exists():
        BACKUP_DIR.mkdir(parents=True)
    
    success = backup_database()
    cleanup_old_backups()
    
    exit(0 if success else 1)
```

**To schedule it:**
- On Linux/Mac: add to crontab `0 2 * * * /path/to/backup.py`
- On Windows: use Task Scheduler
- Document how you set it up

### Thursday Session (3-4 hours): Recovery Testing & Documentation

**Session Theme:** "Your backup is only good if recovery works"

#### Part 1: Testing Recovery (2 hours)

**The critical test:**

**Can you actually restore from your backup?**

1. **Create a test scenario:**
   - Create a test database (not your production one!)
   - "Delete" some data from production
   - Restore from backup
   - Verify data is back

2. **Hands-on test (if safe to do):**
   ```sql
   -- In a test environment:
   -- Create an empty test database
   CREATE DATABASE orbat_test;
   
   -- Restore from your backup
   psql -h localhost -U your_user -d orbat_test < backup.sql
   
   -- Verify tables are there
   \dt orbat.*
   
   -- Verify data count matches (approximately)
   SELECT COUNT(*) FROM orbat.units;
   ```

3. **Document:**
   - How long did recovery take?
   - Did everything work?
   - What surprised you?
   - Could you restore to a different server?

#### Part 2: Point-in-Time Recovery (PITR) Concepts (1 hour)

**Guiding questions:**

1. **What is PITR?**
   - Recover the database to any point in time (not just to last backup)
   - Requires base backup + WAL files
   - More complex but very powerful

2. **Do you need it?**
   - If you accidentally delete data, can you recover it with pg_dump backups? (No—backups are point-in-time)
   - Would PITR help your situation?
   - What would it cost (storage, complexity)?

3. **PostgreSQL WAL basics:**
   - Every transaction is logged to WAL
   - WAL files accumulate
   - You can archive them and use them for recovery
   - How would you set this up?

**Research:**
- PostgreSQL docs: "Continuous Archiving"
- This is advanced—understand the concepts, not necessarily implementation yet

**Document:**
- "What PITR is and whether I need it"
- "Trade-offs: more protection vs. complexity/cost"

#### Part 3: Backup & Recovery Runbook (1 hour)

**Create your documentation:**

```markdown
# Backup & Recovery Procedures

## Backup Strategy

**Frequency:** [how often]
**Type:** Logical backup using pg_dump
**Storage:** [where]
**Retention:** [how many kept]
**Owner:** [who's responsible]

## Current Backup Status

**Last backup:** [when]
**Last verified:** [when]
**Location:** [path/link]

## How to Create a Manual Backup

```bash
pg_dump -h localhost -U your_user \
  -d russianorbatukraine > backup_$(date +%Y%m%d).sql
```

## How to Restore from Backup

**Prerequisites:**
- Have backup file
- Have access to PostgreSQL
- Target database (may need to create)

**Steps:**
1. Create test database: `CREATE DATABASE test_restore;`
2. Restore: `psql -d test_restore < backup_file.sql`
3. Verify: `SELECT COUNT(*) FROM orbat.units;` (compare with expected)

**Time estimate:** [X minutes for full restore]
**Verification:** [How to confirm restoration was successful]

## Emergency Recovery Procedure

**If production database is inaccessible:**
1. [First steps]
2. [Create test database]
3. [Restore from most recent backup]
4. [Verify all critical data is present]
5. [Failover/switch if needed]

**Estimated time to recovery:** [X minutes]
**Data loss window:** [Last backup was X hours ago—could lose up to X hours of changes]

## Testing Schedule

**When:** [how often]
**How:** [procedure]
**Who:** [who verifies]
**Documentation:** [where you record test results]

**Last test:** [date]
**Next test:** [date]
**Test result:** [success/failure/issues]
```

### Friday Session: Review & Week 4 Wrap-up (2 hours)

**Completed:**
- [ ] Understand backup types (logical, physical, PITR)
- [ ] Create initial backup of your database
- [ ] Design backup strategy for your situation
- [ ] Create/configure backup automation script
- [ ] Test restoration (or understand how you would)
- [ ] Create Backup & Recovery Runbook

**Update Progress_Week_04.md**

**Deliverable:**
- [ ] Backup & Recovery Procedures Document
- [ ] Working backup script
- [ ] Concept Library additions
- [ ] All committed to Git

---

## Week 5: Schema Modification & Safe Changes

**Dates:** December 15-19, 2025  
**Total Hours:** 15 hours  
**Primary Goal:** Understand how to safely change database structure  
**Deliverable:** Schema Change Procedures Document  

### Learning Objectives

By end of Week 5, you should be able to answer:
1. What is a migration and why do you need one?
2. What are constraints and why do they prevent changes?
3. How do you add a column safely?
4. How do you change a column type without losing data?
5. What could go wrong and how do you prevent it?

### Why This Matters

Your database structure isn't fixed—it evolves as your needs change. Knowing how to modify the schema safely means:
- You can add new features without breaking existing ones
- You understand why some changes are risky
- You can help team members understand why "just adding a column" might take planning
- You can recover if a schema change breaks something

### Tuesday Session (3-4 hours): Understanding Constraints & Relationships

**Session Theme:** "Why can't I just change things in the database?"

#### Part 1: Table Constraints (1.5 hours)

**Guiding questions:**

1. **What are the five main constraint types?**
   - PRIMARY KEY: unique identifier for each row
   - FOREIGN KEY: links to another table
   - UNIQUE: no duplicate values
   - NOT NULL: must have a value
   - CHECK: value must pass a condition
   - Which one prevents you from doing what you want?

2. **What's the business reason for constraints?**
   - Why would you make a column NOT NULL?
   - Why link tables with FOREIGN KEY?
   - Why UNIQUE on certain columns?
   - Each constraint prevents bad data—what bad data?

3. **How do constraints affect schema changes?**
   - If you have a FOREIGN KEY constraint, can you delete the referenced table?
   - Can you change its type?
   - What's the error message?

**Hands-on exploration (test environment):**
- Look at your constraints:
  ```sql
  SELECT constraint_name, constraint_type
  FROM information_schema.table_constraints
  WHERE table_schema = 'orbat';
  ```
- For each table (maybe orbat.units and orbat.mentions):
  - What constraints exist?
  - Why do they exist?
  - What would happen if you tried to violate them?

**Document in Concept Library:**
- "Five constraint types and why each one matters"
- "Example constraints from orbat.units and what they prevent"

#### Part 2: Foreign Keys & Referential Integrity (1.5 hours)

**Guiding questions:**

1. **What is a foreign key relationship?**
   - Table A references Table B
   - When you insert/update/delete in A, what happens in B?
   - What's "referential integrity"?

2. **What are cascade options?**
   - ON DELETE CASCADE: if parent deleted, child also deleted
   - ON DELETE RESTRICT: can't delete parent if children exist
   - ON DELETE SET NULL: child's foreign key becomes NULL
   - When would you use each?

3. **How do you find foreign keys?**
   - Which tables reference which?
   - Could you draw a diagram of relationships?
   - Which foreign keys might affect your schema changes?

**Hands-on exploration:**
- Find all foreign keys in orbat schema:
  ```sql
  SELECT constraint_name, table_name, column_name, 
         referenced_table_name, referenced_column_name
  FROM information_schema.referential_constraints
  WHERE constraint_schema = 'orbat';
  ```
- For each one, understand:
  - Why does this relationship exist?
  - What happens if parent is deleted?
  - How would this affect schema changes?

**Document:**
- "Foreign key relationships in my database"
- "Which tables are parents vs. children"
- "How cascade options work (with examples)"

### Wednesday Session (3-4 hours): Safe Schema Modifications

**Session Theme:** "How to add/change columns without breaking things"

#### Part 1: Adding Columns Safely (1.5 hours)

**Guiding questions:**

1. **Why is adding a column risky?**
   - If the table has 10 million rows, how long does it take?
   - Does it lock the table (so nobody can use it)?
   - What if you make a mistake?

2. **What are the safest approaches?**
   - Add column with DEFAULT value (easier)
   - Add column with NOT NULL (requires default or UPDATE)
   - Add nullable column (safest—can update later)
   - Can you backfill data while table is in use?

3. **What should you plan before adding a column?**
   - What will go in this column?
   - Can it be NULL?
   - Does it default to something?
   - Will you need to backfill existing rows?
   - How long will the change take?

**Hands-on scenario:**

Imagine you need to add a "last_updated" timestamp to orbat.units.

Plan it:
```sql
-- Step 1: Add nullable column (fast)
ALTER TABLE orbat.units 
ADD COLUMN last_updated timestamp NULL;

-- Step 2: Backfill with current time (may take a while)
UPDATE orbat.units 
SET last_updated = NOW()
WHERE last_updated IS NULL;

-- Step 3: Make NOT NULL (now safe because all rows have values)
ALTER TABLE orbat.units 
ALTER COLUMN last_updated SET NOT NULL;

-- Step 4: Add DEFAULT for future inserts
ALTER TABLE orbat.units 
ALTER COLUMN last_updated SET DEFAULT NOW();
```

For each step, ask:
- How long will it take?
- Will it lock the table?
- Can users still query while it's happening?
- What if it fails?

#### Part 2: Changing Column Types (1.5 hours)

**Guiding questions:**

1. **Why is changing column type risky?**
   - Existing data must convert to new type
   - What if existing data can't convert?
   - Could you lose data?

2. **What's the safest way?**
   - Option A: Direct cast (fast but risky if data doesn't fit type)
   - Option B: Create new column, backfill, swap columns (slower but safer)
   - When would you use each?

3. **What conversions are safe?**
   - integer → varchar (always works, becomes "123")
   - varchar → integer (only if all values are numeric—risky!)
   - integer → smallint (risky if values outside range)
   - What would you do to be sure it's safe?

**Scenario: Imagine a column is currently varchar but should be integer**

Safe approach:
```sql
-- Step 1: Check if all values can convert
SELECT COUNT(*) FROM orbat.units 
WHERE NOT (unit_id::text ~ '^[0-9]+$');
-- If this is > 0, you have non-numeric values!

-- Step 2: Create new column with new type
ALTER TABLE orbat.units 
ADD COLUMN unit_id_new integer;

-- Step 3: Backfill (with testing first!)
UPDATE orbat.units 
SET unit_id_new = unit_id::integer;

-- Step 4: Verify counts match
SELECT COUNT(*) FROM orbat.units WHERE unit_id_new IS NULL;

-- Step 5: If good, drop old column and rename
ALTER TABLE orbat.units DROP COLUMN unit_id;
ALTER TABLE orbat.units RENAME COLUMN unit_id_new TO unit_id;
```

Document your approach.

### Thursday Session (3-4 hours): Migration Planning & Documentation

**Session Theme:** "Before you change anything, write it down"

#### Part 1: Migration Planning (1.5 hours)

**Guiding questions:**

1. **What's a migration?**
   - A set of ordered steps to change the database
   - Usually reversible (can undo)
   - Documented so anyone can apply it
   - Tracked in version control

2. **What should a migration include?**
   - What's changing (schema alteration)
   - Why it's changing (business reason)
   - Expected duration and impact
   - Rollback procedure (how to undo)
   - Testing that it worked
   - Date and who applied it

3. **How do you minimize downtime?**
   - Some changes lock the table
   - Can you do them during low-traffic times?
   - Can you do them in steps so table is only locked briefly?
   - What's acceptable downtime for your database?

**Create a migration template:**
```markdown
# Migration: [What is this changing?]

**Date:** [when do you plan to apply?]
**Impact:** [which tables/users affected?]
**Estimated downtime:** [how long?]
**Risk level:** [low/medium/high—why?]

## Description
[What are you changing and why?]

## Migration Steps
1. [First step—SQL command]
2. [Second step]
3. [Verification step]

## Rollback Procedure
[How to undo if something goes wrong]

## Testing
- [How you'll verify it worked]
- [What you'll check]
- [Expected results]

## Approval
- Reviewed by: [who approved?]
- Approved on: [date]
```

#### Part 2: Schema Change Runbook (1.5 hours)

**Document your procedures:**

```markdown
# Schema Change Procedures

## Before Making Any Schema Change

**Checklist:**
- [ ] Backup exists and has been tested
- [ ] Change has been planned in migration template
- [ ] Impact analyzed (which tables? how long?)
- [ ] Rollback procedure written
- [ ] Timing OK (during maintenance window? low traffic?)
- [ ] Got approval (if needed)

## Common Schema Changes

### Adding a Column
[Step-by-step procedure with timing estimates]

### Removing a Column
[Consider dependencies first—could break code that uses it!]

### Changing Column Type
[Safe procedure with rollback plan]

### Adding a Constraint
[What could go wrong? How to handle existing data?]

### Renaming a Table or Column
[Potential impact on scripts that use old name]

## Applying a Migration

1. [Verify backup exists]
2. [Notify team of maintenance window]
3. [Execute migration steps]
4. [Verify success]
5. [Test rollback procedure (optional)]
6. [Document what happened]

## Testing Migrations

**Before applying to production:**
1. Apply to test database (restore from recent backup)
2. Verify change worked as expected
3. Run any scripts that use affected tables
4. Test rollback procedure

## Emergency Rollback

[What to do if migration breaks something]
```

### Friday Session: Review & Week 5 Wrap-up (2 hours)

**Completed:**
- [ ] Understand constraints (PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, CHECK)
- [ ] Understand foreign key relationships in your database
- [ ] Know safe procedures for adding columns
- [ ] Know safe procedures for changing column types
- [ ] Create migration template
- [ ] Create Schema Change Procedures runbook

**Update Progress_Week_05.md**

**Deliverable:**
- [ ] Schema Change Procedures Document
- [ ] Migration template example
- [ ] Concept Library additions
- [ ] All committed to Git

---

## Week 6: Query Optimization & PostgreSQL Diagnostics

**Dates:** December 22-26, 2025  
**Total Hours:** 15 hours  
**Primary Goal:** Understand why queries are slow and how to fix them  
**Deliverable:** Database Optimization & Diagnostics Guide  

### Learning Objectives

By end of Week 6, you should be able to answer:
1. What does an EXPLAIN plan show?
2. How do you read EXPLAIN output?
3. What are the most common performance problems?
4. When do you need an index?
5. How do you find slow queries?
6. What do PostgreSQL logs tell you?

### Why This Matters

A slow database makes everything slow. Understanding query performance means:
- You can identify which queries are problems
- You understand why they're slow
- You can fix them (add indexes, rewrite query, etc.)
- You can monitor the database proactively
- You can help team members write faster queries

### Tuesday Session (3-4 hours): EXPLAIN and Query Plans

**Session Theme:** "Why is my query slow and how do I know?"

#### Part 1: EXPLAIN Basics (1.5 hours)

**Guiding questions:**

1. **What does EXPLAIN do?**
   - Shows the plan PostgreSQL will use to execute the query
   - Doesn't actually run the query
   - Shows estimated costs
   - Let's you see what operations it's doing

2. **What's different about EXPLAIN vs. EXPLAIN ANALYZE?**
   - EXPLAIN: estimated plan (fast)
   - EXPLAIN ANALYZE: actual plan + execution (runs the query)
   - ANALYZE adds real timing and actual row counts
   - When would you use each?

3. **What information is in the plan?**
   - Node types (Seq Scan, Index Scan, Hash Join, etc.)
   - Cost (startup cost .. total cost)
   - Rows (estimated vs. actual with ANALYZE)
   - Time (only with ANALYZE)

**Hands-on learning:**

Start simple:
```sql
-- Simple EXPLAIN
EXPLAIN SELECT * FROM orbat.units WHERE unit_id = 1;

-- With ANALYZE (actually runs the query)
EXPLAIN ANALYZE SELECT * FROM orbat.units WHERE unit_id = 1;
```

Read the output:
- What's the first operation?
- Is it using an index or scanning the table?
- What's the estimated cost?
- If you added ANALYZE, what's the actual time?

**Comparative analysis:**
```sql
-- Without index
EXPLAIN ANALYZE SELECT * FROM orbat.units WHERE unit_name = 'Example';

-- Compare with another query
EXPLAIN ANALYZE SELECT * FROM orbat.positions WHERE unit_id = 1;
```

For each:
- What operations is PostgreSQL using?
- How many rows does it need to check?
- How long does it take?
- Is it efficient or wasteful?

**Document in Concept Library:**
- "EXPLAIN output components"
- "Seq Scan vs. Index Scan (when does PostgreSQL use each?)"
- "Query costs and what they mean"

#### Part 2: Common Query Plan Problems (1.5 hours)

**Guiding questions:**

1. **What's a "Seq Scan" and why is it sometimes bad?**
   - Scans entire table (checks every row)
   - Slow for large tables
   - But necessary if no index matches
   - Fast for small tables or filtering out most rows

2. **When is an index helpful?**
   - Looking up by value (WHERE id = 5)
   - Range queries (WHERE created_at > '2025-01-01')
   - Sorting (ORDER BY)
   - Not helpful if query returns most rows anyway

3. **What's a "Hash Join" vs. "Nested Loop" vs. "Merge Join"?**
   - Different ways to join tables
   - Trade-offs in speed
   - Which one is fastest depends on query and data
   - EXPLAIN tells you which one PostgreSQL chose

**Analysis scenarios:**

Collect some real queries from your work:
```sql
-- Slow position update query
EXPLAIN ANALYZE SELECT u.unit_id, u.unit_name, p.latitude, p.longitude
FROM orbat.units u
LEFT JOIN orbat.positions p ON u.unit_id = p.unit_id
WHERE p.created_at > NOW() - INTERVAL '7 days';

-- Another query
EXPLAIN ANALYZE SELECT m.unit_id, COUNT(*) as mention_count
FROM orbat.mentions m
GROUP BY m.unit_id
ORDER BY mention_count DESC;
```

For each:
- What's the slowest operation?
- Is it using indexes?
- What rows is it working with?
- Could an index help?
- Could the query be rewritten to be faster?

**Document:**
- "Analysis of 2-3 real slow queries"
- "What's causing each one to be slow"
- "Ideas for fixing them (don't implement yet)"

### Wednesday Session (3-4 hours): Indexes and Query Tuning

**Session Theme:** "How to make queries faster"

#### Part 1: Understanding Indexes (1.5 hours)

**Guiding questions:**

1. **What is an index and how does it work?**
   - Sorted copy of column data (simplified view)
   - Lets PostgreSQL find rows without scanning entire table
   - Like book's index vs. reading every page
   - Trade-off: faster reads, slower writes

2. **What indexes exist in your database?**
   - How many?
   - On which columns?
   - Are they being used?
   - Are there queries that would benefit from new indexes?

3. **What makes a good index?**
   - Indexes on columns used in WHERE clauses
   - Indexes on columns used in joins
   - Indexes on columns used in ORDER BY
   - Not every column needs an index
   - Too many indexes slow down writes

**Exploration:**
Find your indexes:
```sql
-- List all indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'orbat'
ORDER BY tablename, indexname;

-- See which ones are being used
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'orbat'
ORDER BY idx_scan DESC;
```

Questions:
- Which tables have the most indexes?
- Which indexes are never used? (idx_scan = 0)
- Which queries would benefit from an index?

#### Part 2: Creating and Testing Indexes (1.5 hours)

**Guiding questions:**

1. **How do you create an index?**
   ```sql
   CREATE INDEX idx_mentions_unit_id 
   ON orbat.mentions(unit_id);
   ```
   - Simple syntax
   - But what should you index?
   - How do you know it helps?

2. **How do you measure if an index helps?**
   - Run EXPLAIN ANALYZE before index
   - Create index
   - Run same query again
   - Compare timing and rows scanned

3. **When is an index harmful?**
   - If query returns most rows (sequential scan faster)
   - If column has low cardinality (few unique values)
   - If index isn't being used (unused index just slows writes)

**Safe experimentation (test database):**
1. Find a slow query (from your analysis Wednesday)
2. Create a test database: `CREATE DATABASE orbat_test;`
3. Restore your backup there
4. Test before:
   ```sql
   EXPLAIN ANALYZE SELECT ...;
   ```
5. Create index:
   ```sql
   CREATE INDEX idx_test ON table(column);
   ```
6. Test after:
   ```sql
   EXPLAIN ANALYZE SELECT ...;
   ```
7. Compare: did it get faster? How much?
8. Drop index:
   ```sql
   DROP INDEX idx_test;
   ```

Document:
- "Indexes I considered adding"
- "Test results: which ones would help?"
- "Which indexes I recommend creating in production"

### Thursday Session (3-4 hours): Logs, Monitoring, and Diagnostics

**Session Theme:** "How to monitor database health and find problems"

#### Part 1: PostgreSQL Logging (1.5 hours)

**Guiding questions:**

1. **What does PostgreSQL log?**
   - Errors
   - Slow queries (if configured)
   - Connections
   - Warnings
   - Administrative actions
   - Everything? Or only important stuff?

2. **Where are the logs?**
   - Are they enabled on your system?
   - Where are they stored?
   - How often are they rotated?
   - Can you read them?

3. **What useful information can you find?**
   - "ERROR" lines: what went wrong?
   - "duration:" lines: slow queries
   - "STATEMENT:" lines: what query was running?
   - Connection messages: who's connecting when?

**Hands-on exploration:**
Try to find your PostgreSQL logs:
- Linux: usually `/var/log/postgresql/`
- macOS: `/usr/local/var/postgres/` or similar
- Windows: varies by installation
- Cloud: might be in management console

If you can find them:
- Open the most recent log file
- Look for interesting lines
- Find a slow query (duration > 1000 ms)
- Find an error
- Document what you found

**If logging isn't enabled, consider:**
- Should it be?
- What would you want to log?
- How often would you check logs?

#### Part 2: System Views for Monitoring (1.5 hours)

**PostgreSQL has built-in monitoring views:**

**Find active connections:**
```sql
SELECT pid, usename, state, query
FROM pg_stat_activity
WHERE datname = 'russianorbatukraine'
AND state != 'idle';
```

**Find slowest queries (if stats enabled):**
```sql
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

**Find index usage:**
```sql
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE schemaname = 'orbat'
ORDER BY idx_scan DESC;
```

**Find table sizes:**
```sql
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'orbat'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

**Hands-on:**
- Run each of these on your database
- What do they tell you?
- Are there surprises?
- Which tables are biggest?
- Which queries are slowest?
- Which indexes aren't being used?

Document:
- "Current database statistics"
- "Potential problems I discovered"
- "Tables/queries I should monitor"

### Friday Session: Week 6 Wrap-up & Phase 1 Reflection (2 hours)

**Create Database Optimization & Diagnostics Guide:**

```markdown
# Database Optimization & Diagnostics Guide

## EXPLAIN Basics
[How to read query plans]
[Common patterns and what they mean]

## Performance Problems in My Database
[Slow queries you found]
[Why they're slow]
[How you'd fix them]

## Index Recommendations
[Indexes that would help]
[Why each one]
[Performance impact estimates]

## Monitoring
[How to find slow queries]
[How to monitor table sizes]
[How to track index usage]
[What logs tell you]

## Regular Maintenance
[Weekly tasks]
[Monthly tasks]
[What to monitor]

## Troubleshooting Guide
- Problem: "Queries are slow"
  → Check: [what to look at]
  → Possible causes: [list]
  → Solutions: [what to try]

- Problem: "Database is big, taking up lots of disk space"
  → Check: [what tables are biggest]
  → Possible causes: [old data? unnecessary copies?]
  → Solutions: [archive/delete old data?]
```

**Complete Phase 1 Deliverables:**

By now you have:
- [ ] Connection Management Runbook
- [ ] Permissions Audit Document
- [ ] Backup & Recovery Procedures Document
- [ ] Schema Change Procedures Document
- [ ] Database Optimization & Diagnostics Guide
- [ ] Concept Library (50+ entries)
- [ ] All code and documentation in Git

**Phase 1 Self-Assessment:**

```markdown
# Phase 1 Completion: Self-Assessment

## Knowledge Areas
- [ ] PostgreSQL architecture—I understand how it works
- [ ] Connection management—I know how to connect safely
- [ ] Permissions & security—I can audit and set up user access
- [ ] Backup & recovery—I have a plan and have tested it
- [ ] Schema modification—I understand the risks and procedures
- [ ] Query optimization—I can find slow queries and fix them

## Confidence Level (1-5)
- Understanding my database: [rating]
- Managing permissions: [rating]
- Backup/recovery procedures: [rating]
- Making schema changes: [rating]
- Finding and fixing slow queries: [rating]

## Accomplishments
- [What you're most proud of]
- [How you've grown]
- [New understanding you have]

## Next Steps (Phase 2)
- [What topics you want to dive deeper on]
- [New database features to learn]
- [Scripts to automate]
```

---

## Learning Mode Notes

### TEACHING MODE (Default)

When you ask questions, I guide you to answers with:
1. **Clarifying questions** - What are you trying to understand?
2. **Research suggestions** - Where to find information
3. **Guiding scenarios** - How to think about the problem
4. **Hands-on prompts** - What to try and observe
5. **Reflection questions** - What does this mean for your situation?

### EXPLAINER MODE

When you need **EXPLAINER MODE**, I provide:
- Direct explanations with examples
- Step-by-step procedures
- Code snippets you can use
- Faster resolution (good for urgent issues)

---

## Success Criteria for Focus Area 2

**By end of Week 6, you should feel:**
- Confident connecting to your database in multiple ways
- Comfortable understanding who can access what
- Clear on how to protect your data (backups)
- Safe making schema changes
- Able to find and fix performance problems

**By end of Week 6, you should own:**
- Complete documentation of your database setup
- Procedures for all critical admin tasks
- Understanding of why things are the way they are
- Ability to troubleshoot most common problems
- Trust that you can recover from disasters

---

## Resources

**PostgreSQL Documentation:**
- Server Administration: https://www.postgresql.org/docs/current/admin.html
- SQL Commands: https://www.postgresql.org/docs/current/sql-commands.html
- System Catalogs: https://www.postgresql.org/docs/current/catalogs.html

**Tools:**
- psql (command-line client)
- pgAdmin (GUI)
- DBeaver (advanced query tool)
- pgBadger (log analysis)

**Your Resources:**
- complete_russianorbat_schema.sql - Your actual database structure
- functions_schema.sql - Your custom functions
- Progress trackers and concept library - Your learning documentation

---

## Final Thoughts

This five-week journey transforms you from "someone who uses a database" to "someone who owns it." That's a significant shift in capability and confidence.

**By the end of Week 6, you won't know everything about PostgreSQL.** (Nobody does—it's a 30-year-old system!) 

**But you will know:**
- How to learn what you don't know
- Where to look when something breaks
- How to protect your data
- How to make changes safely
- How to measure and improve performance

**That's mastery of the fundamentals. Everything else builds from there.**

---

**Let's begin.**
