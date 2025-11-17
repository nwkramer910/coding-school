# Learning & Development Project Structure

**Purpose:** Organized chat system for 12-month technical learning journey  
**Metaphor:** School structure - each chat type serves a specific learning function  
**Last Updated:** November 16, 2025  

---

## Chat Types & Their Purposes

### 🏠 Homeroom (Single Chat)
**Purpose:** Meta-learning - reflection on the learning process itself

**When to use:**
- Phase transitions (end of Months 3, 6, 12)
- Monthly progress reviews
- Major plan adjustments or pivots
- "Am I on track?" big-picture conversations
- Monthly check-ins (30th, 31st day reflections)

**What to bring:**
- Any scheduling conflicts
- Where am I mentally?
- What do I need to bring to Office Hours or Tutoring?
- Requests for plan modifications

**Project Knowledge:**
- Learning_Plan_Master.md
- Progress_Tracker.md
- Quick_Start_Guide.md
- INDEX.md

---

---
## Chat Types & Their Purposes

### 🏠 Weekly Check-In (One per week)
**When to use:**
- At the beginning of each week
- At the end of the week
- Get classroom assignments for the week
- Check in to see how the week went

**What to bring:**
- Completed phase retrospectives
- Updated Progress_Tracker.md entries
- Questions about timeline or approach
- Requests for plan modifications

**Project Knowledge:**
- Learning_Plan_Master.md
- Progress_Tracker.md
- Quick_Start_Guide.md
- INDEX.md

**Example topics:**
- "Completed Phase 1. Here's my review and adjustments needed for Phase 2."
- "Month 3 review: I'm behind on GUI development but ahead on SQL. Should I adjust timeline?"
- "Week 1 Friday review: Here's what I learned, blockers, and next week's goals."
---

### 📖 Classroom Chats (One per Focus Area)
**Purpose:** Active learning and project work for specific topics

**When to use:**
- Working through a specific focus area from the learning plan
- Building projects related to that topic
- Applying concepts in TEACHING MODE
- Getting help on topic-specific problems

**Naming convention:**
```
Class: [Topic] - Phase [#]
```

**Example chats:**
- Class: Understanding My Scripts - Phase 1
- Class: PostgreSQL DBA Basics - Phase 1
- Class: Debugging Fundamentals - Phase 1
- Class: Git Basics - Phase 1
- Class: GUI with tkinter - Phase 1
- Class: Data Modeling Theory - Phase 2
- Class: Python Intermediate - Phase 2
- Class: ArcPy Automation - Phase 2
- Class: Advanced SQL - Phase 2
- Class: Containers & GitLab - Phase 2
- Class: HTML/CSS/JavaScript - Phase 3
- Class: Flask Backend - Phase 3
- Class: Advanced Python Libraries - Phase 3
- Class: Advanced GUI Development - Phase 3

**Project Knowledge:**
- Relevant sections from Learning_Plan_Master.md for that phase
- Project-specific files (scripts, schemas, data)
- Concept_Library.md entries for that topic

**Example topics:**
- "Let's walk through position_update_v3.py line by line in TEACHING MODE"
- "I'm building a GUI launcher. Here's what I have so far. Can you review?"
- "Working on database normalization for my archaeological schema. Here's my design."

**When to close/archive:**
- After completing that focus area's deliverables
- When moving to next phase (keep for reference, create new for new phase)

---

### 🔧 Department Chats (Persistent Reference)
**Purpose:** Language/library reference that persists across all phases

**When to use:**
- Quick syntax questions
- "How do I do X in [language]?" reference queries
- Understanding language-specific concepts
- Building your personal knowledge base for that technology

**Naming convention:**
```
Dept: [Language/Technology]
```

**Recommended departments:**
- Dept: Python Reference
- Dept: SQL & PostgreSQL
- Dept: ArcPy & GIS
- Dept: Git & Version Control
- Dept: Web Development (HTML/CSS/JS/Flask)

**Project Knowledge:**
- Official documentation links
- Concept_Library.md entries for that language
- Personal code pattern examples
- Bookmark lists for that technology

**Example topics:**
- "What's the difference between a list and a tuple in Python?"
- "Quick reminder: CTE syntax in PostgreSQL?"
- "How do I use arcpy.da.SearchCursor again?"
- "Git merge vs rebase - when to use which?"

**Difference from Classroom:**
- **Classroom:** Applied, project-specific ("How do I use CTEs for my ORBAT database?")
- **Department:** Reference, general ("What's the syntax for CTEs?")

---

### 💡 Office Hours (Single Chat or As Needed)
**Purpose:** Working through challenging concepts that didn't click in Classroom

**When to use:**
- Concept didn't click after 2-3 attempts in Classroom
- Need different explanation approach
- Pattern you keep getting wrong
- Debugging persistent confusion
- Need focused help without project context

**What to bring:**
- Description of what you've tried
- Where understanding breaks down
- Examples of where you got it wrong
- Request for TEACHING MODE approach

**Project Knowledge:**
- Code_Review_Template.md
- Common_Errors_and_Solutions.md (when created)
- Concept_Library.md

**Example topics:**
- "I'm struggling with LEFT JOIN vs INNER JOIN. Learned syntax in SQL Dept, but choosing wrong in practice."
- "Error handling patterns aren't sticking. Can we try a different teaching approach?"
- "I think I understand functions, but my code keeps breaking. Let's test my understanding."

**Key principle:** This is proactive help-seeking, not documenting failure. It's where you actively work through challenges.

---

### 🎯 Tutoring Sessions (Temporary Deep Dives)
**Purpose:** Intensive focus on topics blocking multiple projects or revealing fundamental gaps

**When to use:**
- Foundational concept you need to master properly before proceeding
- Topic blocking progress in multiple areas
- Area where "hallucinated understanding" was exposed
- Need structured intensive study of one concept

**Naming convention:**
```
Tutoring: [Specific Topic]
```

**Example chats:**
- Tutoring: Database Indexing Strategy
- Tutoring: ArcPy Cursors Mastery
- Tutoring: Error Handling Patterns
- Tutoring: Git Workflow Fundamentals

**When to create:**
- Office Hours isn't enough - need sustained focus
- Blocking progress in current phase
- Realized gap in foundations

**When to archive:**
- Concept mastered and applied successfully
- No longer blocking other work
- Can return to normal Classroom flow

**Project Knowledge:**
- Highly focused resources on that one topic
- Practice exercises
- Your failed attempts (for learning)

**Example topics:**
- "Let's spend this session building a complete understanding of database transactions from scratch."
- "I keep breaking things with ArcPy cursors. Let's do 10 examples until I get it."
- "Build comprehensive error handling patterns I can reuse."

---

## Chat Organization Philosophy

### The Flow

```
Homeroom (plan & reflect)
    ↓
Weekly Check-in (plan & reflect)
    ↓
Classroom (active learning)
    ↓
Department (quick reference)
    ↓
Office Hours (stuck? get help)
    ↓
Tutoring (really stuck? intensive work)
    ↓
Back to Classroom (equipped to continue)
```

### When to Use What

**Normal learning flow:**
1. Plan in Homeroom at the beginning of a phase
2. Plan in Weekly Check-in for the week
3. Work in Classroom
4. Reference in Department when needed
5. Reflect in Homeroom on Friday

**When struggling:**
1. Try in Classroom 2-3 times
2. If stuck → Office Hours for different approach
3. If still blocking → Tutoring Session for deep dive
4. Once clear → Return to Classroom

**When just need a fact:**
→ Department (quick in/out)

**When planning or reflecting:**
→ Homeroom (big picture)

---

## Typical Week Structure

### Monday Morning
**→ Weekly Check-in**
- Review last week's progress
- Set this week's 3-5 goals
- Identify which Classroom chats to use
- Schedule learning blocks

### Tuesday-Thursday
**→ Classroom chats** (primary workspace)
- Active learning and building
- Project work
- Applying concepts

**→ Department chats** (as needed)
- Quick reference questions
- Syntax lookups
- Concept refreshers

**→ Office Hours** (if stuck)
- Concepts not clicking
- Need different approach
- Persistent confusion

### Friday Afternoon
**→ Homeroom**
- Weekly review and logging
- Update Progress_Tracker.md
- Rate the week (1-5 stars)
- Note wins and challenges
- Plan next week

---

## Project Knowledge Strategy

### What Goes Where

**Homeroom:**
- Core planning documents
- Progress tracking
- Big-picture references

**Homeroom:**
- Weekly planning documents
- Weekly assignment "grades" and reviews

**Classroom:**
- Phase-specific content
- Project files for that topic
- Deliverables in progress

**Department:**
- Official documentation links
- Language references
- Personal code patterns
- Reusable knowledge

**Office Hours:**
- Code review templates
- Common errors documentation
- Problem-solving frameworks

**Tutoring:**
- Focused resources on specific topic
- Practice exercises
- Intensive learning materials

---

## Naming Conventions Summary

| Chat Type | Format | Example |
|-----------|--------|---------|
| Homeroom | Just "Homeroom" | Homeroom |
| Classroom | Class: [Topic] - Phase [#] | Class: Git Basics - Phase 1 |
| Department | Dept: [Technology] | Dept: Python Reference |
| Office Hours | "Office Hours" | Office Hours |
| Tutoring | Tutoring: [Topic] | Tutoring: Error Handling |

**Why this matters:** Consistent naming makes Project Knowledge Search more effective.

---

## Setup Checklist for Monday

**Phase 0 - Project Setup:**
- [ ] Create "Learning & Development" project in Claude
- [ ] Upload all 6 core documents to project knowledge:
  - [ ] Learning_Plan_Master.md
  - [ ] Quick_Start_Guide.md
  - [ ] Progress_Tracker.md
  - [ ] Code_Review_Template.md
  - [ ] Concept_Library.md
  - [ ] INDEX.md
- [ ] Upload this Project_Structure.md file

**Create initial chats:**
- [ ] Create "Homeroom" chat
- [ ] Add core documents to Homeroom project knowledge

**Week 1 Monday Planning (in Weekly Check-in):**
- [ ] Answer three reflection questions
- [ ] Set Week 1 goals (3-5 specific goals)
- [ ] Identify which Classroom to start with

**Create Week 1 Classroom:**
- [ ] Create "Class: Understanding My Scripts - Phase 1"
- [ ] Add relevant project knowledge (your scripts, Phase 1 plan)
- [ ] Start first learning session

**Create Departments as needed:**
- [ ] Create when you have reference questions
- [ ] Don't create all upfront - add as needed
- [ ] Start with Dept: Python Reference (most likely first need)

---

## Common Questions

### "Should I create all Classroom chats upfront?"
**No.** Create them as you start that focus area. Too many empty chats is overwhelming.

### "When do I create a Department chat?"
**When you have 2-3 reference questions** about that technology. First question → ask in Classroom. Repeat questions → time for Department.

### "How do I know if something needs Office Hours vs. Tutoring?"
- **Office Hours:** Single concept, one session to clarify
- **Tutoring:** Fundamental gap, multiple sessions needed

### "Can I combine chat types?"
**Not recommended.** Separation keeps conversations focused and Project Knowledge Search effective.

### "What if I want to change the structure?"
**Go to Homeroom** and discuss. This structure serves you, not vice versa. Adjust as needed.

### "Do I need to be in the right chat type for every question?"
**Generally yes**, but don't overthink it. If you're in Classroom and have a quick reference question, it's fine to ask there. Just don't make it a habit - Department chats exist for a reason.

---

## Red Flags

⚠️ **All questions going to one chat** → You're not using the structure. Time to reorganize.

⚠️ **Creating Tutoring sessions constantly** → Something wrong with Classroom approach. Discuss in Homeroom.

⚠️ **Never using Office Hours** → Either you're not struggling (great!) or you're avoiding asking for help (not great).

⚠️ **Homeroom cluttered with daily questions** → Those belong in Classroom or Department. Keep Homeroom high-level.

⚠️ **Too many chats open** → Archive completed ones. Active chats should match current focus.

---

## Success Indicators

✅ **Clear separation:** You know which chat to use without thinking

✅ **Easy navigation:** Project Knowledge Search finds what you need

✅ **Clean workflows:** Homeroom → Classroom → Department flow is natural

✅ **Effective help:** Office Hours gets you unstuck quickly

✅ **Focused learning:** Each Classroom stays on topic

✅ **Useful reference:** Departments build over time into personal docs

---

## Version History

**v1.0 (November 16, 2025)**
- Initial project structure
- Five chat types defined
- Naming conventions established
- Workflow examples provided

---

*This structure is designed to match how you naturally learn and organize information. Use it as a framework, not a prison. Adjust in Homeroom as needed.*

**Start Monday with Homeroom. Everything flows from there.**
