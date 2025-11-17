# Week 1 Detailed Session Plan

**Date:** November 17-21, 2025  
**Phase:** Phase 1, Week 1  
**Focus Areas:** Scripts Understanding + Git Setup  
**Total Time:** 15 hours (2.5 hours Monday, 4-5 hours each Tue-Thu, 2 hours Friday)

---

## Monday: Planning & Reflection Day

**Time:** 2.5 hours  
**Objective:** Get clear on where you are and where you're going

### Monday Morning (30 min)

**Task: Set up your Week 1 tracker**

1. Copy `Progress_Tracker_Template.md` 
2. Save as: `Progress_Week_01.md`
3. Fill in:
   - Date: November 17, 2025
   - Phase: Phase 1, Week 1
   - Status: Starting

### Monday Reflection (2 hours)

**Answer these three questions (write them down, be honest):**

**Question 1: What's the single most important thing for me to understand about my current automation?**
- Think about: What runs? What could break? What do I rely on but don't fully understand?
- Example answers: "How position_update_v3.py works", "When data goes in, where does it come out?", "What happens if X fails?"
- Write 2-3 sentences explaining your choice

**Question 2: What's the one database concept I'm shakiest on right now?**
- Think about: What makes me uncomfortable? What do I avoid touching? What could I explain vs. not explain?
- Example answers: "How users and permissions work", "What a transaction is", "How indexes help"
- Write 2-3 sentences

**Question 3: What's my biggest fear about this learning journey?**
- Be honest. No judgment.
- Example answers: "I'll fall behind", "I'll break something in production", "I'm not smart enough for this", "I'll get bored and quit"
- Write 2-3 sentences

**Why this matters:** These answers help me understand how to help you. They're not graded; they're directional.

### Monday Schedule Planning (30 min)

**Block out your week on your calendar:**

- Tuesday 2-5 PM: Session 1 (Script Walkthrough)
- Wednesday 1-4 PM: Session 2 (GitHub Setup)
- Thursday 3-6 PM: Session 3 (Documentation Start)
- Friday 4-5 PM: Review & Planning

**Adjust to fit your schedule.** The times matter less than consistency.

---

## Tuesday: Deep Script Walkthrough

**Time:** 3-4 hours  
**Objective:** Understand what your main automation script does, line by line  
**Output:** First entries in Concept_Library.md + initial comments in script

### Before You Start (5 min)

1. Open your main automation script (likely `position_update_v3.py`)
2. Open Progress_Week_01.md
3. Have a text editor open for notes
4. Have Python documentation available (https://docs.python.org/)

### Part 1: Read-Through (1 hour)

**Read the entire script slowly.** Don't code anything yet. Just read.

As you read, note:
- What are the imports? (What does this script need?)
- What functions exist? (What are the big pieces?)
- What is the script trying to accomplish? (One sentence summary)
- What looks familiar? (What Python do you already know?)
- What looks confusing? (Mark it)

**Write down (in Progress_Week_01.md):**
- Script name and purpose (1-2 sentences)
- List of imports (what does it depend on?)
- List of functions (what are the pieces?)
- 2-3 things that confuse you

### Part 2: Line-by-Line Understanding (1.5-2 hours)

**Now go through it line by line.**

**For each major section:**

1. **Read the code**
   - What is this doing?
   - What would you expect to happen if this code runs?

2. **Test your understanding**
   - Add a comment: `# This does [what I think it does]`
   - Trace variables: if X = something here, what is X by the end of this section?

3. **Look for patterns**
   - Have you seen this pattern before?
   - Is this similar to something else in the script?
   - Could you do this a different way?

4. **Find the confusing parts**
   - Which lines don't make immediate sense?
   - Where do you have to "trust" the code rather than understand it?
   - Mark these with `# CONFUSING:` comment

**Examples of annotations:**
```python
# This function takes raw position data and validates it
def validate_position(data):
    # Check: does the data have all required fields?
    if not all(key in data for key in ['lat', 'lon', 'unit_id']):
        # If not, return error (don't process bad data)
        return False
    # If it passed validation, return True
    return True
```

### Part 3: Concept Capture (30 min)

**Add to Concept_Library.md (new file or section):**

For each new Python concept you encounter, add an entry:

```markdown
## [Concept Name]

**Definition (in your words):** 
[Explain what this is]

**Example from position_update_v3.py:**
[Show the code line or pattern]

**Why it matters:**
[How does this help you understand the script?]

**Confusion points:**
[Anything that's still unclear?]
```

**Example entries:**
```markdown
## List Comprehension

**Definition:** A compact way to create a list from another list

**Example from script:**
valid_records = [r for r in records if validate(r)]

**Why it matters:**
Much faster and cleaner than using a for loop with append()

**Confusion points:**
Still not sure when to use versus for loop
```

### Tuesday Wrap-up (15 min)

**In Progress_Week_01.md, log:**
- Time spent: [X] hours
- What I understood: [summary]
- What's still confusing: [list]
- Questions for Claude: [list]
- Blocks: [any issues?]

### If You Get Stuck

**Come to me (Claude) with:**
```
TEACHING MODE

I'm reading position_update_v3.py and I don't understand 
the [specific part].

Here's what I think is happening: [your interpretation]
Here's what confuses me: [specific issue]

Before you explain, can you help me:
1. What is the purpose of this section?
2. What would break if this didn't exist?
3. How would you test if this is working?
```

---

## Wednesday: GitHub Setup

**Time:** 3-4 hours  
**Objective:** Get your code in version control, understand Git basics  
**Output:** GitHub repository with all scripts committed

### Part 1: GitHub Account & Git Installation (30 min)

**If you don't have GitHub:**
1. Go to https://github.com
2. Click "Sign up"
3. Create account (use professional name/email)
4. Verify email

**If you don't have Git installed:**
1. Go to https://git-scm.com/downloads
2. Download for your operating system
3. Install with default settings
4. Open terminal/command prompt and type: `git --version`
   - You should see a version number

### Part 2: Create Your Repository (30 min)

**On GitHub:**
1. Click "New repository" (usually top left)
2. Name: `isw-orbat-automation` (or similar)
3. Description: "Automation scripts for Russian ORBAT database"
4. Choose "Private" (only you can see it, unless you want public)
5. Check "Add a README file"
6. Click "Create repository"

**You now have an empty repository!**

### Part 3: Set Up Locally (1 hour)

**On your computer:**

1. Create a folder: `C:\Users\[YourName]\Projects\isw-orbat-automation`
   (or `/Users/[YourName]/Projects/isw-orbat-automation` on Mac/Linux)

2. Copy all your scripts into this folder:
   - position_update_v3.py
   - Any other automation scripts
   - Any config files (but NOT database credentials!)

3. Create `.gitignore` file (tells Git what NOT to commit):
   ```
   # Don't commit credentials or secrets
   credentials.json
   passwords.txt
   .env
   
   # Don't commit large files
   *.csv
   *.zip
   
   # Python stuff
   __pycache__/
   *.pyc
   ```

4. Open terminal in that folder
5. Run:
   ```bash
   git init
   git add .
   git config user.name "Your Name"
   git config user.email "your.email@example.com"
   git commit -m "Initial commit: add existing automation scripts"
   ```

6. Link to GitHub:
   - Go back to your GitHub repository page
   - Click "Code" (green button)
   - Copy the HTTPS URL
   - In terminal, run:
   ```bash
   git remote add origin [paste-the-URL]
   git branch -M main
   git push -u origin main
   ```

**Your code is now on GitHub!**

### Part 4: Update README (30 min)

**Edit the README.md file in your repository:**

```markdown
# ISW Russian ORBAT Automation

Automation scripts for maintaining the Russian Order of Battle database.

## Scripts Included

- `position_update_v3.py` - Updates unit positions from intelligence sources
- [Other scripts]

## What These Scripts Do

[Brief description of your automation]

## Prerequisites

- Python 3.x
- PostgreSQL connection to [your database name]
- Required libraries: [psycopg2, arcpy, etc.]

## How to Use

[Step by step for someone running these scripts]

## Database Requirements

- Database: [name]
- Tables: [list key tables]
- Permissions: [what does the database user need?]

## Troubleshooting

[Common issues and how to fix them]

## Author

[Your name]

## Last Updated

[Today's date]
```

**Commit this update:**
```bash
git add README.md
git commit -m "Update README with script descriptions"
git push
```

### Wednesday Wrap-up (15 min)

**In Progress_Week_01.md, log:**
- Time spent: [X] hours
- Repository created: [yes/no]
- All scripts committed: [yes/no]
- README written: [yes/no]
- Questions for Claude: [any Git confusion?]
- Blocks: [any issues?]

### If You Get Stuck

**Come to me (Claude) with:**
```
I'm trying to [specific Git task] and I'm getting this error:
[error message]

I've already tried: [what you tried]
I think the problem is: [your hypothesis]
```

---

## Thursday: Documentation & Script Map Start

**Time:** 3-4 hours  
**Objective:** Start mapping your entire automation architecture  
**Output:** Script Map document outline + begin detailed entries

### Part 1: Create Script Map Framework (1 hour)

**Create new file: `Script_Map.md`**

```markdown
# Automation Architecture Map

**Last Updated:** November 17, 2025
**Purpose:** Document all scripts, what they do, and how they interact

---

## High-Level Architecture

[You'll diagram this]

---

## Scripts Overview

| Script Name | Purpose | Runs When | Dependencies |
|-------------|---------|-----------|--------------|
| [name] | [what] | [when] | [what does it need] |
| ... | ... | ... | ... |

---

## Detailed Scripts

### [Script Name 1]

**File:** position_update_v3.py
**Purpose:** [What does this script accomplish?]
**Runs:** [When does this run? Manual? Scheduled? Triggered by something?]

**Inputs:**
- Data source 1: [What data comes in?]
- Data source 2: [Another source?]

**Processing:**
- Step 1: [What happens]
- Step 2: [What happens]
- Step 3: [What happens]

**Outputs:**
- Output 1: [Where does data go?]
- Database updates: [What tables change?]

**Dependencies:**
- Requires: [Python libraries]
- Needs: [Database connection]
- Expects: [Data formats]

**Error Handling:**
- What if [input missing]? → [what happens]
- What if [database down]? → [what happens]

**Key Functions:**
- `function_name()` - [what it does]
- `function_name()` - [what it does]

**Potential Issues:**
- [Issue 1]: [How to fix]
- [Issue 2]: [How to fix]

**Last Successfully Run:** [date/time]
**Notes:** [Anything special about this script?]

---

### [Script Name 2]
[Same structure]

---

## Dependencies & Flow

Script 1 → Database → Script 2 → Script 3 → Report

---

## Execution Schedule

| Time | What Runs |
|------|-----------|
| 6:00 AM | [Script 1] |
| 8:00 AM | [Script 2] |
| ... | ... |

---

## Known Limitations & Future Improvements

- [Limitation 1]
- [Limitation 2]
- [Improvement idea 1]
```

### Part 2: Fill in First Script (1.5-2 hours)

**Choose your main script. Go deep.**

For position_update_v3.py (or your main script):

1. **Read through completely** (you did this Tuesday)

2. **Document each piece:**
   ```markdown
   ### position_update_v3.py

   **Purpose:** 
   [In your own words, what is this script accomplishing?]

   **Runs:**
   [When? Time? Triggered by something? Manual?]

   **Data Sources:**
   [Where does input come from?]

   **Processing Steps:**
   [What does it actually do? Break it into logical chunks]

   **Database Changes:**
   [What tables does it update? How?]

   **Error Scenarios:**
   [What could go wrong? What happens then?]

   **Key Parts:**
   - Connection string: [where does it connect?]
   - Functions: [what are the main functions?]
   - Critical variables: [what important things get calculated?]
   ```

3. **Ask yourself:**
   - Could I run this script without documentation and understand what it did? (Be honest)
   - What would happen if a colleague ran this without asking me?
   - Where is the riskiest part (most likely to fail)?

### Part 3: Start Concept Library (30 min)

**Create Concept_Library.md:**

```markdown
# Concept Library: Phase 1

Growing glossary of technical terms I'm learning

---

## Python Concepts

### Function
**Definition:** A reusable block of code that does something

**Example from my scripts:**
[Code example]

**Why it matters:**
Functions let me reuse code instead of copy/pasting

**Real-world example:**
[How this applies to my work]

---

### Variables
**Definition:** Named containers that hold values

**Example from my scripts:**
[Code example]

**Why it matters:**
Variables let me store and manipulate data

---

## Database Concepts

### Table
**Definition:** Organized collection of related data (like a spreadsheet)

**Example from my database:**
The `units` table stores information about military units

**Why it matters:**
Data is organized in tables so I can query it

---

## Git Concepts

### Repository
**Definition:** A folder that contains your code and its complete history

**Example from my work:**
isw-orbat-automation is my repository

**Why it matters:**
I can track changes and go back to previous versions

---
```

**Add 5-10 entries (new concepts you've learned this week)**

### Thursday Wrap-up (15 min)

**In Progress_Week_01.md, log:**
- Time spent: [X] hours
- Script Map started: [yes/no]
- Scripts detailed: [which ones?]
- Concept Library entries: [how many?]
- Questions for Claude: [any?]
- Blocks: [any issues?]

### If You Get Stuck

**Come to me (Claude) with:**
```
I'm creating my Script Map and I'm not sure how to document [part].

The script does: [what you understand]
The confusing part: [what's unclear]

Should I document: [your proposed approach]?
```

---

## Friday: Review & Reflection

**Time:** 2 hours  
**Objective:** Complete Week 1, celebrate, plan next week

### Friday Review Session (1.5 hours)

**Complete your Progress_Week_01.md:**

1. **Time Log:**
   ```
   Monday: 2.5 hours - Planning & Reflection
   Tuesday: 3.5 hours - Script walkthrough
   Wednesday: 3.5 hours - GitHub setup
   Thursday: 3.5 hours - Script Map start
   Friday: 1.5 hours - Review
   TOTAL: 15 hours
   ```

2. **What I Learned This Week:**
   - [Key insight 1]
   - [Key insight 2]
   - [Key insight 3]

3. **Success Wins:**
   - [ ] Created GitHub repository
   - [ ] Committed all scripts
   - [ ] Understand position_update_v3.py
   - [ ] Started Script Map
   - [ ] Created Concept Library
   - [ ] Comfortable with TEACHING MODE

4. **Challenges:**
   - [Challenge 1]: [How I handled it]
   - [Challenge 2]: [How I handled it]

5. **Still Confused About:**
   - [Topic 1]
   - [Topic 2]

6. **Questions for Next Week:**
   - [Question 1]
   - [Question 2]

7. **Week Rating:** [1-5 stars] - Why?

### Commit Your Work (15 min)

```bash
git add Script_Map.md
git add Concept_Library.md
git add Progress_Week_01.md
git commit -m "Week 1 complete: Documentation and setup"
git push
```

### Friday Reflection Questions (20 min)

**Answer honestly:**

1. **How am I feeling?**
   - Energized? Overwhelmed? Confident? Confused?
   - What's driving that feeling?

2. **What surprised me this week?**
   - Something harder than expected?
   - Something easier than expected?
   - Something I discovered about my code?

3. **What went well?**
   - What felt productive?
   - What felt good to learn?
   - What made sense?

4. **What needs adjustment?**
   - Schedule? Time allocation?
   - Type of learning?
   - Focus areas?
   - Pace?

### Look Ahead: Week 2 Preview (15 min)

**Next week you'll:**
- Dive deeper into your second script
- Start learning PostgreSQL basics
- Set up database administration runbook
- Continue GUI/Git learning

**What you'll need:**
- Access to your PostgreSQL server
- List of tables and what they contain
- Understanding of how data flows

### Final Celebration (5 min)

**You just completed Week 1 of a 12-week learning journey.**

**What you've done:**
✅ Organized your code in GitHub  
✅ Started understanding your automation  
✅ Documented what you're learning  
✅ Created a learning system  
✅ Asked good questions in TEACHING MODE  

**That's real progress.**

---

## Resources for This Week

**For Python/Scripts:**
- Official Python docs: https://docs.python.org/3/
- Your scripts (the best resource!)

**For Git:**
- Git Book (free): https://git-scm.com/book/en/v2
- GitHub Guides: https://guides.github.com/

**For Documentation:**
- Markdown formatting: https://www.markdownguide.org/basic-syntax/

---

## Next Week Check-In

**After Week 1, we'll review:**
1. Did you complete all three sessions?
2. What's in your GitHub repository?
3. Are you comfortable with TEACHING MODE?
4. What confuses you most about your scripts?
5. What should we focus on in Week 2?

---

**Welcome to Week 1. Let's go.**
