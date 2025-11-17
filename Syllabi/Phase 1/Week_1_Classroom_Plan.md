# Week 1 Classroom Lesson Plan
## Phase 1: Consolidation & Confidence

**Student:** Nate Kramer  
**Start Date:** Monday, November 17, 2025  
**Phase:** Phase 1, Week 1 of 12  
**Total Hours:** 15 hours (sustainable pace)  
**Learning Mode:** TEACHING MODE (default)

---

## Your Reflection Answers (Set on Monday, Nov 17)

### Question 1: What's the single most important thing for me to understand about my automation?

**Your Answer:**
> The problematic areas where a unit mention might not insert properly.

**Why This Matters:**
This tells me you're thinking about **reliability and failure points**—exactly the right mindset for someone managing production systems. Instead of just "how does the code work," you're asking "where does it break?" That's sophisticated thinking.

This week, when you read your mentions.py script, focus on:
- The insertion logic (how does a mention actually get written to the database?)
- What conditions must be true for an insert to succeed?
- What would cause an insert to fail silently vs. loudly?

---

### Question 2: What's the one database concept I'm shakiest on right now?

**Your Answer:**
> Too many to list.

**Translation:**
This is honest. You're comfortable enough with SQL basics to query, but database architecture, permissions, backups, and optimization are still fuzzy. That's completely normal for someone transitioning from "data analyst who writes queries" to "engineer who manages systems."

**This week's approach:**
Don't try to learn everything. As you read mentions.py, simply notice:
- Where does it connect to the database? (Which table?)
- What does it write? (INSERT? UPDATE? Both?)
- What assumptions does it make about the database? (Does it expect certain columns? Certain constraints?)

By the end of this week, you won't be a DBA, but you'll know which database questions to ask next.

---

### Question 3: What's my biggest fear about this learning journey?

**Your Answer:**
> Burning out—from either going too fast, or from the syllabus being too slow.

**How We'll Prevent This:**

**If the pace feels too fast:**
- The syllabus is *flexible*, not rigid
- Tell me: "This is moving too fast" and we slow down
- It's better to spend 2 weeks deeply understanding something than 1 week skimming it

**If the pace feels too slow:**
- You can combine weeks (e.g., do Weeks 1-2 together)
- We can add deeper challenges
- You can propose different focus areas

**The safety valve:** We check in every Friday. If something isn't working, we adjust.

**Real talk:** You're managing a production database and intelligence analysis. Sustainable learning is better than burnout. If you need to skip a week, that's okay. The goal is December 9, 2025, not November 24.

---

## Your 5 Focus Areas This Week

### Focus Area 1: Understanding Your Existing Scripts

**Primary Goal:** Understand mentions.py thoroughly (and any related scripts)

**Why This One First:** You can't fix "problematic areas where a unit mention might not insert properly" unless you understand the insertion logic. This is the foundation.

**This Week's Work:**

**Tuesday Session (3-4 hours): Deep Script Walkthrough**
- Read mentions.py completely
- Mark confusing sections with comments
- Trace the path: what data comes in → what logic happens → what gets written to DB
- Add 5-10 entries to Concept Library

**Thursday Session (2 hours): Documentation Start**
- Create detailed script map for mentions.py
- Document: inputs, processing steps, outputs, potential failure points
- Identify: which functions do the critical work?

**Deliverable by Friday:**
- Annotated mentions.py with comments
- Script_Map.md with mentions.py documented in detail
- Concept Library entries (Python concepts you encounter)

**Success Looks Like:**
You can explain to someone: "Here's how a unit mention gets inserted into the database, and here are three things that could go wrong."

---

### Focus Area 2: PostgreSQL Fundamentals for DBAs

**Primary Goal:** Understand which database concepts your scripts depend on

**Why This One Second:** You can't fix database problems if you don't understand how your code interacts with the database.

**This Week's Work:**

**Tuesday Session (Integrated):** As you read mentions.py, pay attention to:
- What table(s) does it write to?
- What columns does it expect to exist?
- What data types are being inserted?
- Does it use transactions? (Do you commit? Do you rollback?)

**Thursday Session (Integrated):** In your Script Map, document:
- Database tables involved
- Insert/update statements
- Error handling around database operations

**Key Questions to Answer:**
1. What happens if the database connection drops mid-insert?
2. What validation happens before data is written?
3. Could a mention be inserted halfway and then fail? How would you know?

**Deliverable by Friday:**
- Script_Map.md with database details clearly noted

**Success Looks Like:**
You understand which database features your code is using (transactions, constraints, indexes, etc.), even if you don't fully understand those features yet.

---

### Focus Area 3: Debugging Fundamentals

**Primary Goal:** Recognize failure points and start debugging patterns

**Why This One Third:** Understanding where things can break is the foundation of debugging.

**This Week's Work:**

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

**Why This One Fourth:** This enables everything else. You can't learn if your code isn't organized.

**This Week's Work:**

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

### Focus Area 5: GUI Development Basics

**Primary Goal:** Understand what a GUI launcher would do for your team

**Why This One Fifth:** GUI development builds on scripts, databases, and debugging. You'll touch it lightly this week to understand the opportunity.

**This Week's Work:**

**Thursday Session (Integrated, 20 min):** Research and planning
- What tasks does your team do manually that could have a GUI?
- What would a simple launcher look like?
- Note initial ideas (don't build yet—just think)

**Why Now:** You'll start GUI development in Week 4 once scripts and Git are solid. This week is just understanding the "why."

**Deliverable by Friday:**
- Notes on: "What could a GUI launcher do for my team?"

**Success Looks Like:**
You have 2-3 concrete ideas for how a GUI tool could help your team.

---

## Your Weekly Schedule

### Monday, November 17 (2.5 hours)
**Theme: Planning & Reflection**

- [ ] Copy Progress_Tracker_Template.md → Progress_Week_01.md
- [ ] Fill in your three reflection questions (you did this! ✓)
- [ ] Block out time on your calendar:
  - Tuesday 2-5 PM: Session 1 (Script Walkthrough)
  - Wednesday 1-4 PM: Session 2 (GitHub Setup)
  - Thursday 3-6 PM: Session 3 (Documentation)
  - Friday 4-5 PM: Review
- [ ] Create folder structure locally (optional but helpful)

**Time Allocation:** 30 min + 2 hours reflection + 30 min scheduling

---

### Tuesday, November 18 (3-4 hours)
**Theme: Deep Script Walkthrough**

**Objective:** Understand mentions.py completely

**What You'll Do:**

1. **Read-Through (1 hour)**
   - Open mentions.py in your editor
   - Read the entire file slowly (don't code yet)
   - Note in Progress_Week_01.md:
     - What does this script do? (1-2 sentence summary)
     - What are the imports? (What does it need?)
     - What functions exist?
     - What's confusing?

2. **Line-by-Line Understanding (1.5-2 hours)**
   - Go through each major section
   - Add comments like: `# This validates that the unit_id exists before inserting`
   - Trace variables: if X starts here, what is X at the end?
   - Mark confusing parts with `# CONFUSING:` comments
   - Think about each section: "What could break here?"

3. **Concept Capture (30 min)**
   - For each new Python concept you see, add to Concept_Library.md:
     - What is it? (definition in your words)
     - Where do you see it in mentions.py?
     - Why does it matter?
     - What's still confusing?

**Example Concept Entry:**
```markdown
## List Comprehension

**Definition:** A compact way to create a new list by filtering or transforming an existing list

**Example from mentions.py:**
valid_mentions = [m for m in mentions if m['unit_id'] in unit_list]

**Why it matters:**
More efficient and readable than using a loop with append()

**Confusion points:**
Still learning when to use vs. regular for loop
```

**Tuesday Wrap-up (15 min):**
Log in Progress_Week_01.md:
- Time spent
- What you understood
- What's still confusing
- Questions for Claude

---

### Wednesday, November 19 (3-4 hours)
**Theme: GitHub Setup & Version Control**

**Objective:** Get your code in version control

**What You'll Do:**

1. **GitHub Account & Git Installation (30 min)**
   - If you don't have GitHub: https://github.com → Sign up
   - If you don't have Git installed: https://git-scm.com/downloads
   - Verify installation: Open terminal → `git --version`

2. **Create Your Repository (30 min)**
   - Log into GitHub
   - Click "New repository"
   - Name: `isw-orbat-automation` (or similar)
   - Description: "Automation scripts for Russian ORBAT database"
   - Private (only you can see)
   - Check "Add a README file"
   - Create

3. **Set Up Locally (1 hour)**
   - Create folder: `~/Projects/isw-orbat-automation`
   - Copy all scripts into this folder
   - Create `.gitignore` file:
     ```
     # Don't commit secrets
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
   - Open terminal in that folder
   - Run these commands:
     ```bash
     git init
     git add .
     git config user.name "Your Name"
     git config user.email "your.email@example.com"
     git commit -m "Initial commit: add existing automation scripts"
     ```
   - Link to GitHub (copy HTTPS URL from your repo page):
     ```bash
     git remote add origin [paste-the-URL]
     git branch -M main
     git push -u origin main
     ```

4. **Update README (30 min)**
   - Edit README.md in your repository:
     ```markdown
     # ISW Russian ORBAT Automation

     Automation scripts for maintaining the Russian Order of Battle database.

     ## Scripts

     - `mentions.py` - Processes unit mentions from intelligence sources
     - [Other scripts]

     ## What These Scripts Do

     [Brief description]

     ## Setup

     - Python 3.x
     - PostgreSQL connection
     - psycopg2, arcpy, etc.

     ## How to Use

     [Step by step]

     ## Database Requirements

     - Database: [name]
     - Key tables: [list]

     ## Troubleshooting

     [Common issues]

     ## Last Updated

     Nov 17, 2025
     ```
   - Commit:
     ```bash
     git add README.md
     git commit -m "Update README with script descriptions"
     git push
     ```

**Wednesday Wrap-up (15 min):**
Log in Progress_Week_01.md:
- Time spent
- Repository created: [yes/no]
- All scripts committed: [yes/no]
- README updated: [yes/no]
- Any Git issues: [notes]

---

### Thursday, November 20 (3-4 hours)
**Theme: Script Documentation & Analysis**

**Objective:** Document mentions.py in detail; create Script Map

**What You'll Do:**

1. **Create Script_Map.md (1.5-2 hours)**
   
   Create a new file called `Script_Map.md` with this structure:

   ```markdown
   # Script Map: Automation Architecture

   ## mentions.py

   **Purpose:** [What does this script accomplish? 2-3 sentences]

   **When It Runs:** [Time? Triggered? Manual? Frequency?]

   **Data Sources:**
   - Source 1: [Where does data come from?]
   - Source 2: [Another source?]

   **Processing Steps:**
   1. [What happens first?]
   2. [What happens next?]
   3. [What happens last?]

   **Outputs:**
   - Primary output: [Where does data go?]
   - Database tables updated: [Which tables?]
   - Side effects: [Anything else that happens?]

   **Database Operations:**
   - Tables accessed: units, mentions, etc.
   - INSERT/UPDATE/DELETE statements: [which ones?]
   - Transactions: [Does it use them? How?]
   - Constraints: [What must be true for success?]

   **Key Functions:**
   - `function_name()` - [What it does]
   - `function_name()` - [What it does]

   **Error Handling:**
   - If [input missing] → [what happens]
   - If [DB down] → [what happens]
   - If [bad data] → [what happens]

   **Critical Failure Points:**
   - **Point 1:** [Where/why it could break]
   - **Point 2:** [Where/why it could break]
   - **Point 3:** [Where/why it could break]

   **Dependencies:**
   - Python libraries: psycopg2, arcpy, etc.
   - Database version: PostgreSQL X.X+
   - Data format: [expected format of inputs]

   **Known Issues:**
   - [Issue]: [How to work around]

   **Last Successfully Run:** [Date/time]
   **Notes:** [Anything else?]
   ```

2. **Document Potential Problems (1-1.5 hours)**

   In your Script_Map, specifically focus on:
   - Where a unit mention might not insert properly (your #1 priority!)
   - What validation happens before insertion?
   - What could cause a silent failure vs. a loud error?
   - How would you know if a mention was inserted incorrectly?

   Create a "Failure Scenarios" section:
   ```markdown
   ## Failure Scenarios for mentions.py

   ### Scenario 1: Duplicate Mention Inserted
   **What happens:** Same mention gets inserted twice
   **Why:** No unique constraint checking
   **How to detect:** Check database for duplicates
   **How to fix:** Add UNIQUE constraint or check before insert

   ### Scenario 2: Missing Unit Reference
   **What happens:** Mention inserted but references wrong unit
   **Why:** [Your analysis]
   **How to detect:** [Your approach]
   **How to fix:** [Your proposal]

   ### Scenario 3: Partial Insert (Transaction Fails)
   **What happens:** [Your analysis]
   **Why:** [Your analysis]
   **How to detect:** [Your approach]
   **How to fix:** [Your proposal]
   ```

3. **Add to Concept Library (30 min)**

   Add 3-5 new concepts you encountered:
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

**Thursday Wrap-up (15 min):**
Log in Progress_Week_01.md:
- Time spent
- Script_Map.md created: [yes/no]
- Failure scenarios documented: [how many?]
- Concept Library entries added: [count]
- Questions for Claude: [list]

---

### Friday, November 21 (2 hours)
**Theme: Review, Reflection, and Planning**

**Objective:** Complete Week 1, celebrate progress, plan Week 2

**What You'll Do:**

1. **Complete Progress_Week_01.md (1 hour)**

   Fill in your complete weekly summary:

   **Time Log:**
   ```
   Monday: X hours - Planning & Reflection
   Tuesday: X hours - Script walkthrough
   Wednesday: X hours - GitHub setup
   Thursday: X hours - Script Map & documentation
   Friday: X hours - Review
   TOTAL: X hours
   ```

   **What I Learned This Week:**
   - [Key insight 1]
   - [Key insight 2]
   - [Key insight 3]

   **Accomplishments:**
   - [ ] Created GitHub repository
   - [ ] Committed all scripts
   - [ ] Understand mentions.py completely
   - [ ] Started Script Map
   - [ ] Created Concept Library
   - [ ] Documented failure scenarios

   **Challenges:**
   - [Challenge 1]: [How I handled it]
   - [Challenge 2]: [How I handled it]

   **Still Confused About:**
   - [Topic 1]
   - [Topic 2]

   **Week Rating (1-5 stars):** [X] - Why?

2. **Commit Your Work (15 min)**

   ```bash
   git add Script_Map.md
   git add Concept_Library.md
   git add Progress_Week_01.md
   git add Common_Errors.md
   git commit -m "Week 1 complete: Script documentation, GitHub setup, concept library"
   git push
   ```

3. **Reflection Questions (30 min)**

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

   **5. Am I worried about burning out?**
   - If pace feels too fast, tell me now
   - If pace feels too slow, tell me now
   - We can adjust

---

## What Success Looks Like at Week 1

### By End of Friday (Nov 21), You'll Have:

✅ **GitHub Repository**
- All code committed
- Professional README
- .gitignore configured
- At least 3 meaningful commits

✅ **Script Documentation**
- mentions.py fully annotated with comments
- Script_Map.md with complete details
- Failure scenarios documented (your priority!)
- Database operations noted

✅ **Concept Library**
- 8-12 Python concepts documented
- 3-5 Database concepts started
- 2-3 Git concepts included
- All in your own words

✅ **Understanding**
- Can explain what mentions.py does
- Can identify 3 ways a mention might fail to insert
- Can trace the data flow from source to database
- Know which database concepts to focus on next

✅ **Progress Tracker**
- Complete week log
- Reflection questions answered
- Challenges and wins documented
- Ready for Week 2 planning

---

## Important Notes for Week 1

### On Pace

You asked about burning out from the pace. Here's the reality:
- **Too fast?** Tell me. We slow down.
- **Too slow?** Tell me. We speed up.
- **Just right?** Great. We keep going.

I'm checking in with you every week. This isn't a race.

### On Database Concepts

You said there are "too many database concepts" to list. That's fine. Don't try to learn them all this week. Focus on:
- Where your code touches the database
- What assumptions it makes
- What could break

Everything else comes later.

### On "Problematic Areas"

You want to understand where mentions might not insert properly. This is the single most important thing for Week 1. When you read mentions.py:
- Every time you see an INSERT or UPDATE, stop
- Ask: "What could go wrong here?"
- Mark it in your Script Map

By Friday, you should have a list of 3-5 specific concerns about insertion reliability.

### On TEACHING MODE

Default: I'll guide you with questions rather than give answers.

Example:
- You: "I don't understand this SQL query in mentions.py"
- Me: "What do you think this WHERE clause is checking for? What data would match?"
- You: [thinks through it]
- Me: "Now test that hypothesis by running the query. What did you get?"

**Why:** This builds real understanding. You'll remember better, and you'll be able to debug similar issues later.

If you get stuck, ask me. But try the question first.

---

## Resources You'll Need This Week

**For Python/Scripts:**
- https://docs.python.org/3/ - Official Python documentation
- Your mentions.py file (the best learning material!)

**For Git/GitHub:**
- https://git-scm.com/book/en/v2 - Free Git book
- https://guides.github.com/ - GitHub guides

**For Documentation:**
- https://www.markdownguide.org/ - Markdown syntax

**For PostgreSQL (preview):**
- https://www.postgresql.org/docs/ - Official Postgres docs (we'll use more next week)

---

## Next Week Preview

Week 2 you'll start deeper PostgreSQL learning while continuing script documentation. But that's next week. Focus on Week 1.

---

## Your Commitment to This Week

You've got 15 hours to invest. Here's what you're getting back:

By November 21:
- ✅ Code organized and backed up
- ✅ Understanding of your primary automation
- ✅ Clear picture of where things could break
- ✅ Foundation for database learning
- ✅ Confidence that you can manage this pace

Let's do it.

---

**Week 1 starts now. Your first task: Read this plan, make sure the schedule works for you, and tell me if anything needs adjustment.**

*Let's begin.*
