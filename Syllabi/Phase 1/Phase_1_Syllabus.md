# Phase 1: Consolidation & Confidence - Comprehensive Syllabus

**Learner:** Nate Kramer  
**Start Date:** Monday, November 17, 2025  
**Duration:** 12 weeks (Months 1-3)  
**Learning Mode:** TEACHING MODE (default) | EXPLAINER MODE (for urgent issues)  
**Time Commitment:** ~15 hours/week average  

---

## Table of Contents

1. [Phase Overview](#phase-overview)
2. [Learning Philosophy](#learning-philosophy)
3. [Success Criteria](#success-criteria)
4. [Weekly Structure](#weekly-structure)
5. [Five Focus Areas](#five-focus-areas)
6. [Weekly Breakdown (Weeks 1-12)](#weekly-breakdown)
7. [Deliverables by Week](#deliverables-by-week)
8. [Resources & Tools](#resources--tools)
9. [Rules of Engagement](#rules-of-engagement)

---

## Phase Overview

### Primary Goal
**Own what you've already built; reduce dependency on AI for basic troubleshooting.**

You're managing a production database system. This phase focuses on deep understanding of your existing codebase and database infrastructure so you can troubleshoot, maintain, and extend systems with confidence.

### Core Philosophy
You can't build new things confidently until you understand what you've already created. This phase emphasizes **reading comprehension and debugging** rather than writing new code.

### Your Current Position
- ✅ You have working Python scripts and a PostgreSQL database in production
- ✅ You understand GIS and your domain (geospatial intelligence analysis)
- ❌ You're still learning the technical fundamentals
- ❌ You rely on AI for basic troubleshooting
- ❌ You're not fully confident in your debugging skills

**Phase 1 Goal:** Transform those checkmarks into solid understanding.

---

## Learning Philosophy

### Why This Approach Works for You

**Your cognitive strengths:**
- You learn quickly when concepts make sense
- You excel at pattern recognition
- You prefer understanding "why" over memorizing "what"
- You're motivated by real-world application

**Your learning challenges:**
- You can feel confident before actually mastering material (LLM brain problem)
- Understanding ≠ Application (just reading about code isn't the same as debugging it)
- You tend to over-organize notes instead of actually capturing content
- Sustained interest requires visible progress and real-world relevance

### How We'll Address These

✅ **Testing over trusting:** You'll apply concepts before considering them mastered  
✅ **Code reviews aggressively:** External validation catches false confidence  
✅ **Quick capture, clean up later:** Templates do the organizing, you do the learning  
✅ **Real work projects:** Your Russian ORBAT database is inherently interesting  
✅ **Visible milestones:** Weekly wins, weekly tracker updates, phase completion checklist  

### TEACHING MODE (Default)
When you ask questions, I'll guide you to answers rather than handing them to you. This builds real understanding.

**Example Teaching Mode interaction:**
```
You: "I don't understand how this for loop works"
Me: "Tell me what you think happens in each iteration. What would you expect as output?"
You: [thinks through it]
Me: "Now test your hypothesis by running the code. What did you observe?"
```

### EXPLAINER MODE (For Urgent Issues)
When you're stuck and need direct answers for production work.

**Example Explainer Mode interaction:**
```
You: "EXPLAINER MODE - I'm getting a connection timeout in production"
Me: [Directly explains the issue and how to fix it]
```

---

## Success Criteria

### Phase 1 Completion Checklist

By the end of Week 12 (December 9, 2025), you should be able to:

**Scripts & Automation:**
- ✅ Explain what every existing script does, line by line
- ✅ Trace execution flow through complex scripts
- ✅ Map dependencies between scripts
- ✅ Fix common errors without AI help
- ✅ Modify existing scripts for new use cases

**PostgreSQL & Databases:**
- ✅ Understand server architecture (connections, users, permissions)
- ✅ Perform basic administrative tasks (backups, user management)
- ✅ Read and interpret EXPLAIN plans
- ✅ Diagnose connection and permission issues
- ✅ Make safe schema modifications

**Debugging:**
- ✅ Read Python tracebacks and identify the problem
- ✅ Use breakpoints and systematic debugging
- ✅ Understand PostgreSQL error messages
- ✅ Fix issues without asking AI first
- ✅ Document solutions for future reference

**Version Control:**
- ✅ Commit code meaningfully
- ✅ Create and switch branches
- ✅ Understand merge basics
- ✅ Use Git for version control (not just backup)

**Documentation:**
- ✅ Your scripts are documented and commented
- ✅ Your database procedures are written down
- ✅ Your automation architecture is mapped
- ✅ Your common errors are documented

### Quantitative Success Metrics

- [ ] 100% of existing scripts documented and understood
- [ ] 0 database incidents due to lack of understanding
- [ ] ≥20 meaningful Git commits
- [ ] Personal debugging checklist with ≥10 common error patterns
- [ ] ≥5 scripts modified successfully using new understanding

### Qualitative Success Metrics

- You can **explain** technical concepts to non-technical colleagues
- You **debug** most common errors without AI assistance
- You **review** AI-generated code and identify potential issues
- You feel **confident** managing your production systems

---

## Weekly Structure

### Standard Week Pattern

**Monday Morning (15-30 min):**
- Open `Progress_Week_XX.md` (copy Progress_Tracker_Template.md)
- Set 3-5 specific goals for the week
- Review which focus area(s) you're tackling this week
- Schedule learning blocks on calendar

**Tuesday-Thursday (10-12 hours total):**
- Three 3-4 hour learning sessions
- Apply concepts from learning plan
- Write code, read documentation, troubleshoot issues
- Track questions and blockers in Progress_Tracker.md
- Commit code to Git as you go

**Friday Afternoon (1-2 hours):**
- Update Progress_Tracker.md with week's work
- Rate the week (1-5 stars)
- Note wins and challenges
- Preview next week's goals
- Celebrate small victories

**Time Allocation per Week:**
- 5-6 hours: Reading and learning concepts
- 6-8 hours: Hands-on practice (scripts, database, Git)
- 2-3 hours: Documentation and reflection

---

## Five Focus Areas

### Focus Area 1: Understanding Your Existing Scripts (Weeks 1-4)

**Goal:** Comprehensively understand your automation architecture

**What You'll Learn:**
- Line-by-line walkthrough of current automation
- How to trace execution flow through complex scripts
- Map dependencies between scripts
- Document "what runs when and why"
- Identify patterns you can reuse

**Deliverable:** Script Map Document
- Diagram: Which scripts do you have?
- What does each do?
- What order do they run in?
- What dependencies exist?

**Resources:**
- Your position_update_v3.py and related scripts
- Python documentation (functions, control flow)
- Concept_Library.md (you'll add many entries)

**Key Questions to Answer:**
1. What data sources feed into each script?
2. What transformations happen in each step?
3. Where do errors most commonly occur?
4. What would break if you changed [specific part]?

---

### Focus Area 2: PostgreSQL Fundamentals for DBAs (Weeks 2-6)

**Goal:** Understand your database from an administrator's perspective

**What You'll Learn:**
- Server architecture and connection management
- User roles, permissions, and security
- Backup strategies and disaster recovery
- Schema modification best practices
- Reading EXPLAIN plans for query optimization
- Understanding PostgreSQL logs and error messages
- Safe production database changes

**Deliverable:** Database Administration Runbook
- How to connect as different users
- Backup and recovery procedures
- How to modify schemas safely
- Common issues and how to diagnose them
- Emergency procedures

**Resources:**
- Your PostgreSQL server and schemas
- PostgreSQL documentation (official Postgres docs)
- *PostgreSQL: Up and Running* (reading starting Month 2-3)
- Your work on create_maid_unit_association, unit hierarchy functions

**Key Questions to Answer:**
1. What users exist and what can they access?
2. What's your current backup strategy?
3. How do you safely add a new column to a production table?
4. What do these EXPLAIN results tell you about query performance?

---

### Focus Area 3: Debugging Fundamentals (Weeks 3-8)

**Goal:** Develop systematic debugging skills

**What You'll Learn:**
- Reading Python tracebacks and understanding stack traces
- Strategic use of print statements and logging
- PostgreSQL error message interpretation
- Systematic debugging methodology
- Using breakpoints (introduction to debugging tools)
- Common error patterns and solutions
- When to ask for help vs. troubleshoot yourself

**Deliverable:** Personal Debugging Checklist & Common Errors Reference
- Your error patterns and what causes them
- Step-by-step debugging workflow
- Common fixes and where to look
- How to Google technical errors effectively
- When to escalate vs. solve yourself

**Resources:**
- Real errors from your production systems
- Python error documentation
- PostgreSQL error codes documentation
- Your work scripts (which will have bugs to learn from)

**Key Questions to Answer:**
1. What does this traceback actually tell me?
2. Where should I look first when something breaks?
3. What does this PostgreSQL error mean?
4. How do I test my fix before putting it in production?

---

### Focus Area 4: Git Basics for Version Control (Weeks 4-8)

**Goal:** Become comfortable with Git for code management

**What You'll Learn:**
- Repository creation and initialization
- Commit workflow and best practices
- Branch creation and switching
- Merge basics (avoiding conflicts)
- .gitignore for database credentials
- Basic GitHub workflow
- Why version control matters

**Deliverable:** All Existing Scripts Committed to GitHub
- Organized repository structure
- Meaningful commit history
- Professional README
- .gitignore protecting sensitive data
- Clear documentation

**Resources:**
- Git documentation and tutorials
- GitHub guides (https://guides.github.com/)
- Your existing scripts
- Pro Git book (free online)

**Key Questions to Answer:**
1. What is the difference between Git and GitHub?
2. Why does my commit message matter?
3. When should I create a new branch?
4. What shouldn't I commit to Git?

---

### Focus Area 5: GUI Development Basics (Weeks 4-12)

**Goal:** Build a user-friendly launcher for your team

**What You'll Learn:**
- Basic tkinter for GUI development
- Event-driven programming
- Creating windows, buttons, text fields
- Running commands from GUI
- Error handling in user-facing tools
- Making tools accessible for non-technical users

**Deliverable:** GUI Launcher Tool
- Used successfully by ≥3 team members
- Reduces common manual tasks
- Clear instructions and error messages
- Actually improves team workflow

**Resources:**
- Official tkinter documentation
- Real user feedback from your team
- Best practices for user-friendly design
- Your automation scripts (what needs a GUI?)

**Key Questions to Answer:**
1. What tasks are your team doing manually that could have a GUI?
2. How do I make a GUI that non-programmers can understand?
3. What happens when a user provides bad input?
4. How do I test that it actually works for my team?

---

## Weekly Breakdown (Weeks 1-12)

### Week 1: Planning & First Script Walkthrough

**Focus Area:** Scripts Understanding (1) + Git Setup (4)  
**Deliverable Start:** Script Map document outline  
**Time:** 15 hours

**Monday:**
- Answer three reflection questions in Progress_Tracker.md:
  1. What's the single most important thing to understand about my automation?
  2. What's the one database concept I'm shakiest on?
  3. What's my biggest fear about this learning journey?
- Set three specific goals for Week 1
- Schedule learning blocks

**Tuesday-Thursday Sessions:**

**Session 1 (2-3 hours): Deep Script Walkthrough**
- Open position_update_v3.py (or main script)
- Read it slowly, line by line
- For each section, note: "What is this doing?"
- Mark parts you don't understand
- Bring questions to Claude in TEACHING MODE
- Write comments explaining what you understand

**Session 2 (2-3 hours): GitHub Setup**
- Create GitHub account (if needed)
- Install Git locally
- Create repository: `isw-orbat-database`
- Commit your existing scripts
- Write a README explaining the project
- Practice: Make a small change, commit it

**Session 3 (3-4 hours): Documentation Start**
- Create Script Map outline
- List all your scripts
- For each, write: "This script does..."
- Identify dependencies (what needs to run first?)
- Document data sources
- Start Concept_Library.md with new terms

**Friday:**
- Update Progress_Tracker.md with what you learned
- Add 3-5 new terms to Concept_Library.md
- Commit your work to Git
- Rate week (1-5 stars)
- Celebrate: You've started!

---

### Week 2: Database Fundamentals & More Scripts

**Focus Area:** PostgreSQL (2) + Scripts Understanding (1)  
**Deliverable Start:** Database Administration Runbook outline  
**Time:** 15 hours

**Key Learning:**
- What is a PostgreSQL server? How do you connect?
- What are users and permissions?
- What does your current database look like?
- How do you understand your schema?

**Session 1 (2-3 hours): Connect to Your Database**
- Connect to your PostgreSQL server using different methods
- List all databases
- Connect to your main database
- List all tables (what's stored here?)
- For 3 key tables: understand the columns and their purpose
- Write this understanding down

**Session 2 (3-4 hours): Deep Script Reading**
- Continue with next script in your automation
- Same process: read line by line, understand each part
- Find where this script connects to the database
- Trace: What does it read? What does it write?
- Add to Script Map

**Session 3 (2-3 hours): Database Concepts**
- Read PostgreSQL basics documentation
- Add entries to Concept_Library.md:
  - What is a "relation"?
  - What is a "primary key"?
  - What is a "foreign key"?
  - What is a "constraint"?
- Look at your schema: identify these patterns in your own tables

**Friday:**
- Update Progress_Tracker.md
- Commit code and documentation to Git
- Add 5+ new database concepts to Concept_Library.md
- Preview Week 3

---

### Week 3: Debugging & Connection Troubleshooting

**Focus Area:** Debugging (3) + PostgreSQL (2)  
**Deliverable Start:** Common Errors reference document  
**Time:** 15 hours

**Key Learning:**
- How to read Python error messages
- How to understand PostgreSQL connection errors
- What to check when "things aren't working"
- How to test your fixes

**Session 1 (2-3 hours): Reading Error Messages**
- Find 3 real errors from your scripts or logs
- For each error:
  - What does it say?
  - Where did the error occur?
  - What was happening when it failed?
- Research what each error means
- Document your findings

**Session 2 (3-4 hours): Connection & Permission Debugging**
- Test: Can you connect as different users?
- Try accessing tables as different users
- Create a test error (intentionally)
- Troubleshoot it systematically
- Document what you learned about permissions

**Session 3 (2-3 hours): Script Errors**
- Pick a script that sometimes has issues
- Create test cases that work and that fail
- Use print statements to trace execution
- Add better error messages
- Document patterns you find

**Friday:**
- Create "Common Errors & Solutions" document
- Start with 5-10 errors you've encountered
- For each: what causes it? How to fix it?
- Update Progress_Tracker.md
- Commit to Git

---

### Week 4: Version Control Deep Dive & GUI Planning

**Focus Area:** Git (4) + GUI Preparation (5)  
**Deliverable Progress:** Complete GitHub setup + GUI design  
**Time:** 15 hours

**Key Learning:**
- Why Git branches matter
- How to work without breaking production
- What makes a good GUI
- Planning before coding

**Session 1 (2-3 hours): Git Branches**
- What is a branch?
- Create a new branch
- Make changes on that branch
- Switch back and forth
- Understand why this matters (safety!)
- Practice merging changes carefully

**Session 2 (3-4 hours): Reviewing Your Work**
- Use Git to see what changed over the week
- Write meaningful commit messages for old commits
- Organize your scripts logically
- Update your README
- Make sure sensitive data is ignored (.gitignore)

**Session 3 (2-3 hours): GUI Design**
- Talk to your team: what tasks are tedious?
- What would make their lives easier?
- Sketch out 2-3 GUI ideas
- Pick the most useful
- Plan: what buttons? what inputs? what output?
- Document your design

**Friday:**
- Complete GitHub setup
- All scripts organized and committed
- Begin researching tkinter
- Update Progress_Tracker.md
- Preview Week 5

---

### Week 5: More Scripts & Starting GUI

**Focus Area:** Scripts (1) + GUI (5)  
**Deliverable Progress:** Script Map nearly complete + First GUI prototype  
**Time:** 15 hours

**Key Learning:**
- Understanding your complete automation pipeline
- Basic tkinter and event-driven programming
- Getting feedback early from users

**Session 1 (2-3 hours): Complete Script Mapping**
- Finish understanding remaining scripts
- Complete the Script Map document
- Include: purpose, inputs, outputs, dependencies
- Identify common patterns across scripts
- Document edge cases or special behaviors

**Session 2 (3-4 hours): GUI Basics**
- Read tkinter tutorials
- Create a simple test GUI (hello world equivalent)
- Add a button
- Make the button do something
- Learn about event handlers
- Add text input
- Display results

**Session 3 (2-3 hours): Your First Real GUI**
- Based on your design from Week 4
- Create the basic structure
- Add the key buttons
- Get feedback from 1-2 team members
- What works? What's confusing?

**Friday:**
- Update Progress_Tracker.md
- Commit Script Map to Git (complete!)
- Commit first GUI code to Git
- Get feedback from team
- Note what to improve in Week 6

---

### Week 6: Database Administration Essentials

**Focus Area:** PostgreSQL (2) continued  
**Deliverable Progress:** Database Administration Runbook (draft)  
**Time:** 15 hours

**Key Learning:**
- How to back up your database (really important!)
- How to restore from backup (also really important!)
- How to monitor database health
- How to safely modify production schemas

**Session 1 (2-3 hours): Backups & Recovery**
- What is a backup? Why do you need one?
- What backup strategy does your server have?
- Create a test backup
- Test recovery (restore to test environment)
- Document the complete procedure
- Understand: when do you need a backup? How do you restore?

**Session 2 (3-4 hours): Safe Schema Modifications**
- Pick a non-critical table
- Practice adding a column
- Practice removing a column
- Practice changing a data type
- For each change: what could go wrong?
- How would you roll back?
- Document procedures for production changes

**Session 3 (2-3 hours): Monitoring & Maintenance**
- What does a healthy database look like?
- How to check: connections, storage, performance
- Understand PostgreSQL logs
- Practice: turn on error logging, cause an error, find it in logs
- Set up basic monitoring

**Friday:**
- Create Database Administration Runbook (draft)
- Test your procedures (on test database!)
- Update Progress_Tracker.md
- Commit runbook to Git
- Note: this is essential knowledge

---

### Week 7: GUI Refinement & Error Handling

**Focus Area:** GUI (5) + Debugging (3)  
**Deliverable Progress:** Improved GUI, ready for team testing  
**Time:** 15 hours

**Key Learning:**
- Making GUIs that don't break easily
- Handling user mistakes gracefully
- Getting and implementing feedback
- Testing user-facing tools

**Session 1 (2-3 hours): Error Handling**
- What happens if user enters bad data?
- What happens if the database is unavailable?
- What happens if a script fails?
- Add error handling to your GUI
- Show helpful error messages (not technical jargon)
- Test: intentionally break it, see what happens

**Session 2 (3-4 hours): User Feedback**
- Get 2-3 team members to use your GUI
- Watch them use it (don't help!)
- What's confusing?
- What's working well?
- Fix the confusing parts
- Improve the working parts

**Session 3 (2-3 hours): Documentation**
- Write user guide for your GUI
- Include: how to use, what each button does, what to do if something breaks
- Test: can a non-programmer follow it?
- Add to your GitHub repository

**Friday:**
- GUI ready for wider team use
- Update Progress_Tracker.md
- Commit improvements to Git
- Begin getting feedback from more team members
- Celebrate: your tool is working!

---

### Week 8: Deep Debugging & Script Optimization

**Focus Area:** Debugging (3) continued  
**Deliverable:** Advanced Common Errors reference + Script optimization  
**Time:** 15 hours

**Key Learning:**
- Debugging complex problems systematically
- Understanding Python profiling
- Optimizing scripts for performance
- Knowing when "it's fast enough"

**Session 1 (2-3 hours): Systematic Debugging**
- Pick a script that has intermittent issues
- Set up detailed logging (not just print statements)
- Create test cases that reproduce the problem
- Use Python debugger (pdb) to step through code
- Identify the root cause
- Fix it and verify

**Session 2 (3-4 hours): Error Patterns**
- Review all the errors you've documented
- Group them by type
- For each group: common causes and fixes
- Add prevention strategies
- Update your Common Errors document
- Create your personal debugging checklist

**Session 3 (2-3 hours): Script Performance**
- Pick your slowest script
- Add timing to see where time is spent
- Is it database queries? File I/O? Processing?
- Research optimization for the bottleneck
- Implement improvements
- Measure the impact

**Friday:**
- Update Common Errors & Solutions document
- Create Personal Debugging Checklist
- Commit optimizations to Git
- Update Progress_Tracker.md
- Assess: Are you debugging independently yet?

---

### Week 9: GUI Polish & Team Deployment

**Focus Area:** GUI (5) + Scripts (1)  
**Deliverable:** Production-ready GUI  
**Time:** 15 hours

**Key Learning:**
- Making software production-ready
- Documentation for different audiences
- Deployment and support
- User adoption strategies

**Session 1 (2-3 hours): Final Polish**
- Review all feedback
- Fix remaining issues
- Add missing features
- Test thoroughly
- Performance: does it run smoothly?
- Edge cases: what unusual inputs might break it?

**Session 2 (3-4 hours): Documentation & Training**
- Write admin guide (for you)
- Write user guide (for team)
- Create troubleshooting guide
- Record a short demo video (optional)
- Plan training session

**Session 3 (2-3 hours): Deployment**
- Set up on shared location
- Verify all your team members can access it
- Train team on how to use it
- Set up support process (how do they report issues?)
- Monitor first week of usage

**Friday:**
- GUI deployed and in use!
- Update Progress_Tracker.md
- Commit to Git
- Celebrate: major deliverable complete!
- Begin planning next weeks

---

### Week 10: Review & Advanced Database Concepts

**Focus Area:** PostgreSQL (2) + Concept Review  
**Deliverable:** Advanced Database Runbook additions  
**Time:** 15 hours

**Key Learning:**
- Advanced SQL for your use cases
- Query optimization and EXPLAIN
- PostGIS for spatial data
- Database design patterns

**Session 1 (2-3 hours): Query Optimization**
- Pick 3 slow queries from your work
- Use EXPLAIN ANALYZE to understand them
- Read the explain plans
- Add indexes? Rewrite the query?
- Measure performance improvements
- Document what you learned

**Session 2 (3-4 hours): PostGIS & Spatial Queries**
- Review your current spatial data usage
- Understand spatial indexes
- Practice spatial queries
- Review PostGIS functions you use
- Experiment with new spatial capabilities
- Document useful patterns

**Session 3 (2-3 hours): Database Design Review**
- Review your current schema
- Are there design issues?
- What would you do differently now?
- Document improvements for future work
- Plan: what tables might you add in Phase 2?

**Friday:**
- Update Database Administration Runbook
- Create "Database Optimization Guide"
- Update Progress_Tracker.md
- Commit to Git
- Assess: how far you've come!

---

### Week 11: Script Consolidation & Phase Review

**Focus Area:** Scripts (1) + Documentation  
**Deliverable:** Complete Script Map & documentation  
**Time:** 15 hours

**Key Learning:**
- Consolidating knowledge into lasting documentation
- Teaching others what you've learned
- Identifying remaining gaps

**Session 1 (2-3 hours): Final Script Review**
- Review every script one more time
- Complete Script Map with all details
- Include: usage, dependencies, common issues, optimization tips
- Verify: could someone else understand this?
- Add to Git

**Session 2 (3-4 hours): Code Comments & Cleanup**
- Review all your scripts
- Add meaningful comments
- Clean up any temporary code
- Ensure naming is clear
- Remove debug statements
- Commit cleaned-up versions

**Session 3 (2-3 hours): Documentation Package**
- Gather all documentation
- Organize logically
- Verify completeness
- Create master README
- Add to Git repository
- Would a new developer understand everything?

**Friday:**
- All scripts and documentation complete
- Commit final package to Git
- Update Progress_Tracker.md (comprehensive!)
- Preview next week's phase review
- Prepare: summarize what you've learned

---

### Week 12: Phase Review & Celebration

**Focus Area:** Reflection & Phase Completion  
**Deliverable:** Phase 1 Complete  
**Time:** 15 hours

**Key Learning:**
- How much you've learned
- Where you are now vs. Week 1
- What to focus on next

**Session 1 (2-3 hours): Personal Inventory**
- Review your Concept_Library.md
- How many concepts have you learned?
- Review your Git commits
- How much code have you written/modified?
- Review your documentation
- What are you proud of?

**Session 2 (3-4 hours): Practical Testing**
- Can you debug a real error without AI help?
- Can you modify a script?
- Can you safely change the database?
- Can you use Git effectively?
- Can you explain your automation to someone else?
- Test yourself on all these

**Session 3 (2-3 hours): Phase Retrospective**
- What went well?
- What was harder than expected?
- What surprised you?
- Did you learn what you set out to learn?
- What's your biggest confidence gain?
- What do you still want to learn?

**Friday:**
- Complete Phase 1 Retrospective
- Answer: "Am I ready for Phase 2?"
- Update Progress_Tracker.md (final week)
- Celebrate! You've completed Phase 1!
- Plan: What's next? (Phase 2 preview)

---

## Deliverables by Week

### Week 1
- [ ] Progress_Tracker_Week_01.md (created and filled)
- [ ] GitHub repository created with scripts
- [ ] Script Map document (outline)

### Week 2
- [ ] Database Administration Runbook (outline)
- [ ] Script Map (continued)
- [ ] 5+ Concept_Library entries

### Week 3
- [ ] Common Errors & Solutions reference (started)
- [ ] Script Map (continued)

### Week 4
- [ ] GitHub setup complete (all scripts organized)
- [ ] Meaningful commit history
- [ ] README documentation
- [ ] GUI design document

### Week 5
- ✅ **Script Map COMPLETE**
- [ ] First GUI prototype

### Week 6
- ✅ **Database Administration Runbook (DRAFT)**
- [ ] Backup & recovery procedures documented

### Week 7
- [ ] GUI ready for team testing
- [ ] GUI user guide

### Week 8
- ✅ **Common Errors & Solutions COMPLETE**
- ✅ **Personal Debugging Checklist COMPLETE**

### Week 9
- ✅ **GUI Launcher DEPLOYED & IN USE**
- [ ] GUI documentation (admin + user guides)

### Week 10
- [ ] Query Optimization Guide
- ✅ **Database Administration Runbook (FINAL)**

### Week 11
- ✅ **All Scripts Fully Documented**
- [ ] Complete code cleanup and comments

### Week 12
- ✅ **PHASE 1 COMPLETE**
- [ ] Phase 1 Retrospective
- [ ] Decision: Ready for Phase 2?

### Summary of Deliverables
- ✅ Script Map document (what your automation does)
- ✅ Database Administration Runbook (how to manage your DB)
- ✅ Common Errors & Solutions (your debugging knowledge)
- ✅ Personal Debugging Checklist (how you debug)
- ✅ GUI Launcher Tool (used by team)
- ✅ GitHub repository (all code organized)
- ✅ Concept Library entries (technical vocabulary)
- ✅ Complete documentation (for future reference)

---

## Resources & Tools

### Essential Readings (by week)

**Week 1-2:**
- *Automate the Boring Stuff with Python* - Chapters 1-3
- Git documentation and guides
- Your own script files (the best learning material)

**Week 3-4:**
- Python debugging documentation
- PostgreSQL documentation (official docs)
- Your own error logs and scripts

**Week 5-6:**
- *Automate the Boring Stuff with Python* - Chapters 8-9 (file I/O)
- PostgreSQL documentation - backup and recovery sections
- tkinter tutorials

**Week 7-8:**
- tkinter documentation
- Python error handling (try/except)
- Performance profiling documentation

**Week 9-10:**
- *Database Design for Mere Mortals* (if you have it) - chapters on normalization
- PostgreSQL query optimization guides
- PostGIS documentation

**Week 11-12:**
- Review materials from previous weeks
- Professional Python practices

### Tools You'll Use

- **Python:** Your scripts, debugger (pdb)
- **PostgreSQL:** psql command line, your database
- **Git:** Version control for your code
- **tkinter:** GUI framework
- **Claude:** Learning partner (TEACHING MODE default)
- **Documentation:** Concept_Library, Progress_Tracker, Script Map

### Reference Materials

From your work project:
- Russian ORBAT Database schema (understand what it does)
- MAID integration documentation
- Function documentation examples
- Your existing scripts

### Online Documentation (Bookmark These)

- https://docs.python.org/ - Python official docs
- https://www.postgresql.org/docs/ - PostgreSQL official docs
- https://docs.python.org/3/library/pdb.html - Python debugger
- https://git-scm.com/doc - Git documentation
- https://docs.python.org/3/library/tkinter.html - tkinter

---

## Rules of Engagement

### For You (The Learner)

1. **Default to TEACHING MODE**
   - Bring specific questions and problems
   - Think through my guiding questions before asking me for answers
   - Apply concepts immediately (don't just read about them)

2. **Update your Progress Tracker weekly**
   - Friday end-of-week review (30 minutes)
   - Tuesday check-in on any blockers
   - Keep it brief but consistent

3. **Commit code to Git regularly**
   - Commit at least 2-3 times per week
   - Write meaningful commit messages (what changed and why?)
   - Don't worry about perfect commits; consistency matters more

4. **Validate your understanding before trusting it**
   - Test code before considering it "learned"
   - Apply concepts in your own scripts
   - Explain concepts to someone else (or in writing)
   - Don't trust the "yeah, I get it" feeling without verification

5. **Document everything you learn**
   - Add to Concept_Library.md (5-10 entries per week)
   - Add to Common Errors as you encounter them
   - Update Script Map as you understand more
   - Write in your own words (not copy/paste from docs)

### For Claude (Your Learning Partner)

1. **I will guide, not give answers**
   - Unless you explicitly say EXPLAINER MODE
   - I'll ask questions that help you think through problems
   - I'll point you to resources rather than spoonfeed information

2. **I will validate your understanding**
   - I'll catch false confidence ("hallucinated" understanding)
   - I'll ask you to apply concepts
   - I'll push back gently when something seems off

3. **I will celebrate your progress**
   - I'll acknowledge wins and milestones
   - I'll remind you how far you've come
   - I'll help you adjust when things aren't working

4. **I will respect your time**
   - 15 hours/week is reasonable
   - It's okay to slip a week occasionally
   - Consistency matters more than perfection

---

## How to Use This Syllabus

### At the Start of Each Week

1. Open this syllabus to the relevant week
2. Copy Progress_Tracker_Template.md → `Progress_Week_XX.md`
3. Set your 3-5 goals for the week from the weekly breakdown
4. Schedule your learning blocks on your calendar
5. Start with the first session

### During Each Week

1. Track progress in Progress_Tracker.md (daily brief notes)
2. Commit code as you write it (no need to wait until end of week)
3. Add to Concept_Library.md as you learn new terms
4. Ask Claude questions in TEACHING MODE with specific context

### At the End of Each Week

1. Fill out complete week summary in Progress_Tracker.md
2. Rate the week (1-5 stars)
3. Note what worked and what needs adjustment
4. Commit your work to Git
5. Celebrate progress

### At Phase Milestones (Weeks 4, 8, 12)

1. Review completed deliverables
2. Assess progress against success criteria
3. Decide: stay on track or adjust?
4. Plan for next phase

---

## Important Notes

### This Plan Is Your Servant, Not Your Master

- Adjust weeks if you need more/less time on a topic
- Combine weeks if you're ahead
- Split weeks if you're finding something challenging
- The goal is learning, not following the plan perfectly

### Sustainable Learning > Fast Learning

- 15 hours/week is designed to be sustainable
- It's okay if you miss a week
- It's okay if you spend 3 weeks on something that should take 2
- Progress is measured over months, not days

### You're Building Confidence, Not Just Skills

- By Week 12, you should **feel** confident
- By Week 12, you should **be** confident
- Confidence comes from understanding, not from following instructions

### This Is Specifically Designed for Your Profile

- Real-world projects (your Russian ORBAT database)
- Leveraging your domain expertise (GIS, geospatial intelligence)
- Applied learning (testing concepts immediately)
- Visible progress markers (weekly wins, phase completion)
- Flexible pacing (adjust as needed)

---

## Getting Started

**Today is Monday, November 17, 2025.**

### Right Now, This Hour

1. Read this syllabus through (you're doing it!)
2. Copy Progress_Tracker_Template.md → Progress_Week_01.md
3. Answer the three reflection questions:
   - What's the single most important thing for me to understand about my automation?
   - What's the one database concept I'm shakiest on?
   - What's my biggest fear about this learning journey?
4. Set three goals for Week 1
5. Schedule your learning blocks on your calendar

### This Week

- Session 1: Deep script walkthrough (understand what your code does)
- Session 2: GitHub setup (get your code in version control)
- Session 3: Documentation start (begin mapping your automation)

### This Month

- Understand your existing automation completely
- Get all code in GitHub
- Start learning PostgreSQL fundamentals
- Build first GUI prototype
- Learn Git basics

### Three Months from Now (Phase 1 Complete)

- You'll understand your entire automation architecture
- You'll manage your database with confidence
- You'll debug most errors without AI help
- Your team will be using your GUI tool
- You'll feel ownership of your technical systems

---

## Your Success Looks Like This

**At the end of Week 1:** "I finally understand what position_update_v3.py actually does."

**At the end of Week 4:** "I could explain my automation to someone else."

**At the end of Week 8:** "I just fixed a bug without asking Claude first."

**At the end of Week 12:** "I feel confident managing my database and automation. I know how to debug problems. I understand the code I'm running."

---

**You've got this. One week at a time. Let's begin.**

*Homeroom Chat*  
*Started: November 17, 2025*  
*Phase 1: Consolidation & Confidence*
