# Technical Learning & Development Plan
## Master Document v1.0

**Learner:** Nate Kramer  
**Role:** GEOINT Analyst & Database Lead, Institute for the Study of War  
**Timeline:** 12-month intensive learning program  
**Last Updated:** November 16, 2025  

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Background & Context](#background--context)
3. [Learning Goals](#learning-goals)
4. [Three-Phase Learning Plan](#three-phase-learning-plan)
5. [Weekly Structure & Methodology](#weekly-structure--methodology)
6. [Reading List & Resources](#reading-list--resources)
7. [Success Metrics](#success-metrics)
8. [Reference Files](#reference-files)

---

## Executive Summary

This is a **pragmatic, project-based learning plan** designed to transform a GEOINT analyst with basic coding skills into a **technical product owner** capable of:
- Designing and managing database systems
- Writing and debugging automation scripts
- Building user-friendly interfaces for non-technical teams
- Leading technical projects and collaborating with developers
- Positioning for data team leadership or career transition

**Core Philosophy:** You don't need to write every line of code from scratch. You need to **understand code, validate AI-generated solutions, troubleshoot problems, and extend existing systems**. This is a sustainable approach for someone managing production systems while learning.

**Key Constraint:** ~15 hours/week average, with variable availability day-to-day.

**Primary Learning Mode:** Project-based learning using real work data and actual deliverables, supplemented with structured reading for conceptual foundations.

---

## Background & Context

### Current Role & Responsibilities

You work as a GEOINT analyst at the Institute for the Study of War (ISW), a think tank analyzing US adversaries. Your primary mission involves building and maintaining a comprehensive Russian ORBAT (Order of Battle) intelligence database system to track Russian military units in Ukraine.

**Key Technical Achievements:**
- Built PostgreSQL database with PostGIS extensions for spatial analysis
- Integrated multiple intelligence sources (MAID data, SIGINT, satellite imagery, textual intelligence)
- Designed database schema supporting ~20 concurrent users
- Automated data collection and processing workflows with Python
- Currently managing transition to Azure Database for PostgreSQL

**Immediate Challenge:** You've been assigned to manage a database server for significant funding, but you're still learning the technical fundamentals. You need to **deliver value quickly** while building deeper competency.

**Team Context:** Your colleagues are humanities majors who struggle with basic tech tasks ("had to walk them through Task Manager"). Any automation you build must be **extremely user-friendly** or it won't get used.

### Current Technical Skills

**Python:**
- ✅ Understand control flow (if/else/elif, loops)
- ✅ Can write simple scripts with print statements
- ✅ Basic familiarity with existing automation scripts (with AI assistance)
- ❌ Not yet comfortable writing functions from scratch
- ❌ Limited experience with error handling and debugging
- ❌ Haven't built GUIs yet

**SQL/PostgreSQL:**
- ✅ Can build queries with JOINs
- ✅ Comfortable with WHERE, ORDER BY, basic statements
- ✅ Understand foreign key relationships
- ❌ Not comfortable with CTEs (Common Table Expressions)
- ❌ Limited experience with window functions
- ❌ Haven't written complex PostgreSQL functions independently
- ❌ New to formal database administration (backups, permissions, optimization)

**Data Structuring:**
- ✅ Good intuitive sense of schema design from building Russian ORBAT database
- ✅ Understand normalization practically (but not formally)
- ❌ Want confidence and formal grounding in database design theory

**HTML/Web Development:**
- ❌ No current experience
- 🎯 Goal: Build modern website for archaeological data (6-12 month timeline)

**Version Control:**
- ❌ Limited GitHub experience
- ❌ No GitLab experience
- ❌ Need to learn professional development workflows

**Other:**
- ✅ Expert in ArcGIS Pro for geospatial visualization
- ✅ Strong understanding of geospatial data concepts
- ✅ Comfortable with command-line basics

### Learning Profile: Understanding How You Learn

**Academic Background:**
- Dartmouth graduate with classics focus (Latin and Greek expertise)
- Accepted at Columbia and UNC, waitlisted at Princeton for Classics PhD
- National Merit scholar, top 7 in high school class
- Varsity athlete training with Olympians while producing dissertation-level undergraduate thesis

**Cognitive Strengths:**
- **Pattern recognition excellence:** Brain naturally sees structures and systems (inflected languages ≈ mathematical equations)
- **Conceptual understanding:** Rarely struggles to grasp concepts initially
- **Strong memory:** Retains information from lectures and discussions well
- **High capacity:** Successfully managed dual demands (athletics + rigorous academics)
- **Driven and goal-oriented:** Thrives with clear objectives and meaningful challenges

**Learning Challenges to Navigate:**

**1. The "LLM Brain" Pattern**
Your brain, like an LLM, excels at forcing coherent understanding from incomplete information - but this can create false confidence. You might "hallucinate" understanding when gaps exist.

**Implication for this plan:** 
- ⚠️ **Extra validation needed:** Don't trust initial understanding without testing
- ✅ **Build in application checks:** Concept isn't mastered until you've applied it successfully
- ✅ **Use code reviews aggressively:** External validation catches "hallucinated" understanding
- ⚠️ **Watch for:** "I get it" moments that fall apart during implementation

**2. Understanding vs. Application Gap**
Strong conceptual grasp doesn't always translate to successful application (e.g., calculus tests).

**Implication for this plan:**
- ✅ **Emphasize hands-on practice:** Every concept must be used in actual code/queries
- ✅ **Test-driven learning:** Write code that could fail before you fully understand
- ⚠️ **Beware "tutorial hell":** Reading/understanding ≠ ability to build
- ✅ **Deliberate practice:** Focus on application, not just comprehension

**3. Note-Taking Perfectionism**
Tendency to over-organize notes (color-coding, hierarchies) at the expense of content capture.

**Implication for this plan:**
- ✅ **Use templates:** Pre-structured documents (Progress_Tracker, Concept_Library) remove formatting decisions
- ⚠️ **Avoid over-documentation:** "Good enough" documentation > perfect documentation that doesn't happen
- ✅ **Quick capture priority:** Jot notes messily during learning, clean up later if needed
- ✅ **Code comments > separate docs:** Documentation lives with code when possible

**4. Interest Sustainability**
High capacity and drive, but can struggle maintaining interest over time.

**Implication for this plan:**
- ✅ **Project-based learning:** Use real work problems (inherently interesting)
- ✅ **Visible progress markers:** Weekly wins, phase completions, deliverable milestones
- ⚠️ **Watch for burnout:** 12 months is long - build in variety and breaks
- ✅ **Connect to goals:** Regularly revisit why this matters (data team leadership, career flexibility)
- ⚠️ **Pivot when needed:** If interest wanes in a topic, adjust approach or timeline

**5. Language-Oriented Thinking**
Brain structured around inflected languages (Latin/Greek) - thinks in grammatical patterns and transformations.

**Implication for this plan:**
- ✅ **Leverage analogy:** Programming syntax ≈ grammar rules, functions ≈ declensions
- ✅ **Pattern libraries:** Collect "conjugation tables" for code patterns
- ✅ **Structural thinking:** Database schemas ≈ linguistic structures
- ✅ **Use this strength:** You'll excel at understanding code syntax and structure

**Optimal Learning Strategies for Your Profile:**

**For concept introduction:**
1. Get overview (you'll grasp it quickly)
2. **Immediately apply** (before false confidence sets in)
3. Break something intentionally
4. Fix it (validates actual understanding)
5. Teach it back to Claude or document it

**For skill building:**
1. Build something real (not tutorials)
2. Get it working (even if ugly)
3. Get feedback (external validation critical)
4. Refactor and improve
5. Use pattern in new context

**For maintaining engagement:**
1. Work on actual problems (Russian ORBAT, archaeological database)
2. Set aggressive but achievable weekly goals
3. Track visible progress (commits, deliverables, team usage)
4. Vary between different types of work (code, database, documentation)
5. Celebrate wins explicitly

**Red Flags Specific to Your Profile:**

⚠️ **"I understand this perfectly"** → Test it immediately with code  
⚠️ **"I'll take better notes next time"** → Accept messy notes, move forward  
⚠️ **"This is boring now"** → Connect to end goal or change approach  
⚠️ **"I read about it, I'm good"** → No. Build something with it.  
⚠️ **Tutorial completion ≠ skill mastery** → Always validate with original work  

### Dual-Track Projects

**Work Project (Immediate):** Russian ORBAT Database
- Prove value to justify hiring a data team
- Expand to other theaters (China, Iran)
- Add strike tracking, terrain analysis capabilities
- Support colleague's data visualization work (ArcGIS SDK, D3)
- Timeline: Deliver proof-of-concept value within 12 months

**Side Project (Long-term):** Archaeological Database for Greece
- Partner: Thesis advisor with 18-month Guggenheim fellowship window
- Goal: Build "Perseus Tufts but for archaeological data" - normalized database of excavations in Greece
- Phase 1 (18 months): Design, funding, proof-of-concept with Sparta data
- Phase 2 (years 2-5): Scale and expand
- Technical needs: Website for researchers to query, deposit, visualize geospatial data

### Career Objectives

**Immediate (0-12 months):**
- Confidently manage production database server
- Prove value to justify creating and leading a data team at ISW
- Position as technical lead who can work with specialists

**Long-term (1-3 years):**
- If ISW data team works out: Lead it as technical director
- If not: Transition to new role leveraging both humanities background and technical skills
- Target competency level: Junior software engineer (for skillset, not necessarily the role)

---

## Learning Goals

### Core Competencies to Develop

#### 1. Coding Fundamentals
- **Vocabulary:** Understand technical terms to communicate with developers
- **Reading comprehension:** Read and understand most script structures
- **Debugging:** Diagnose and fix problems in existing code
- **Writing:** Create basic helper scripts within 12 months
- **Extension:** Modify and enhance existing automation

#### 2. Python Proficiency

**Priority Libraries:**
- `arcpy` - ArcGIS Pro automation and geoprocessing
- `geopandas` - Geospatial data manipulation
- `pandas` - Data analysis and transformation
- `python-docx` - Document generation for reports
- `rapidfuzz` - Fuzzy string matching for data deduplication
- `tkinter` / `ttkbootstrap` - GUI development for user-friendly tools
- JSON handling - Data exchange and configuration files

**Key Skills:**
- Function writing and organization
- Error handling and logging
- Working with files and databases
- Event-driven programming (for GUIs)
- Package management and virtual environments

#### 3. SQL & Database Management

**PostgreSQL Expertise:**
- Server concepts (connections, users, permissions, backups)
- Schema design and modification
- Input/update functions for data workflows
- Geospatial analysis functions (PostGIS)
- Data quality and validation functions
- Performance optimization (indexing, partitioning, query plans)
- JSON support in PostgreSQL

**Database Administration:**
- Backup and recovery strategies
- User management and security
- Monitoring and maintenance
- Migration planning and execution
- Understanding when to use extensions

#### 4. Version Control & Collaboration

**Git/GitHub:**
- Branching and merging strategies
- Pull requests and code review
- Commit message best practices
- Repository organization
- Documentation standards

**GitLab:**
- CI/CD pipelines basics
- Collaboration workflows
- Issue tracking integration

**Containers:**
- Docker fundamentals for PostgreSQL deployment
- Container orchestration basics
- Azure container deployment

#### 5. Web Development (HTML/CSS/JavaScript)

**Goal:** Build modern, functional website for archaeological data

**Requirements:**
- Clean, professional design
- Query interface for researchers
- Data deposit workflows
- Geospatial data visualization
- User authentication and permissions

**Approach:** Learn enough to prototype and communicate with web developers, not necessarily build everything from scratch.

#### 6. Development Workflows

**Professional Practices:**
- Documentation standards
- Code organization and modularity
- Testing and validation
- Deployment procedures
- Team collaboration patterns

---

## Three-Phase Learning Plan

### Phase 1: Consolidation & Confidence (Months 1-3)

**Primary Goal:** Own what you've already built; reduce dependency on AI for basic troubleshooting

**Philosophy:** You can't build new things confidently until you understand what you've already created. This phase focuses on **reading comprehension and debugging** rather than writing new code.

#### Focus Areas

**1. Understanding Your Existing Scripts (Weeks 1-4)**
- Line-by-line walkthrough of current automation (position_update_v3.py, etc.)
- Trace execution flow through complex scripts
- Map dependencies between scripts
- Document "what runs when and why"
- Identify patterns you can reuse

**Deliverable:** Script map document showing your current automation architecture

**2. PostgreSQL Fundamentals for DBAs (Weeks 2-6)**
- Server architecture and connection management
- User roles, permissions, and security
- Backup strategies and disaster recovery
- Schema modification best practices
- Reading EXPLAIN plans for query optimization
- Understanding PostgreSQL logs and error messages
- Safe production database changes

**Deliverable:** Database administration runbook for your server

**3. Debugging Fundamentals (Weeks 3-8)**
- Reading Python tracebacks and stack traces
- Strategic use of print statements and logging
- PostgreSQL error message interpretation
- Systematic debugging methodology
- Using breakpoints (introduction to debugging tools)
- Common error patterns and solutions

**Deliverable:** Personal debugging checklist and common errors reference

**4. Git Basics for Version Control (Weeks 4-8)**
- Repository creation and initialization
- Commit workflow and best practices
- Branch creation and switching
- Merge basics (avoiding conflicts)
- .gitignore for database credentials
- Basic GitHub workflow

**Deliverable:** All existing scripts committed to GitHub with proper structure

**5. Basic GUI with tkinter (Weeks 6-12)**
- Event-driven programming concepts
- Building simple button-based interfaces
- Layout management (grid, pack)
- Progress bars and status indicators
- Error handling in GUIs
- User input validation
- Packaging for distribution to team

**Deliverable:** GUI launcher for existing scripts that your team can actually use

#### Weekly Time Allocation (Phase 1)

**Total: 15 hours/week average**

- **5 hours:** Structured learning (reading Python/PostgreSQL docs, working through tutorials)
- **7 hours:** Hands-on work (understanding existing scripts, building GUI launcher)
- **3 hours:** Documentation and review (capturing what you learned)

#### Phase 1 Success Criteria

By end of Month 3, you should be able to:
- ✅ Explain what every line in your current automation scripts does
- ✅ Troubleshoot and fix common errors without AI assistance
- ✅ Make small modifications to existing scripts independently
- ✅ Perform basic PostgreSQL server administration tasks
- ✅ Use Git to track changes to your code
- ✅ Deploy a working GUI that your team can use to run scripts

**Critical Milestone:** Your team successfully uses your GUI launcher without your direct assistance.

---

### Phase 2: Extension & Data Design (Months 4-6)

**Primary Goal:** Design new schemas and write helper scripts independently (with AI review)

**Philosophy:** Now that you understand existing systems, you can confidently extend them. This phase focuses on **design thinking and implementation** rather than just maintenance.

#### Focus Areas

**1. Data Modeling & Normalization Theory (Weeks 13-18)**
- Normal forms (1NF, 2NF, 3NF, BCNF) - formal understanding
- When to normalize vs. denormalize
- Entity-relationship diagrams
- Referential integrity patterns
- Temporal data modeling (tracking history)
- Handling hierarchical data
- Schema evolution strategies

**Practice Project:** Design China or Iran ORBAT schema from scratch, get AI review

**Deliverable:** New theater database schema (fully documented)

**2. Intermediate Python for Automation (Weeks 14-20)**
- Writing maintainable functions
- Working with JSON files (reading, writing, validation)
- Pandas for data transformation workflows
- GeoPandas for spatial data processing
- **ArcPy fundamentals** - geoprocessing, cursors, field calculations
- **ArcPy spatial operations** - geometry manipulation, spatial analysis
- Error handling with try/except/finally
- Logging instead of print statements
- Configuration files for script settings
- Command-line arguments with argparse

**Practice Project:** Rewrite one existing script with proper structure + ArcPy automation for routine ArcGIS tasks

**Deliverable:** 2-3 new helper scripts written independently (with AI review), including at least one ArcPy script

**3. SQL Beyond Queries (Weeks 15-22)**
- Common Table Expressions (CTEs) for complex queries
- Window functions for analytical queries
- Writing PostgreSQL functions (beyond basic CRUD)
- Triggers for automated data quality
- Advanced constraints and validations
- Creating views for specific use cases (e.g., for visualization colleague)
- Materialized views for performance
- Understanding transaction isolation levels

**Practice Project:** Build data quality views for your visualization colleague

**Deliverable:** Suite of views ready for visualization work

**4. Git/GitHub Workflows (Weeks 16-22)**
- Feature branch workflow
- Pull requests and code review process
- Merge conflict resolution
- Collaborative development patterns
- Documentation in README files
- Issue tracking and project management
- GitHub Actions basics (introduction to CI/CD)

**Practice Project:** Collaborate on a feature branch with AI as reviewer

**Deliverable:** Documented GitHub workflow for future team members

**5. GitLab & Containers Introduction (Weeks 20-24)**
- GitLab vs GitHub differences
- Basic Docker concepts
- Creating Dockerfiles
- Docker Compose for multi-container setups
- PostgreSQL in containers
- Azure Container Instances basics
- When to use containers vs. traditional deployment

**Practice Project:** Containerize your PostgreSQL database for testing

**Deliverable:** Docker setup for local development environment

#### Weekly Time Allocation (Phase 2)

**Total: 15 hours/week average**

- **4 hours:** Structured learning (database theory, intermediate Python concepts)
- **8 hours:** Design and implementation (schema design, new scripts, views)
- **3 hours:** Documentation and review (schema docs, code documentation)

#### Phase 2 Success Criteria

By end of Month 6, you should be able to:
- ✅ Design a normalized database schema for a new domain
- ✅ Write Python scripts from scratch (with occasional AI consultation)
- ✅ Create complex SQL queries using CTEs and window functions
- ✅ Write PostgreSQL functions for data workflows
- ✅ Use Git branching workflow effectively
- ✅ Understand when and how to use containers

**Critical Milestone:** New theater ORBAT schema implemented and accepted by stakeholders.

---

### Phase 3: Web & Advanced Automation (Months 7-12)

**Primary Goal:** Build toward website capability; position for leadership

**Philosophy:** You now have solid foundations. This phase focuses on **expanding your toolkit** for the archaeological website and **demonstrating leadership-level competency** at work.

#### Focus Areas

**1. HTML/CSS/JavaScript Basics (Weeks 25-36)**
- HTML structure and semantic markup
- CSS for styling and layout
- Responsive design principles
- JavaScript for interactivity
- DOM manipulation
- Fetch API for backend communication
- Modern frameworks overview (React, Vue - awareness level)

**Practice Project:** Static prototype of archaeological website

**Deliverable:** Functional HTML/CSS prototype with basic JavaScript

**2. Backend for Web Applications (Weeks 28-40)**
- Flask framework basics
- RESTful API design
- Connecting Flask to PostgreSQL
- Authentication and authorization
- Form handling and validation
- File uploads for data deposits
- API security basics

**Practice Project:** Simple API for querying your database

**Deliverable:** Backend API for archaeological database

**3. Advanced Python Libraries (Weeks 26-44)**
- `python-docx` for automated report generation
- `rapidfuzz` for data matching and deduplication
- Advanced GeoPandas (spatial joins, overlays, aggregations)
- Data validation libraries
- Testing frameworks (pytest introduction)
- Package creation basics

**Practice Project:** Automated weekly intelligence report generator

**Deliverable:** Report generation tool for ISW workflows

**4. Database Performance & Optimization (Weeks 30-46)**
- Indexing strategies (B-tree, GiST, GIN)
- Query optimization techniques
- Partitioning strategies (you already use hash partitioning - understand it deeper)
- Connection pooling
- Monitoring and alerting
- Backup strategies (pg_dump, continuous archiving)
- Maintenance tasks (VACUUM, ANALYZE)

**Practice Project:** Optimize slowest queries in your database

**Deliverable:** Database performance monitoring dashboard

**5. Advanced GUI Development (Weeks 32-48)**
- Tab-based interfaces with ttkbootstrap
- Better layouts and styling
- Configuration file management
- Multi-threaded GUIs (preventing freezing)
- Packaging Python apps for distribution
- Auto-update mechanisms
- User preferences and settings

**Practice Project:** Enhanced GUI dashboard with tabs and configuration

**Deliverable:** Polished, production-ready GUI for ISW workflows

**6. Integration & Geospatial Visualization (Weeks 35-48)**
- Mapbox GL JS for web mapping
- GeoJSON for data exchange
- Leaflet as alternative mapping library
- PostGIS spatial queries for web applications
- Tile serving for large datasets
- Real-time data updates

**Practice Project:** Interactive web map for archaeological data

**Deliverable:** Archaeological website with functional map interface

#### Weekly Time Allocation (Phase 3)

**Total: 15 hours/week average**

- **3 hours:** Structured learning (web technologies, new libraries)
- **9 hours:** Project work (website development, advanced automation)
- **3 hours:** Documentation and polish (user guides, deployment docs)

#### Phase 3 Success Criteria

By end of Month 12, you should be able to:
- ✅ Build a functional web application with database backend
- ✅ Create polished, user-friendly GUIs for complex workflows
- ✅ Optimize database performance and diagnose bottlenecks
- ✅ Generate automated reports from database queries
- ✅ Deploy applications to cloud infrastructure (Azure)
- ✅ Communicate technical requirements to potential team members

**Critical Milestones:**
1. Functional prototype of archaeological website (or at least backend + simple frontend)
2. Production-quality GUI dashboard for ISW that demonstrably saves team time
3. Documentation sufficient to hand off projects to junior developers
4. Technical specification for hiring needs (if building data team)

---

## Weekly Structure & Methodology

### Time Allocation Framework

**Average commitment:** 15 hours/week  
**Reality:** Variable day-to-day (some days 5 hours, some days 0 hours)  
**Strategy:** Weekly planning with flexible daily execution

### Weekly Rhythm

**Monday (Planning Day - 1-2 hours)**
- Review last week's progress
- Set 3-5 specific goals for the week
- Identify blockers and questions
- Schedule learning blocks on calendar

**Tuesday-Thursday (Deep Work Days - 10-12 hours total)**
- Structured learning sessions (reading, tutorials)
- Hands-on project work
- Code writing and debugging
- AI consultation sessions

**Friday (Review & Documentation - 2-3 hours)**
- Document what you learned
- Update progress tracker
- Prepare questions for next week
- Clean up and commit code to GitHub

**Weekend (Optional - 0-2 hours)**
- Overflow for week's goals if needed
- Light reading or exploration
- Usually used for catch-up, not primary learning

### Learning Session Structure

**Structured Learning Block (60-90 minutes):**
1. Review objective (what am I learning today?)
2. Read/watch tutorial content (30-45 min)
3. Take notes and highlight key concepts (15-20 min)
4. Try simple example yourself (20-30 min)
5. Document 1-2 key takeaways (5-10 min)

**Project Work Block (90-120 minutes):**
1. Define specific task (what am I building?)
2. Break into small steps (plan approach)
3. Implement in 25-minute focused bursts
4. Test and debug
5. Document what worked/didn't work
6. Commit progress to Git

**AI Consultation Strategy:**
- Bring specific problems, not vague requests
- Try solving yourself first, then ask for help
- Request explanations, not just solutions
- Ask for code review after writing
- Build up personal solution patterns

### Teaching Mode vs. Explainer Mode

**When "TEACHING MODE" is active:**
- AI asks questions before giving answers
- You're guided to solutions rather than given them
- Focus on understanding WHY, not just WHAT
- More time-intensive but builds deeper knowledge

**When "EXPLAINER MODE" is active:**
- AI provides direct explanations and solutions
- Faster for time-sensitive work problems
- Good for production troubleshooting
- Less learning depth, more immediate productivity

**Recommendation:** Use TEACHING MODE for learning sessions, EXPLAINER MODE for urgent work issues.

### Documentation Practice

**What to document:**
- Problems you solved and how you solved them
- New concepts you learned (in your own words)
- Code snippets worth reusing
- Questions that came up (even if unanswered)
- Mistakes you made and what you learned

**Where to document:**
- `Progress_Tracker.md` - Weekly progress and blockers
- `Concept_Library.md` - Growing glossary of terms and concepts
- `Common_Errors_and_Solutions.md` - Personal debugging knowledge base
- GitHub commit messages - What changed and why
- Code comments - Why you made specific choices

**Why this matters:** Documentation is how you transform learning into lasting knowledge. Writing forces clarity.

---

## Reading List & Resources

### Essential Books (Priority Order)

**1. Database Design (Start immediately)**
- *Database Design for Mere Mortals* by Michael J. Hernandez
  - Focus: Normalization theory, schema design principles
  - Why: Fills your conceptual gaps in database design
  - When: Phase 1-2, reference throughout

**2. Python Fundamentals (Start Month 1)**
- *Automate the Boring Stuff with Python* (2nd Edition) by Al Sweigart
  - Focus: Practical Python for automation tasks
  - Why: Matches your use cases (file processing, web scraping, automation)
  - Chapters to prioritize: 
    - Ch 8-9: File I/O
    - Ch 11: Web scraping
    - Ch 12: Working with Excel/CSV
    - Ch 15-16: Time scheduling, email
  - When: Phase 1-2, reference as needed
  - Free online: https://automatetheboringstuff.com/

**3. PostgreSQL Deep Dive (Start Month 3-4)**
- *PostgreSQL: Up and Running* by Regina Obe and Leo Hsu
  - Focus: PostgreSQL-specific features and administration
  - Why: Goes beyond SQL basics to PostGIS and server management
  - When: Phase 2, reference throughout

**4. Web Development (Start Month 7)**
- *Flask Web Development* by Miguel Grinberg
  - Focus: Building web applications with Flask
  - Why: Practical approach to backend development
  - When: Phase 3

**Optional but Valuable:**
- *Fluent Python* by Luciano Ramalho (intermediate Python, Phase 2-3)
- *PostGIS in Action* by Regina Obe and Leo Hsu (deep PostGIS, as needed)
- *Pro Git* by Scott Chacon (comprehensive Git reference, Phase 1-2)

### Online Documentation (Always Available)

**Primary References:**
- PostgreSQL Official Docs: https://www.postgresql.org/docs/16/
  - Bookmark: SQL Commands, Functions, PostGIS extension
- Python Official Docs: https://docs.python.org/3/
  - Bookmark: Built-in Functions, Standard Library
- GeoPandas Docs: https://geopandas.org/
- Pandas Docs: https://pandas.pydata.org/docs/
- tkinter Tutorial: https://docs.python.org/3/library/tkinter.html

**ArcGIS Resources:**
- ArcGIS Pro Python Reference: https://pro.arcgis.com/en/pro-app/latest/arcpy/
- ArcPy Get Started: https://pro.arcgis.com/en/pro-app/latest/arcpy/get-started/what-is-arcpy-.htm
- ArcGIS API for Python: https://developers.arcgis.com/python/
- ArcGIS Online Developer Docs: https://developers.arcgis.com/documentation/
- **Key ArcPy modules to bookmark:**
  - arcpy.da (Data Access) - cursors for reading/writing
  - arcpy.management - geoprocessing tools
  - arcpy.analysis - spatial analysis
  - Geometry objects - spatial operations

**Web Development:**
- MDN Web Docs (HTML/CSS/JavaScript): https://developer.mozilla.org/
- Flask Documentation: https://flask.palletsprojects.com/
- Mapbox GL JS: https://docs.mapbox.com/mapbox-gl-js/

### Video Resources (Supplementary)

**When text isn't clicking:**
- Corey Schafer's Python Tutorials (YouTube) - Excellent explanations
- Traversy Media (YouTube) - Web development
- Hussein Nasser (YouTube) - Database concepts

### Forums & Community Resources

**For troubleshooting and best practices:**
- Stack Overflow - Search before asking
- Reddit: r/PostgreSQL, r/learnpython, r/flask
- PostgreSQL Mailing Lists
- GIS Stack Exchange

**Important:** When using forum advice (especially Reddit), always note it's from forums (not official docs) and verify before implementing in production.

### Course Platforms (If Needed)

**Not required, but available if you prefer structured courses:**
- DataCamp (interactive Python/SQL)
- Coursera (database design courses)
- Udemy (specific technology courses on sale)

**Recommendation:** Start with books and documentation; only add courses if you're struggling with self-directed learning.

---

## Success Metrics

### Quantitative Metrics

**Phase 1 (Months 1-3):**
- [ ] 100% of existing scripts documented and understood
- [ ] GUI launcher used successfully by ≥3 team members
- [ ] 0 major database incidents due to lack of understanding
- [ ] ≥20 Git commits with meaningful messages
- [ ] Personal debugging checklist with ≥10 common error patterns

**Phase 2 (Months 4-6):**
- [ ] New theater database schema designed and reviewed
- [ ] ≥3 helper scripts written independently
- [ ] ≥5 database views created for visualization colleague
- [ ] Feature branch workflow successfully completed
- [ ] Docker development environment functional

**Phase 3 (Months 7-12):**
- [ ] Archaeological website prototype deployed
- [ ] Advanced GUI with ≥3 tabs and configuration system
- [ ] Database query performance improved by ≥25% (measured)
- [ ] Automated report generation saving ≥2 hours/week
- [ ] Technical specification document for hiring prepared

### Qualitative Metrics

**Am I achieving the goals?**

**Can you:**
- Explain technical concepts to non-technical colleagues clearly?
- Debug most common errors without AI assistance?
- Review AI-generated code and identify potential issues?
- Design a database schema and defend design choices?
- Collaborate effectively with developers (when you hire them)?
- Make confident technical decisions about infrastructure?

**Are you demonstrating leadership?**
- Team members using your tools without constant support?
- Stakeholders trusting your technical recommendations?
- Able to spec out projects and estimate effort?
- Comfortable saying "I don't know, but I'll find out"?
- Building documentation that helps others learn?

### Career Milestones

**Work (ISW):**
- ✅ Successfully managing database server (Month 3)
- ✅ Proving value to justify data team creation (Month 6-9)
- ✅ Ready to hire and lead junior developers (Month 12)

**Side Project (Archaeological Database):**
- ✅ Functional design completed with advisor (Month 6)
- ✅ Funding proposals written with technical specifications (Month 9-12)
- ✅ Proof-of-concept deployed with Sparta data (Month 12+)

**Personal Development:**
- ✅ Confident in technical skills (Month 6)
- ✅ Positioned for career transition if needed (Month 12)
- ✅ Technical competency at "junior software engineer" level (Month 12)

---

## Reference Files

### Russian ORBAT Tracking

**Architecture & Design:**
- `complete_russianorbat_schema.sql` - Comprehensive database design

**Function Documentation Examples:**
- `functions_schema.sql`

**Tool Documentation:**
- `mentions.py` - Python script for adding mentions into the database.
- `mentionsgui.py` - GUI wrapper for the above script.
- `commit_mentions.py` - Python script for committing mentions and converting them to unit position records.
- `commit_mentions_gui.py` - GUI wrapper for the above script.
- `insert_unit_gui.py` - GUI wrapped script for adding new units into the database.
- `Alcamenes.py` - Python script for searching the archive of collect documents.
- `AlcamenesGUI.py` - GUI wrapper for the above script.
- `fcs_base.py` - Python script for turning settlement callouts into a shapefile.
- `fcs.py` - GUI wrapper for the above script.
- `uaf_strike_report_generator.py` - Python script for turning Telegram posts into Excel data and a formatted paragrahp.
- `uaf_strike_report_gui.py` - GUI wrapper for the above script.
- `Datetime.py` - ArcPy script to add a date field to batch shapefiles for time lapses.
- `layouts_export.py` - ArcPy script to export daily layouts.
- `Package_Export.py` - ArcPy script to export the package for team use.
- `shapefiles_export.py` - ArcPy script to export daily shapefile products.

### Greek Archaeological Data

**Architecture & Design:**
- `complete_greek_excavation_schema.sql` - Complete database architecture.

**Tool Documentation:**
- `1x1km.py` & `1k_for_100k.py` & `100x100m for 1x1km tiles.py` - Python script for naming the grid reference system in a hierarchy system.

**References:**
- `CPW Sparta GIS Article 12 July 2023.pdf` - Paper outlining project methodology.
- <https://tidsskrift.dk/classicaetmediaevalia/article/view/146573/189795> - Paper outlining results of spatial analysis of data for Sparta.
- <https://tidsskrift.dk/classicaetmediaevalia/article/view/159599/201470> - Paper outlining analysis of data for all of Lakonia.

### Learning Project Files

**Core Planning:**
- `Learning_Plan_Master.md` - This document
- `Progress_Tracker.md` - Weekly progress log
- `Code_Review_Template.md` - Standard format for code reviews

**Knowledge Building:**
- `Concept_Library.md` - Growing glossary of technical terms
- `Reading_List_and_Resources.md` - Expanded resource links
- `Common_Errors_and_Solutions.md` - Personal debugging knowledge base
- `Practice_Exercises.md` - Specific exercises by phase

**Workflow Tools:**
- `Questions_for_Claude.md` - Template for articulating technical questions
- `Weekly_Planning_Template.md` - Structure for Monday planning sessions

**Hardware Specifications:**
- `My_PC_Specs.md` - Development workstation specs
---

## Working with Claude: The AI Collaboration Model

### Your Technical Stack (Explained)

**Layer 1: Claude as Sounding Board (This Chat)**
- Brainstorming ideas and approaches
- Architectural decisions and design review
- Conceptual questions and explanations
- Progress check-ins and learning guidance

**Layer 2: Claude Code for Implementation**
- Writing complex scripts (when needed)
- Generating boilerplate code
- Database schema generation
- Large refactoring tasks

**Layer 3: Your Understanding & Modification**
- Reading and understanding generated code
- Making modifications and extensions
- Debugging when things break
- Validating AI suggestions before implementation

**Layer 4: Production Deployment**
- Testing thoroughly before deployment
- Documenting for team/future self
- Monitoring and maintaining
- Iterating based on real usage

### Special Guidance for Your Learning Style

**Given your "LLM brain" pattern:**

**When you feel you understand something:**
```
❌ DON'T: "I get it, let's move on"
✅ DO: "I think I understand. Let me code it from scratch without looking"
✅ DO: "Can you give me a challenge problem to test this?"
✅ DO: "I'll explain this back to you - stop me if I'm wrong"
```

**When taking notes:**
```
❌ DON'T: Spend 20 minutes color-coding and formatting
✅ DO: Use the pre-structured templates (they're already organized)
✅ DO: Quick bullet points during learning, clean up later IF needed
✅ DO: Code comments > separate documentation
```

**When interest starts waning:**
```
❌ DON'T: Push through with grinding (leads to burnout)
✅ DO: Switch between different types of work (code, database, docs)
✅ DO: Build something tangible for your actual work
✅ DO: Revisit why this matters for your goals
✅ DO: Take a planned break and come back fresh
```

**When concepts seem easy:**
```
⚠️ WARNING: This is when "hallucinated understanding" is most likely
✅ DO: Test yourself immediately with novel application
✅ DO: Try to break it intentionally
✅ DO: Ask for edge cases you haven't considered
```

### When to Use Which Tool

**Use Claude Chat (Conversational) for:**
- "Why does this approach make sense?"
- "What's the trade-off between X and Y?"
- "Can you explain how this code works?"
- "Is this schema design sound?"
- "What should I learn next?"

**Use Claude Code for:**
- "Write a script that processes these files"
- "Generate the SQL for this schema"
- "Refactor this messy code"
- "Create a GUI with these features"

**Do Yourself for:**
- Small modifications to existing code
- Configuration changes
- Simple queries and functions
- Documentation
- Testing and validation

### Effective Prompting Strategies

**For Learning (TEACHING MODE):**
```
I'm working on [specific task]. Before you give me the solution, 
can you help me think through:
1. What's the core problem I'm solving?
2. What are 2-3 approaches I could take?
3. What are the trade-offs?

Then let's work through the implementation together.
```

**For Code Review:**
```
I wrote this function to [purpose]. Can you review it for:
- Correctness
- Best practices I'm missing
- Potential bugs or edge cases
- Better ways to structure it

[paste code]
```

**For Troubleshooting:**
```
I'm getting this error: [error message]

Context:
- What I'm trying to do: [explanation]
- What I've tried: [list attempts]
- What I don't understand: [specific confusion]

Can you help me understand what's happening?
```

### Building Your Own Solution Patterns

As you work with AI, you'll notice patterns in solutions. Start collecting these:

**Pattern Example: "Safe Database Schema Change"**
```
1. Create new column/table (don't drop old one yet)
2. Backfill data from old to new
3. Dual-write period (update both)
4. Validate new structure works
5. Switch applications to use new structure
6. Archive (don't drop) old structure
```

**Your Pattern Library** (to build over time):
- Data validation patterns
- Error handling patterns
- GUI layout patterns
- Database query optimization patterns
- Testing patterns

**For your language-oriented brain:** Think of these as "conjugation tables" for code:

| Latin Concept | Python Equivalent | Pattern |
|--------------|-------------------|---------|
| Verb conjugation (amo, amas, amat) | Function definition | `def function_name(params):` |
| Noun declension (cases) | Object attributes | `object.attribute` |
| Genitive case (possession) | Dot notation | `unit.name`, `position.coordinates` |
| Ablative (by/with/from) | Method chaining | `df.filter().sort().head()` |
| Conditional clauses | if/elif/else | Structure follows logic patterns |
| Relative clauses | List comprehensions | Embedded transformation logic |

Your brain that mastered Latin declensions will excel at Python syntax patterns - they're both rule-based transformational systems.

---

## Adapting This Plan

### This Plan is a Living Document

**Expected to change:**
- Pace might be faster or slower than estimated
- Work priorities might shift focus areas
- New technologies might become relevant
- Resources might be more/less helpful than expected

**What to do when plans change:**
1. Update this document with revisions
2. Document why the change happened
3. Adjust timeline and expectations
4. Don't feel guilty about adaptation

### Red Flags to Watch For

**Warning signs you need to adjust:**
- ⚠️ Consistently falling behind weekly goals (burnout risk)
- ⚠️ Breezing through material without understanding (going too fast)
- ⚠️ Avoiding certain topics repeatedly (knowledge gaps or bad resources)
- ⚠️ Not using what you learn in practice (learning without application)
- ⚠️ Team still can't use your tools (building wrong things)

**When you see red flags:**
- Pause and assess honestly
- Adjust pace, resources, or approach
- Get feedback from Claude or colleagues
- Remember: sustainable beats fast

### Getting Unstuck

**When you're stuck on a concept:**
1. Try explaining it to someone else (even rubber duck)
2. Find a different resource (video if you've been reading)
3. Build something with it, even if you don't fully understand
4. Ask Claude in TEACHING MODE
5. Move on and come back later (sometimes you need context first)

**When you're stuck on a project:**
1. Break it into smaller pieces
2. Get one small thing working
3. Ask for code review even if incomplete
4. Check if you're solving the right problem
5. Simplify scope if needed

---

## Final Notes: The Philosophy of This Plan

### You Are Not Becoming a Solo Full-Stack Developer

**You ARE becoming:**
- A technical product owner who can spec and validate
- A database architect who can design and optimize
- An automation engineer who can build and maintain workflows
- A team lead who can work with specialists
- A problem solver who knows when to build vs. when to hire

**You are NOT trying to:**
- Replace professional web developers for complex applications
- Become a machine learning engineer
- Build enterprise software from scratch
- Know everything about every technology

### The AI-Augmented Professional

This plan embraces a modern reality: **professionals don't work alone, they work with tools.** AI is one of your tools, just like:
- PostgreSQL is a tool for data storage
- ArcGIS is a tool for visualization
- Git is a tool for version control

**The skill isn't "can you code without AI?"**  
**The skill is "can you validate, modify, and deploy AI-generated code reliably?"**

### Measure Progress by Impact, Not Just Knowledge

**Don't ask:** "Did I learn X this week?"  
**Ask:** "Can I now do Y that I couldn't before?"

**Don't ask:** "Do I understand all of Python?"  
**Ask:** "Can I build the tools my team needs?"

**Don't ask:** "Am I as good as a professional developer?"  
**Ask:** "Can I lead technical projects effectively?"

### The Long Game

This is a 12-month intensive plan, but your learning doesn't stop at month 12. By the end:

**You should be able to:**
- Learn new technologies independently
- Evaluate technical approaches critically
- Build and maintain production systems
- Lead technical teams and projects
- Continue growing as a technical professional

**The real measure of success:** In month 13, you're still learning, but you're learning different (more advanced) things, and you're learning them faster because you have solid foundations.

---

## Version History

**v1.1 (November 16, 2025)**
- Added ArcPy as priority Python library across all phases
- Added comprehensive learner profile section
- Included cognitive strengths and learning challenges
- Added learner-specific guidance for AI collaboration
- Expanded red flags specific to learning style
- Added optimal learning strategies based on profile

**v1.0 (November 16, 2025)**
- Initial comprehensive learning plan
- Three-phase structure (12 months)
- Integrated work and side project goals
- AI collaboration methodology
- Reading list and resources

---

**Let's build something great. Start with Phase 1, Week 1, Monday planning.**

**Your first task:** Set up your GitHub repositories and commit your first piece of code (even if it's just your existing scripts with documentation).

**Questions to answer in Week 1:**
1. What's the single most important thing for me to understand about my current automation?
2. What's the one database concept I'm shakiest on right now?
3. What's my biggest fear about this learning journey?

Face those questions honestly, and we'll tackle them together.

---

*End of Learning Plan Master Document v1.0*
