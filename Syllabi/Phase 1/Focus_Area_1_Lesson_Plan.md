# Focus Area 1: Understanding My Existing Scripts
## Weeks 1-4 Detailed Lesson Plan

**Student:** Nate Kramer  
**Phase:** Phase 1 - Consolidation & Confidence  
**Focus Area:** Understanding My Existing Scripts (Weeks 1-4)  
**Total Duration:** 4 weeks × 15 hours/week = 60 hours  
**Learning Mode:** TEACHING MODE (default) | EXPLAINER MODE (when needed)  
**Start Date:** November 17, 2025

---

## Strategic Context

### Why This Focus Area Now

You're transitioning from "someone who wrote some scripts" to "someone who owns and maintains production systems." This focus area builds that foundation:

- **Week 1:** Deep understanding of your primary automation scripts
- **Week 2:** Complete documentation of what your code does
- **Week 3:** Understand how your scripts interact with the database
- **Week 4:** Build your debugging toolkit and identify all failure points

By Week 4, you won't just know how to run your scripts—you'll own them completely.

### Your Current Automation

Your systems include:
- **mentions.py** - Extracts unit mentions from intelligence sources
- **position_update_v3.py** - Updates unit position data in the database
- Related utilities and helper scripts
- PostgreSQL backend (orbat, maid, facilities schemas)

These scripts are currently in production. This focus area is about understanding them completely so you can maintain, debug, and extend them with confidence.

### What "Understanding" Means

Understanding your code means you can:
1. **Explain** - Describe what it does, how it works, why it's designed that way
2. **Debug** - Trace execution, identify problems, fix bugs
3. **Modify** - Make changes without breaking things
4. **Maintain** - Monitor it, fix issues, improve it
5. **Teach** - Explain it to team members or document it clearly

---

## Four-Week Overview

| Week | Primary Focus | Secondary Focus | Deliverable |
|------|---|---|---|
| **Week 1** | Script deep-read & explanation | First documentation attempt | Script_Explanation.md + Common_Errors.md starter |
| **Week 2** | Understand database interaction | Script architecture mapping | Script_Map.md + Database_Operations.md |
| **Week 3** | Flow tracing & data movement | Failure scenario documentation | Comprehensive failure analysis |
| **Week 4** | Debugging skills & automation | Integration understanding | Debug_Procedures.md + Testing_Plan.md |

---

## Weekly Goals Overview

### Week 1 Goals: Deep Script Understanding
- Can explain your primary script line-by-line
- Understand data flow from input to output
- Identify 3-5 potential failure points
- Set up documentation structure

### Week 2 Goals: Database Integration
- Understand which database tables are used
- Know what each SQL query does
- Identify data validation points
- See complete data flow through the system

### Week 3 Goals: Error Scenarios
- Document all potential failure modes
- Understand where errors appear
- Know how to diagnose each type of failure
- Create diagnostic flowcharts

### Week 4 Goals: Mastery & Ownership
- Confidently explain your entire automation
- Could debug an issue without AI help
- Understand trade-offs in design
- Ready to modify or extend scripts

---

## Overview of Week 1

### This Week's Purpose
**Own what you've already built; establish deep understanding of your automation before expanding it.**

By Friday, you'll understand your primary automation scripts completely—including what they do, how they fail, and where the weak points are. This foundation enables all future learning.

### Big Picture
You're managing production database automation. You can't confidently modify, debug, or extend code you don't fully understand. This week is about achieving that understanding.

---

## Weekly Goals

### By End of Friday, You Will:
1. **Understand your complete automation workflow** - Can trace code execution from start to finish
2. **Identify all database operations** - Know what queries run, when, and why
3. **Recognize failure points** - Can articulate 3-5 scenarios where each script could break
4. **Have working version control** - All code committed to GitHub with meaningful history
5. **Create foundational documentation** - Script Map and Common Errors files started

### Success Looks Like:
When a script fails, you can think through probable causes instead of just "something broke." You understand not just *what* your code does, but *why* it does it that way.

---

## Focus Areas (4 Mini-Modules)

### Focus Area 1: Script Deep-Read
**Primary Goal:** Understand your automation code completely  
**Why This One Quarter:** You can't debug what you don't understand

#### This Week's Work:

**Tuesday Session (3-4 hours): Script Walkthrough**
- Read mentions.py line-by-line
- Understand each variable assignment
- Know what each function does
- Understand the database queries
- See the complete flow from start to finish

**Questions to Answer (in your notes):**
1. What does this script do in one sentence?
2. What data does it read? Where from?
3. What data does it write? Where to?
4. What order do things happen in?
5. What would happen if Step 3 failed? Step 7?

**Deliverable by Friday:**
- Annotated code (comments added to your copy)
- Your own explanation (2-3 paragraphs) of what mentions.py does
- Flow diagram (even a simple text one: "Step 1 → Step 2 → Step 3")

**Success Looks Like:**
You could explain your script to someone else without looking at the code. You understand the logic, not just the syntax.

---

### Focus Area 2: Database Understanding
**Primary Goal:** Identify all database operations and their impact  
**Why This One Fourth:** Database operations are where failures hurt most

#### This Week's Work:

**Wednesday Session (2-3 hours): Database Queries Examination**
- List every SQL query your code runs
- For each query, answer: "What does this do?"
- Understand: SELECT vs. INSERT vs. UPDATE vs. DELETE
- Ask yourself: "What if this fails?"

**Specific Questions to Answer:**
1. How many tables does this script touch?
2. What data validation happens before data is written?
3. Could a mention be inserted halfway and then fail? How would you know?

**Deliverable by Friday:**
- Script_Map.md with database details clearly noted

**Success Looks Like:**
You understand which database features your code is using (transactions, constraints, indexes, etc.), even if you don't fully understand those features yet.

---

### Focus Area 3: Debugging Fundamentals
**Primary Goal:** Recognize failure points and start debugging patterns  
**Why This One Third:** Understanding where things can break is the foundation of debugging

#### This Week's Work:

**Tuesday Session (Integrated):** As you read mentions.py:
- Mark sections with `# PROBLEM:` if you see potential failure points
- Think: "What if this fails? What error would we see?"
- Start a running list: "Common Problems in This Script"

**Thursday Session (Integrated):** In your Script Map:
- Document error scenarios: "If X happens, then Y..."
- Note: "Where would we see the error?" (application log? database log? silent failure?)

**Example Framework:**
```
Problem: Duplicate mention inserted
Where: In the INSERT statement
Why it might happen: No unique constraint checking
How to fix: Add UNIQUE constraint or check before insert
```

**Deliverable by Friday:**
- Common_Errors.md started with 3-5 scenarios from mentions.py

**Success Looks Like:**
When a unit mention doesn't insert, you can think through 3-4 possible causes instead of just "something broke."

---

### Focus Area 4: Version Control & Documentation
**Primary Goal:** Get your code in GitHub and establish documentation habits  
**Why This One Fourth:** This enables everything else. You can't learn if your code isn't organized

#### This Week's Work:

**Wednesday Session (3-4 hours): GitHub Setup**
- Create GitHub repository for your automation
- Commit mentions.py and related scripts
- Create professional README
- Set up .gitignore (don't commit credentials!)

**Ongoing (All Week):**
- Commit after each session
- Write meaningful commit messages
- Track your progress in Progress_Week_01.md

**Deliverable by Friday:**
- GitHub repository with all code
- README.md explaining the automation
- At least 3 meaningful commits
- Progress_Week_01.md complete

**Success Looks Like:**
Your code is backed up, organized, and you can see the history of what you've done.

---

## Daily Schedule

### Monday, November 17 (2.5 hours)
**Theme: Planning & Reflection**

**Objective:** Get clear on the week, set goals, prepare to learn

**What You'll Do:**

1. **Read This Plan (20 min)**
   - Make sure the schedule works for you
   - Note any questions or concerns

2. **Copy and Customize Progress Tracker (15 min)**
   - Copy Progress_Tracker_Template.md → Progress_Week_01.md
   - Fill in your three reflection questions:
     - *What's the single most important thing for me to understand about my automation?*
     - *What's one database concept I'm shakiest on?*
     - *What's my biggest fear about this learning journey?*

3. **Set Week Goals (15 min)**
   - Review the 5 goals at top of this plan
   - Write them down in Progress_Week_01.md
   - Commit to them

4. **Preview Your Code (1 hour)**
   - Open mentions.py (your primary script for this week)
   - Read it once, don't annotate yet
   - Note initial questions/confusion points
   - List 3-5 things you don't understand

5. **Commit Your Progress (10 min)**
   ```bash
   git add Progress_Week_01.md
   git commit -m "Week 1: Planning and reflection"
   git push
   ```

**Questions to Bring to Next Session:**
- List the 3-5 confusing things you noted
- Write one specific question about each

---

### Tuesday, November 18 (3-4 hours)
**Theme: Code Deep-Read & Documentation**

**Objective:** Understand your script completely and document what you learn

**What You'll Do:**

1. **Deep-Read mentions.py (2-3 hours)**

   **Read Method:**
   - Keep Python docs open: https://docs.python.org/3/
   - Read line by line (not whole-file skimming)
   - Stop at each unfamiliar thing
   - Write a question about it
   - Move on (don't get stuck forever)

   **For Each Section, Ask Yourself:**
   - What is this doing?
   - Why would the author do it this way?
   - What would break if I deleted this line?
   - What data flows through here?

   **In Your Code, Add Comments Like:**
   ```python
   # UNDERSTAND: This is reading the database to find...
   # QUESTION: Why does it use .fetchall() instead of .fetchone()?
   # WORRY: What if the database is down here?
   ```

   **Keep a Running List:**
   - "Things mentions.py does"
   - "Things I don't understand"
   - "Things that could fail"

2. **Create Your Script Explanation (30-45 min)**

   Write 2-3 paragraphs explaining mentions.py:
   - What does it do? (start with one-sentence summary)
   - Where does data come from?
   - What transformations happen?
   - Where does processed data go?
   - When/why would someone run this?

   **Save as:** `Script_Explanation_mentions.md`

3. **Start Failure Scenarios List (30 min)**

   Create Common_Errors.md file, start with:
   ```markdown
   # Common Error Scenarios

   ## mentions.py Potential Problems

   ### 1. [Error Type]
   - **What happens:** [describe the failure]
   - **Where it fails:** [which line/query]
   - **Why:** [root cause]
   - **How to diagnose:** [what to look for]

   ### 2. [Error Type]
   - ...
   ```

   Identify at least 3 failure points from your reading

4. **Commit Your Work (15 min)**
   ```bash
   git add Script_Explanation_mentions.md
   git add Common_Errors.md
   git commit -m "Tuesday: Script deep-read, documentation started, failure scenarios documented"
   git push
   ```

5. **Log Your Progress (10 min)**
   - Update Progress_Week_01.md Tuesday section
   - What did you learn?
   - What confused you?
   - Questions for Claude?

**TEACHING MODE Note:**
If you get stuck on a line of code, don't jump straight to asking. Try:
1. Read the surrounding context
2. Check Python docs for that function
3. Ask yourself: "What would this return?"
4. Test your hypothesis
5. *Then* ask me if still confused

---

### Wednesday, November 19 (3-4 hours)
**Theme: Database Operations & GitHub Setup**

**Objective:** Understand database operations deeply AND get code into version control

**Part 1: Database Query Analysis (2 hours)**

1. **Extract All Queries (30 min)**

   Find every SQL query in mentions.py:
   ```python
   SELECT ...   # Query 1
   INSERT ...   # Query 2
   UPDATE ...   # Query 3
   ```

   Create a new file: `Database_Operations_mentions.md`

2. **Analyze Each Query (1.5 hours)**

   For EACH query, write:
   ```markdown
   ## Query 1: [Description]

   **SQL:**
   [The actual query]

   **Purpose:**
   [What does this do?]

   **Input Data:**
   [What data feeds into this query?]

   **Output:**
   [What does this return?]

   **Failure Points:**
   [What could go wrong?]

   **Database Features Used:**
   [Which concepts: transactions, constraints, indexes, etc.?]
   ```

   **Questions to Answer for Each:**
   - Is this a SELECT, INSERT, UPDATE, or DELETE?
   - What tables does it touch?
   - What validation happens?
   - What if this query fails mid-execution?

3. **Commit Database Documentation (15 min)**
   ```bash
   git add Database_Operations_mentions.md
   git commit -m "Wednesday: Database queries analyzed and documented"
   git push
   ```

**Part 2: GitHub Setup (1-2 hours)**

*If you haven't already created a repository:*

1. **Create Repository (15 min)**
   - GitHub.com → New Repository
   - Name: `isw-orbat-automation` (or your naming preference)
   - Description: "Automation scripts for unit position tracking and mention management"
   - Add README.md
   - Add .gitignore (choose Python template)

2. **Create Professional README.md (45 min)**

   ```markdown
   # ISW ORBAT Automation

   ## Overview
   [2-3 sentences: What does this system do?]

   ## Scripts
   - **mentions.py** - [what it does]
   - **position_update_v3.py** - [what it does]

   ## Database
   - Tables: [list them]
   - Connection: PostgreSQL [version]

   ## Setup
   [How to run locally - credentials setup, dependencies, etc.]

   ## Usage
   [How to run each script]

   ## Maintenance
   [How to troubleshoot common issues]
   ```

3. **Commit Your Code (30 min)**
   ```bash
   git add mentions.py position_update_v3.py [other scripts]
   git commit -m "Initial commit: Core automation scripts"
   git push

   git add Script_Explanation_mentions.md
   git add Common_Errors.md
   git add Database_Operations_mentions.md
   git commit -m "Documentation: Script analysis and database operations"
   git push
   ```

4. **Update Progress Tracker (10 min)**
   - Log Wednesday activities
   - Note: GitHub repository URL
   - Database queries documented: [how many?]

---

### Thursday, November 20 (2-3 hours)
**Theme: Script Architecture & Failure Analysis**

**Objective:** Complete Script_Map.md with full failure scenarios

**What You'll Do:**

1. **Create Script_Map.md (2-3 hours)**

   This is your complete picture of how mentions.py works:

   ```markdown
   # Script Map: mentions.py

   ## High-Level Flow
   [Draw the complete flow from start to finish]

   Example:
   ```
   START
     ↓
   Load Configuration
     ↓
   Connect to Database
     ↓
   Read Mention Data from [source]
     ↓
   Validate Data
     ↓
   Insert into mentions table
     ↓
   Log Results
     ↓
   END
   ```

   ## Variables & Their Purpose
   [For each major variable, explain what it holds]

   ## Database Operations
   [List each query with purpose]

   ## Configuration & Secrets
   [What configuration does it need?]
   [Where does it get credentials?]

   ## Logs & Monitoring
   [Where does it log?]
   [How do you know if it worked?]

   ## Error Scenarios & Recovery

   ### Scenario 1: Database Connection Fails
   - **When it happens:** [at what point in flow]
   - **Error message:** [what would you see]
   - **Root cause:** [why it happened]
   - **How to recover:** [steps to fix]

   ### Scenario 2: Duplicate Mention Inserted
   - [same structure as above]

   ### Scenario 3: Malformed Input Data
   - [same structure as above]

   [Add 2-3 more scenarios]

   ## Questions Still Unanswered
   [What don't you understand yet?]
   ```

2. **Document Your Confusion (30 min)**

   In Script_Map.md, add a section:
   ```markdown
   ## Open Questions

   1. [Specific question about the code]
   2. [Question about database behavior]
   3. [Question about error handling]
   ```

   These become your questions for Claude in TEACHING MODE.

3. **Add to Concept Library (30 min)**

   Add 3-5 new concepts you've learned:
   ```markdown
   ## INSERT Statement

   **Definition:** SQL command to add new rows to a table

   **Example from mentions.py:**
   INSERT INTO mentions (unit_id, text, date) VALUES (%s, %s, %s)

   **Why it matters:**
   Understanding INSERT logic helps me see where mentions get added

   **Confusion points:**
   Still not clear on %s vs. using string formatting directly
   ```

4. **Commit Your Work (15 min)**
   ```bash
   git add Script_Map.md
   git add Concept_Library.md
   git commit -m "Thursday: Complete script architecture map and failure scenarios"
   git push
   ```

---

### Friday, November 21 (2 hours)
**Theme: Review, Reflection, and Celebration**

**Objective:** Complete Week 1, document progress, and plan Week 2

**What You'll Do:**

1. **Complete Progress_Week_01.md (1 hour)**

   Fill in your comprehensive weekly summary:

   **Time Log:**
   ```
   Monday: 2.5 hours - Planning and reflection
   Tuesday: 3.5 hours - Script deep-read and documentation
   Wednesday: 3.5 hours - Database analysis and GitHub setup
   Thursday: 2.5 hours - Script map and failure scenarios
   Friday: 2 hours - Review and reflection
   TOTAL: 14 hours
   ```

   **What I Learned This Week:**
   - [Key insight 1 - about your code]
   - [Key insight 2 - about databases]
   - [Key insight 3 - about debugging]

   **Accomplishments:**
   - [x] Created GitHub repository
   - [x] Committed all scripts with meaningful messages
   - [x] Completely understand mentions.py
   - [x] Created Script_Map.md with complete flow
   - [x] Documented failure scenarios
   - [x] Created Concept Library with new terms
   - [x] Identified open questions

   **Challenges & How I Handled Them:**
   - [Challenge 1]: [How I worked through it]
   - [Challenge 2]: [How I worked through it]

   **Still Confused About:**
   - [Topic 1]
   - [Topic 2]

   **Week Rating (1-5 stars):** ⭐⭐⭐⭐⭐ - Why?
   [Be honest. 5 stars = "I feel ready for Week 2." 3 stars = "Need help." 1 star = "This didn't work for me."]

2. **Reflection Questions (30 min)**

   Write honest answers:

   **1. How am I feeling?**
   - Energized? Overwhelmed? Confident? Confused?
   - What's driving that feeling?

   **2. What surprised me this week?**
   - Something harder than expected?
   - Something easier than expected?
   - Something I discovered about my code?

   **3. What went well?**
   - What felt productive?
   - What felt good to learn?
   - What made sense?

   **4. What needs adjustment?**
   - Schedule? Time allocation? Type of learning? Pace?

   **5. Am I ready for Week 2?**
   - Do I understand mentions.py?
   - Can I explain it to someone else?
   - What's my biggest question going into Week 2?

3. **Final Commit (15 min)**

   ```bash
   git add Progress_Week_01.md
   git add Concept_Library.md
   git commit -m "Week 1 complete: Deep understanding of mentions.py, documentation package, GitHub setup"
   git push
   ```

4. **Celebrate & Reflect (15 min)**

   You've accomplished:
   - ✅ Understood your automation completely
   - ✅ Documented your code professionally
   - ✅ Set up version control properly
   - ✅ Started building debugging instincts
   - ✅ Created reusable learning system

   **That's a real week's work.**

---

## Resources You'll Need This Week

### For Python
- Official Python Docs: https://docs.python.org/3/
- Your mentions.py script (the best learning material!)

### For Git/GitHub
- Git Book (free): https://git-scm.com/book/en/v2
- GitHub Guides: https://guides.github.com/

### For PostgreSQL (Preview for Next Week)
- PostgreSQL Official Docs: https://www.postgresql.org/docs/
- We'll dive deeper next week

### For Documentation
- Markdown Guide: https://www.markdownguide.org/basic-syntax/

---

## Week 2: Database Integration & Data Flow

**Dates:** November 24-28, 2025  
**Total Hours:** 15 hours (3-4 per day Tue-Thu, 2-3 Fri)  
**Primary Goal:** Understand how your scripts interact with the database  
**Deliverable:** Complete Database_Operations.md + Script_Map.md

### Learning Objectives

By the end of Week 2, you should be able to answer:
1. What database tables does each script use?
2. What happens to data as it flows through the system?
3. How does your code validate data before inserting?
4. What constraints protect data integrity?
5. Where could data corruption happen?

### Why This Matters

Scripts don't exist in isolation—they interact with the database. Understanding that interaction means:
- You see where data comes from and where it goes
- You understand what prevents bad data
- You can trace problems backward from the database
- You can predict side effects of changes

### Tuesday Session (3-4 hours): SQL Query Deep Dive

**Session Theme:** "What do these queries actually do?"

#### Part 1: Extract All Queries (1 hour)

**Guiding questions:**

1. **How many SQL queries are in your scripts?**
   - SELECT queries (reading data)?
   - INSERT queries (adding data)?
   - UPDATE queries (modifying data)?
   - DELETE queries (removing data)?

2. **Where does each query live?**
   - In the Python code as a string?
   - In a separate SQL file?
   - Built dynamically from parameters?

3. **What's the execution order?**
   - Do they always run in the same order?
   - Could they run conditionally?
   - Is there a sequence that matters?

**Hands-on assignment:**
- Open each of your main scripts
- Find every SQL query
- Extract it and save it separately
- Number them in execution order
- For each, write: "This query [action] and returns/modifies [data]"

**Document in Database_Operations.md:**
```markdown
## Query Inventory

### mentions.py Queries

#### Query 1: Check if mention already exists
**SQL:** [The exact SQL]
**Type:** SELECT
**Purpose:** [What it's checking for]
**Input:** [Parameters passed to it]
**Output:** [What it returns]
**Impact:** [What happens next based on result]

#### Query 2: Insert new mention
[Same structure]
```

#### Part 2: Understanding Individual Queries (1.5 hours)

For each query, ask:

**Structural questions:**
- What tables does it touch?
- What columns does it read/write?
- Does it use WHERE clause? (If so, what's it filtering?)
- Does it use JOINs? (If so, why is it connecting tables?)
- Does it use ORDER BY? (If so, why that order?)

**Business logic questions:**
- What's this query checking for?
- What would good data look like?
- What would bad data look like?
- What prevents bad data from being inserted?

**Risk questions:**
- What if this query returns no rows?
- What if it returns more rows than expected?
- What if it fails to execute?
- What if someone manipulates the input parameters?

**Example analysis (for mentions.py insert):**

```sql
INSERT INTO mentions (unit_id, mention_text, date_mentioned)
VALUES (%s, %s, %s)
```

**Your analysis:**
- Touches: orbat.mentions table
- Columns: unit_id (which unit?), mention_text (what was said?), date_mentioned (when?)
- No WHERE: always inserts
- No JOIN: doesn't need data from other tables
- What it's doing: Adding a new mention of a unit
- Risk: What if unit_id doesn't exist? (Foreign key constraint prevents this!)
- Risk: What if mention_text is empty? (Your code should validate)
- Risk: What if date_mentioned is in future? (Your code should handle)

#### Part 3: Data Validation Points (1 hour)

**Guiding questions:**

1. **Where does validation happen?**
   - In Python before sending to database?
   - In database constraints?
   - Both?

2. **What validations exist?**
   - Check if values are right type? (string, number, date)
   - Check if values are in acceptable range?
   - Check if related data exists?
   - Check for duplicates?

3. **What happens if validation fails?**
   - Error message?
   - Skip that record?
   - Retry?
   - Crash?

**Hands-on exploration:**

Find validation code in your scripts:
```python
# Look for patterns like:
if not mention_text:
    # Validation
if len(mention_text) > 500:
    # Validation
if unit_id not in valid_units:
    # Validation
```

For each validation point:
- What's it checking?
- What happens if check fails?
- Is there a matching database constraint?

Document:
```markdown
## Validation Points in mentions.py

### Python-level validation
1. [Check 1] - ensures [what] - fails: [action]
2. [Check 2] - ensures [what] - fails: [action]

### Database-level validation (constraints)
1. Foreign key on unit_id - ensures [unit exists] - fails: [INSERT fails]
2. [Other constraint] - ensures [what] - fails: [action]
```

### Wednesday Session (3-4 hours): Data Flow & Relationships

**Session Theme:** "How does data move through my system?"

#### Part 1: Table Relationships (1.5 hours)

**Guiding questions:**

1. **What tables does your system use?**
   - Which tables do your scripts read from?
   - Which tables do they write to?
   - Are any tables used by multiple scripts?

2. **How are tables related?**
   - Does orbat.mentions reference orbat.units? (foreign key)
   - Does orbat.positions reference orbat.units?
   - Could changes to one table affect another?

3. **What's the primary data flow?**
   - Data comes in → gets processed → gets stored
   - Which scripts do each step?
   - Where could data get lost or corrupted?

**Exploration assignment:**

Look at your schema files (complete_russianorbat_schema.sql):
- Find CREATE TABLE statements for tables your scripts use
- For each table, identify:
  - Primary key (unique identifier)
  - Foreign keys (references to other tables)
  - Constraints (what validations exist)
  - Indexes (what's optimized for speed)

Create a visual map (simple text is fine):

```
Input Data
    ↓
mentions.py reads from [source]
    ↓
Validates: [checks what?]
    ↓
Inserts into orbat.mentions
    ↓
References: orbat.units (must exist!)
    ↓
Result: New mention recorded
```

#### Part 2: Impact Analysis (1.5 hours)

**For each script, understand the chain of consequences:**

**Question: What happens if mentions.py inserts a mention?**

1. **Direct effects:**
   - orbat.mentions table gets one more row
   - Any indexes on mentions are updated
   - Any views referencing mentions show new data

2. **Indirect effects:**
   - Scripts that read from orbat.mentions see new data
   - Reports based on mention counts change
   - Any aggregations/statistics become slightly different

3. **Could cause problems?**
   - If mention references non-existent unit? (Foreign key prevents!)
   - If same mention inserted twice? (Check if you have uniqueness constraint?)
   - If date is invalid? (Your validation should catch)

**Question: What happens if position_update_v3.py updates positions?**

Similar analysis for that script.

**Document:**
```markdown
## Script Impact Analysis

### mentions.py
**Direct changes:**
- [Table 1] gets [X] new rows
- [Table 2] maybe updated

**Cascading effects:**
- [Other script] will see new data
- [Report] will change
- [Metric] will update

**Could go wrong:**
- [Problem 1] - prevented by [constraint/validation]
- [Problem 2] - prevented by [constraint/validation]
```

### Thursday Session (3-4 hours): Complete Database Map

**Session Theme:** "Complete picture of how data flows"

**Create comprehensive Database_Operations.md:**

```markdown
# Database Operations

## Overview
[Diagrams showing data flow]

## Schemas & Tables Used
- orbat.units - [what this stores]
- orbat.mentions - [what this stores]
- orbat.positions - [what this stores]
- [others]

## Script-by-Script Analysis

### mentions.py
**Purpose:** [What it does]

**Input:**
- Reads from: [source]
- Format: [CSV/API/database/etc]

**Processing:**
- Validates: [what checks]
- Transforms: [what changes]

**Database Operations:**
- Query 1: [check for duplicates] → SELECT
- Query 2: [insert mention] → INSERT
- Query 3: [log result] → [optional]

**Output:**
- New rows in: orbat.mentions
- Updates to: [if any]
- Cascading effects: [what else changes]

**Error Handling:**
- If input invalid: [action]
- If database fails: [action]
- If duplicate found: [action]

### position_update_v3.py
[Same structure]

## Data Integrity Safeguards

### Constraints
[Which constraints protect which data]

### Validation
[What checks happen before database writes]

### Order Dependencies
[Does order of operations matter?]

## Potential Problem Areas
[Where data could get corrupted or lost]
```

### Friday Session: Review & Week 2 Wrap-up (2 hours)

**Complete:**
- [ ] Database_Operations.md (comprehensive)
- [ ] Updated Script_Map.md with data flow diagrams
- [ ] Understanding of all queries
- [ ] Data validation points documented
- [ ] Progress_Week_02.md filled in

**Update Progress_Week_02.md:**
- How many SQL queries did you find?
- Which table is touched most frequently?
- Where did you find validation?
- What surprised you about data flow?
- Open questions for Week 3?

---

## Week 3: Failure Analysis & Error Scenarios

**Dates:** December 1-5, 2025  
**Total Hours:** 15 hours  
**Primary Goal:** Document all ways your scripts could fail and how to diagnose each  
**Deliverable:** Comprehensive failure scenario documentation

### Learning Objectives

By the end of Week 3, you should be able to answer:
1. What are the top 5 ways your scripts could fail?
2. For each failure, what error would you see?
3. How would you diagnose the root cause?
4. What's the recovery procedure?
5. Which failures are preventable? How?

### Why This Matters

Understanding failure modes is the foundation of debugging. You'll encounter problems—the difference between "I'm lost" and "I can fix this" is knowing what to look for.

### Tuesday Session (3-4 hours): Failure Taxonomy

**Session Theme:** "What could go wrong?"

#### Part 1: Identify Failure Categories (1.5 hours)

**Guiding questions:**

1. **What are the main failure types?**
   - Input failure (bad data coming in)
   - Database failure (can't connect or query fails)
   - Logic failure (code doesn't do what it should)
   - Output failure (can't write results)
   - External failure (dependent system down)

2. **What's specific to your scripts?**
   - What if data source is unavailable?
   - What if database is down?
   - What if required files are missing?
   - What if credentials are wrong?

3. **What's easy to detect vs. hard to detect?**
   - Obvious: Script crashes with error message
   - Subtle: Script runs but produces wrong results
   - Silent: Script succeeds but data is corrupt

**Hands-on:**

For each main script, brainstorm:
- 5 ways it could fail to start
- 5 ways it could fail during processing
- 5 ways it could fail when writing results

Then categorize by severity:
- **Critical:** System unusable, data at risk
- **Major:** Feature doesn't work, significant impact
- **Minor:** Workaround exists, limited impact

#### Part 2: Specific Failure Scenarios (1.5 hours)

**For each likely failure, document:**

**Example: Database Connection Fails**

```markdown
## Failure Scenario: Cannot Connect to Database

**Severity:** CRITICAL

**When it happens:**
- mentions.py starts
- Tries to connect to PostgreSQL
- Network down, PostgreSQL not running, wrong credentials, etc.

**Error message you'd see:**
psycopg2.OperationalError: could not connect to server

**What actually failed:**
[One of several things—need to diagnose]

**How to diagnose:**
1. Check: Is PostgreSQL running? `pg_isready`
2. Check: Network accessible? `ping [server]`
3. Check: Credentials correct? Verify username/password
4. Check: Port correct? Default is 5432

**Root causes ranked by likelihood:**
1. [Most likely] - PostgreSQL not running
2. [Second most likely] - Wrong credentials
3. [Third] - Network issue
4. [Fourth] - Database doesn't exist

**How to recover:**
[Steps to fix each cause]

**How to prevent:**
[Early detection? Automated check? Better docs?]

**Testing:**
How would you intentionally cause this to test your recovery?
```

**Document in Common_Errors.md:**

Extract critical scenarios:

```markdown
## Critical Failures (System Down)

### 1. Cannot Connect to Database
- Diagnosis: [How to detect]
- Recovery: [How to fix]

### 2. Duplicate Data Inserted
- Diagnosis: [How to detect]
- Recovery: [How to fix]

### 3. [Other critical]
- Diagnosis: [How to detect]
- Recovery: [How to fix]

## Major Failures (Feature broken)

### 1. [Major failure]
- Diagnosis: [How to detect]
- Recovery: [How to fix]

### 2. [Major failure]
- Diagnosis: [How to detect]
- Recovery: [How to fix]

## Minor Failures (Workaround exists)

### 1. [Minor failure]
- Diagnosis: [How to detect]
- Recovery: [How to fix]
```

### Wednesday Session (3-4 hours): Diagnostic Procedures

**Session Theme:** "How do I figure out what went wrong?"

#### Part 1: Finding Clues (1.5 hours)

**Guiding questions:**

1. **Where do you look when something fails?**
   - Script output/stdout?
   - Log files?
   - Database state?
   - Application monitoring?

2. **What tells you what went wrong?**
   - Error messages (most explicit)
   - Log file entries (provide context)
   - Data state (shows effects of failure)
   - Absence of expected output (silent failure)

3. **How do you trace through the script?**
   - Read the code line-by-line?
   - Add debug print statements?
   - Run in debugger?
   - Check intermediate results?

**Hands-on:**

For mentions.py, create a diagnostic checklist:

```markdown
## Diagnostic Checklist: mentions.py

**If script fails to start:**
- [ ] Is Python installed? (`python --version`)
- [ ] Are dependencies installed? (`pip list`)
- [ ] Can you read the input file? (`ls -la [input]`)
- [ ] Do credentials exist? (`echo $DB_PASSWORD`)

**If script runs but hangs:**
- [ ] Is it waiting for database? (Check database logs)
- [ ] Is it waiting for file input? (Check file system)
- [ ] Is it in infinite loop? (Check line X)

**If script runs but no output:**
- [ ] Check log file: [location]
- [ ] Check database: Did data get inserted? `SELECT COUNT(*) FROM orbat.mentions;`
- [ ] Check output file: [location]

**If script fails with error:**
- [ ] What's the exact error message?
- [ ] What line number?
- [ ] What was the script trying to do?
- [ ] What data was it processing?
```

#### Part 2: Building a Debug Toolkit (1.5 hours)

**What tools help you debug?**

1. **For SQL problems:**
   ```sql
   -- Test the exact query
   SELECT ... FROM orbat.mentions WHERE [condition];
   
   -- Check if tables exist
   \d orbat.mentions
   
   -- Check recent data
   SELECT * FROM orbat.mentions ORDER BY inserted_at DESC LIMIT 10;
   ```

2. **For Python problems:**
   ```python
   # Add debug logging
   import logging
   logging.basicConfig(level=logging.DEBUG)
   
   # Print intermediate values
   print(f"DEBUG: variable_name = {variable_name}")
   
   # Add try-except with detailed error info
   try:
       conn.execute(query)
   except Exception as e:
       print(f"ERROR: {type(e).__name__}: {e}")
       print(f"Query was: {query}")
       raise
   ```

3. **For system problems:**
   ```bash
   # Check if PostgreSQL is running
   pg_isready
   
   # Check system resources
   df -h  # disk space
   ps aux | grep postgres  # processes
   
   # Check logs
   tail -f /var/log/postgresql/postgresql.log
   ```

**Document your toolkit:**

```markdown
## Debug Toolkit

### For mentions.py failures
- Log file location: [path]
- Database query to check status: [query]
- Python debugging: add this code [snippet]

### For database failures
- Check if running: [command]
- Check logs: [location]
- Test connection: [command]

### For system failures
- Check disk space: [command]
- Check processes: [command]
- Check network: [command]
```

### Thursday Session (3-4 hours): Recovery Procedures

**Session Theme:** "How do I fix it when it breaks?"

#### Part 1: Failure Recovery Plans (2 hours)

**For each critical failure, document:**

```markdown
## Recovery Plan: [Failure Name]

### Immediate Actions (first 5 minutes)
1. [Stop the script? Keep it running?]
2. [Preserve evidence—don't delete logs]
3. [Alert stakeholders? Run quietly?]

### Diagnosis (next 15 minutes)
1. [Check #1]
2. [Check #2]
3. [Verify root cause]

### Recovery (next 30 minutes)
1. [Fix step 1]
2. [Fix step 2]
3. [Verify system is working]

### Verification (ensure everything is OK)
1. [What should be true now?]
2. [How to verify?]
3. [Any side effects to check?]

### Prevention (so it doesn't happen again)
1. [What should we do differently?]
2. [Code change? Config? Documentation?]
3. [Test to prevent recurrence?]
```

**Create recovery plans for top 3 critical failures:**

For example:
- Recovery Plan: Database Connection Lost
- Recovery Plan: Duplicate Data Detected
- Recovery Plan: Input File Corrupted

#### Part 2: Testing & Runbook (1 hour)

**Create your Failure_Recovery_Runbook.md:**

```markdown
# Failure Recovery Runbook

## Quick Reference

| Failure | Diagnosis | Recovery | Contact |
|---------|-----------|----------|---------|
| DB down | pg_isready | Restart service | [DBA] |
| Bad data | Log shows error | Check input | [Your name] |
| Duplicate | COUNT mismatch | Delete + retry | [Your name] |

## Detailed Procedures

### [Failure 1]
[Complete procedure]

### [Failure 2]
[Complete procedure]

## Testing
[How to test each recovery procedure safely]
```

### Friday Session: Review & Week 3 Wrap-up (2 hours)

**Complete:**
- [ ] Common_Errors.md (comprehensive)
- [ ] Diagnostic checklists
- [ ] Debug toolkit documented
- [ ] Recovery procedures for top failures
- [ ] Failure_Recovery_Runbook.md created
- [ ] Progress_Week_03.md filled in

---

## Week 4: Mastery & Comprehensive Documentation

**Dates:** December 8-12, 2025  
**Total Hours:** 15 hours  
**Primary Goal:** Complete ownership and integration of all knowledge  
**Deliverable:** Comprehensive automation runbook + testing plan

### Learning Objectives

By the end of Week 4, you should be able to:
1. Explain your entire automation to someone else
2. Modify a script without breaking it
3. Debug issues independently
4. Design tests for your scripts
5. Describe trade-offs in your current implementation

### Tuesday Session (3-4 hours): Script Modification Safety

**Session Theme:** "How to change things without breaking them"

#### Part 1: Safe Code Changes (1.5 hours)

**Guiding questions:**

1. **What could go wrong when modifying code?**
   - Change breaks existing behavior
   - Change introduces subtle bugs
   - Change has unexpected side effects
   - Change optimizes for one case but breaks another

2. **How do you change safely?**
   - Understand the code first (weeks 1-3!)
   - Change one small thing at a time
   - Test each change
   - Have a way to revert

3. **What's a good test before committing?**
   - Run with test data
   - Verify output looks right
   - Check database state
   - Look for side effects

**Hands-on scenario:**

Imagine you want to add a feature: "Skip mentions from before 2023"

Planning:
```
Current code:
INSERT ALL mentions regardless of date

Change:
IF date > 2023-01-01 THEN INSERT

Risk analysis:
- Could lose historical mentions
- Previous runs might have processed old data
- Need to handle if someone runs with old data

Safe implementation:
1. Add code for date check
2. Test with old data (verify skipped)
3. Test with new data (verify still inserted)
4. Add flag to enable/disable feature
5. Document the change
6. Commit with clear message
```

#### Part 2: Testing Your Scripts (1.5 hours)

**Guiding questions:**

1. **What should you test?**
   - Happy path (everything works)
   - Error cases (what if data is bad)
   - Edge cases (empty data? huge data? special characters?)
   - Integration (does it work with database?)

2. **How do you test safely?**
   - Use test database (not production!)
   - Use test data (not real intelligence data!)
   - Verify output matches expectations
   - Clean up after tests

3. **What tests would catch real problems?**
   - Test with duplicate data (should handle?)
   - Test with missing data (should handle?)
   - Test with malformed data (should reject?)
   - Test database being slow (timeout?)

**Create Testing_Plan.md:**

```markdown
## Testing Plan for mentions.py

### Unit Tests (test individual functions)

**Test 1: validate_mention**
- Input: Valid mention
- Expected: Returns True
- Actual: [To be tested]

**Test 2: validate_mention**
- Input: Empty mention
- Expected: Returns False
- Actual: [To be tested]

### Integration Tests (test with database)

**Test 1: Insert new mention**
- Setup: Clean test database
- Action: Run mentions.py with test data
- Verify: Row inserted in mentions table
- Cleanup: Delete test data

**Test 2: Handle duplicate**
- Setup: Insert test mention
- Action: Run again with same data
- Verify: No duplicate inserted (constraint prevents)
- Cleanup: Delete test data

### Regression Tests (ensure nothing broke)

**Test 1: Script still runs**
- Ensure basic execution works
- Ensure no new errors
- Ensure output format unchanged

**Test 2: Database queries still work**
- Ensure queries still execute
- Ensure result sets unchanged
- Ensure performance acceptable
```

### Wednesday Session (3-4 hours): Integration & Design Patterns

**Session Theme:** "How do these scripts work together?"

**Explore:**
- Do your scripts share code?
- Do they share database tables?
- Could they run in parallel?
- What's the order they should run?
- What dependencies exist?

**Document in Automation_Runbook.md:**

```markdown
## Complete Automation Runbook

### System Architecture
[Diagram or description of all scripts]

### Data Flow
[How data moves from source to database]

### Dependencies
[What must run before what?]

### Execution Model
- Frequency: [How often?]
- Sequence: [Order of execution]
- Parallelization: [Can scripts run simultaneously?]
- Failure handling: [If one fails, stop all? Or continue?]

### Monitoring & Alerting
[How do you know if something failed?]

### Maintenance
[Regular tasks needed]

### Troubleshooting
[Common issues and fixes]
```

### Thursday Session (3-4 hours): Design Analysis

**Session Theme:** "Why is the system designed this way?"

**For each design choice, ask:**
- Why do it this way?
- What are the trade-offs?
- What are the alternatives?
- What would you change if you could?

**Document in Design_Analysis.md:**

```markdown
## Design Analysis

### Choice 1: [Design decision in your code]
**Why:** [Original reason]
**Trade-offs:** [What you gain and lose]
**Alternatives:** [Other ways to do it]
**Would you change it?** [Your assessment]

### Choice 2: [Another design decision]
[Same analysis]
```

### Friday Session: Week 4 Wrap-up & Focus Area Completion (2 hours)

**Final deliverables:**
- [ ] Complete Automation_Runbook.md
- [ ] Testing_Plan.md
- [ ] Design_Analysis.md
- [ ] Updated Concept_Library.md
- [ ] Progress_Week_04.md comprehensive reflection
- [ ] All code commented and organized
- [ ] All documentation in Git

**Focus Area Completion Checklist:**

```markdown
# Focus Area 1 Completion: Understanding My Existing Scripts

## Knowledge Areas
- [ ] Can explain mentions.py completely
- [ ] Can explain position_update_v3.py completely
- [ ] Understand data flow through system
- [ ] Know all failure modes
- [ ] Could debug issues independently
- [ ] Could safely modify code

## Documentation Complete
- [ ] Script_Explanation.md (2+ scripts)
- [ ] Database_Operations.md (all queries)
- [ ] Script_Map.md (data flow)
- [ ] Common_Errors.md (failure scenarios)
- [ ] Failure_Recovery_Runbook.md
- [ ] Testing_Plan.md
- [ ] Automation_Runbook.md
- [ ] Design_Analysis.md
- [ ] Concept_Library.md (50+ entries)

## Practical Skills
- [ ] Could debug an error without AI help
- [ ] Could add a small feature to a script
- [ ] Could explain system to a team member
- [ ] Know how to test changes safely
- [ ] Could recover if something broke

## Confidence Level (1-5)
- Understanding code: [rating]
- Debugging skills: [rating]
- Making changes safely: [rating]
- Overall system mastery: [rating]
```

---

## Teaching Mode Expectations

### How We'll Work This Focus Area (Weeks 1-4)

**You:**
- Come with specific questions about your code
- Show work (your Script_Map.md, your annotations, your findings)
- Apply concepts immediately and test your understanding
- Bring evidence when you're confused ("Here's the line that doesn't make sense...")

**Me:**
- Ask guiding questions instead of giving answers
- Help you think through problems systematically
- Validate or challenge your understanding
- Point you to resources and ask you to try solutions
- Catch false confidence and push for deeper understanding

### Example Teaching Dialogue (Works for All 4 Weeks)

**Week 1 - Script Understanding:**
- You: "I don't understand this database query in mentions.py"
- Me: "What do you think this WHERE clause is checking for? What data would match it?"
- You: [thinks through it] "It seems like it's filtering by date range..."
- Me: "Good hypothesis. Now look at the code—what dates are being compared? Can you trace where those dates come from?"
- You: [looks again] "Oh, it's comparing database values to a config variable..."
- Me: "Exactly. So what would happen if someone ran this with a config date in the future?"
- You: [realizes issue] "Oh no. It would never find any data..."
- Me: "Now test that. Run the query with a future date. What actually happens?"

**Week 2 - Database Integration:**
- You: "I'm not sure what this INSERT statement is doing"
- Me: "What tables does it touch? What columns does it populate?"
- You: [traces through] "It's adding a row to orbat.mentions with unit_id, text, and date"
- Me: "Good. Now—what validates that the unit_id actually exists in the database?"
- You: [looks at constraints] "Oh, there's a foreign key constraint!"
- Me: "So what happens if you try to insert a mention for a unit that doesn't exist?"
- You: "The database would reject it"
- Me: "Have you tested that scenario?"

**Week 3 - Failure Analysis:**
- You: "So what happens if the database connection fails?"
- Me: "Good question. Let me turn that back—where in your code does the connection happen? What would that error look like?"
- You: [finds the code] "It's here... it would probably raise an exception"
- Me: "What exception? What would the error message say?"
- You: [runs test] "It says 'could not connect to server'"
- Me: "Great. So how would you test that your recovery procedure actually works?"

**Week 4 - Mastery:**
- You: "I want to add a feature to skip old mentions"
- Me: "Okay. Walk me through your plan—what would change?"
- You: [explains changes]
- Me: "Good. Now—what could break? What existing functionality might this affect?"
- You: [thinks through consequences]
- Me: "How would you test that nothing broke?"
- You: [designs tests]
- Me: "Excellent. Go do it. Show me when you're done."

---

## Focus Area 1 Complete Deliverables

### By End of Week 4, You Will Have:

**Core Understanding Documentation:**
- [ ] Script_Explanation.md (2+ scripts fully explained)
- [ ] Database_Operations.md (all queries analyzed)
- [ ] Script_Map.md (complete data flow with diagrams)
- [ ] Common_Errors.md (5+ failure scenarios)
- [ ] Failure_Recovery_Runbook.md (recovery procedures)
- [ ] Testing_Plan.md (how to test safely)
- [ ] Automation_Runbook.md (complete system overview)
- [ ] Design_Analysis.md (why decisions were made this way)
- [ ] Concept_Library.md (50+ entries on coding/database concepts)

**Code & Configuration:**
- [ ] All scripts with meaningful comments
- [ ] Clean, organized GitHub repository
- [ ] README.md (professional introduction)
- [ ] .gitignore (Python template)
- [ ] Meaningful commit history (10+ commits)

**Progress & Reflection:**
- [ ] Progress_Week_01.md through Progress_Week_04.md
- [ ] Weekly reflections on learning
- [ ] Self-assessment of confidence levels
- [ ] Clear understanding of what you still want to learn

---

## Success Criteria for Focus Area 1

### You're Ready to Move On to Focus Area 2 If:

1. **Complete Understanding:** You can explain your entire automation system to someone else without looking at the code
2. **Comprehensive Documentation:** All 8+ deliverable documents are complete and comprehensive
3. **Version Control:** Your code is well-organized in GitHub with meaningful commit history
4. **Debugging Capability:** You can identify and diagnose failures independently using your runbooks
5. **Testing Knowledge:** You understand how to test changes safely and would verify them
6. **Confidence:** You feel true ownership of this code—it's yours to maintain and modify
7. **Pattern Recognition:** You can spot potential issues before they happen and understand design trade-offs

### Red Flags (Let's Adjust If This Happens):

- You're still treating any part of your automation as "magic"
- You can't trace data flow from input through database to output
- You don't understand why specific design choices were made
- You haven't tested recovery procedures
- You couldn't explain the system to a colleague
- You feel rushed or confused—understanding > speed

---

## Next Phase Preview

**After Week 4:** You'll complete Focus Area 1 with complete mastery of your existing scripts.

**Week 5 onward (Focus Area 2):** PostgreSQL DBA Fundamentals
- Deep dive into database architecture
- Learn SQL fundamentals through your actual queries
- Start building a database administration runbook
- Learn backup and disaster recovery

**But that's later.** Focus on these 4 weeks now.

---

## Notes for You (Weeks 1-4)

### This Focus Area Is Foundational

Everything you do in Phase 1 depends on understanding your code. Don't rush. Understanding beats speed.

By Week 4, you won't just know how to run your scripts—you'll own them completely. That ownership is valuable.

### Specificity Matters

When you ask questions, include:
- Exact line of code (or query, or error message) you're confused about
- What you think it does
- What's confusing you specifically
- What you've tried so far
- Your working hypothesis

Generic questions ("What does INSERT do?") get generic answers. Specific questions with evidence get real learning.

### You're Building Understanding, Not Just Reading

The difference between "I read the code" and "I understand the code" is that you can:
- Explain it in your own words to someone else
- Predict what happens if you change something
- Identify where failures could happen
- Modify it without breaking things
- Debug it when something goes wrong
- Design tests to verify it works

That's what these 4 weeks are about.

### Each Week Builds on the Last

- Week 1: Deep script understanding
- Week 2: Database integration understanding
- Week 3: Failure scenario knowledge
- Week 4: Full mastery and confidence

Don't skip ahead. The foundation matters.

### Celebrate the Progress

- Week 1: You understand your code ✅
- Week 2: You see the database interaction ✅
- Week 3: You can diagnose failures ✅
- Week 4: You own your system ✅

These are real accomplishments. Each one is a level-up in capability.

---

## Questions? Start a Chat!

When you hit blockers:
1. Try TEACHING MODE first—think through it before asking
2. Show me your work (your documentation, annotated code, your findings)
3. Ask specific questions about specific things
4. Tell me what you've tried and what you think is happening

I'm here to help you understand, not to give you answers.

---

**Phase 1, Focus Area 1 starts now.** 

**Week 1:** Monday, November 17, 2025

**You've got this. Let's go.** 🚀

*Your Phase 1 Classroom*  
*Focus Area 1: Understanding My Existing Scripts*  
*Weeks 1-4 of Phase 1*  
*60 hours of deep learning*
