# Reading List & Resources

**Last Updated:** November 2025  
**Status:** Living document - update as you discover new resources

---

## Core Books

### Database Design
**📘 Database Design for Mere Mortals (3rd Edition)**  
**Author:** Michael J. Hernandez  
**Priority:** HIGH  
**Phase:** 2  
**Timeline:** Weeks 1-6

**Focus Chapters:**
- Ch 1-3: Relational Database Design Fundamentals
- Ch 4-5: Data Analysis
- Ch 6-10: Design Process & Normalization
- Ch 11-12: Business Rules & Views

**Reading Strategy:**
- Read chapters 1-3 first time through quickly for overview
- Deep read chapters 4-10 with note-taking
- Apply concepts to China ORBAT schema design
- Reference chapters 11-12 as needed

**Key Takeaways to Focus On:**
- [ ] Why normalization matters
- [ ] How to identify entities vs. attributes
- [ ] When to denormalize (and why)
- [ ] Primary key selection strategies
- [ ] Foreign key relationship types

---

### Python Programming
**📗 Automate the Boring Stuff with Python (2nd Edition)**  
**Author:** Al Sweigart  
**Priority:** HIGH  
**Phase:** 1-2  
**Free Online:** https://automatetheboringstuff.com/

**Essential Chapters:**
- Ch 3: Functions
- Ch 6: Manipulating Strings
- Ch 8: Reading and Writing Files
- Ch 9: Organizing Files
- Ch 10: Debugging
- Ch 11: Web Scraping
- Ch 13: Working with Excel Spreadsheets
- Ch 14: Working with CSV Files and JSON

**Reading Strategy:**
- Start with Ch 10 (Debugging) in Phase 1
- Read Ch 3, 6 in Phase 1
- Read Ch 8-9, 13-14 in Phase 2
- Ch 11 in Phase 3 (web development)

**Practice Projects:**
- Modify author's examples to use your ORBAT data
- Build file processing scripts for ArcGIS exports
- Create automated reporting tools

---

### Web Development
**📙 HTML and CSS: Design and Build Websites**  
**Author:** Jon Duckett  
**Priority:** MEDIUM  
**Phase:** 3  
**Timeline:** Weeks 1-8

**Focus:**
- HTML structure and semantics
- CSS layout techniques
- Responsive design
- Modern web standards

**Supplement With:**
- MDN Web Docs for reference
- Real examples from archaeology project needs

---

## Online Documentation (Primary References)

### PostgreSQL
**Official Documentation:** https://www.postgresql.org/docs/16/

**Essential Sections:**

**Phase 1 - Server Administration:**
- Part III: Server Administration
  - Ch 18: Server Setup and Operation
  - Ch 19: Server Configuration
  - Ch 20: Client Authentication
  - Ch 21: Database Roles
  - Ch 24: Backup and Restore
  - Ch 27: Monitoring Database Activity

**Phase 2 - Advanced SQL:**
- Part II: The SQL Language
  - Ch 7.8: WITH Queries (CTEs)
  - Ch 4.2: Window Functions
  - Ch 9: Functions and Operators
  - Ch 37: Triggers
  - Ch 38: PL/pgSQL

**Phase 3 - Performance:**
- Ch 14: Performance Tips
- Ch 11.1: Indexes
- Ch 5.11: Table Partitioning

**Reading Strategy:**
- Don't read linearly - use as reference
- Search for specific topics when needed
- Bookmark frequently-used sections
- Read examples carefully

---

### PostGIS
**Official Documentation:** https://postgis.net/documentation/

**Essential Sections:**
- Ch 4: Using PostGIS (spatial queries)
- Ch 5: Spatial Relationships and Measurements
- Ch 8: Performance Tips
- Ch 12: Reference (function lookup)

**When to Reference:**
- Phase 1: Basic spatial queries
- Phase 2: Complex spatial analysis
- Phase 3: Performance optimization

---

### Python Libraries

**GeoPandas**  
**Docs:** https://geopandas.org/  
**Phase:** 2-3

**Essential Guides:**
- Getting Started
- User Guide: Data Structures
- User Guide: Spatial Relationships
- User Guide: Coordinate Reference Systems
- Gallery: Examples

**Key Functions to Master:**
- `read_file()`, `to_file()`
- `.plot()` for visualization
- `.sjoin()` for spatial joins
- `.overlay()` for geometric operations
- `.to_crs()` for projection transforms

---

**Pandas**  
**Docs:** https://pandas.pydata.org/  
**Phase:** 2

**Essential Sections:**
- 10-minute tutorial
- User Guide: DataFrame basics
- User Guide: Merge, join, concatenate
- User Guide: Grouping
- User Guide: Time series

**Focus:**
- DataFrame manipulation
- Filtering and selection
- Aggregations and grouping
- Merging datasets

---

**tkinter / ttkbootstrap**  
**tkinter:** https://docs.python.org/3/library/tkinter.html  
**ttkbootstrap:** https://ttkbootstrap.readthedocs.io/  
**Phase:** 1, 3

**Learning Path:**
- Phase 1: Basic buttons, layouts, progress bars
- Phase 3: Advanced widgets, themes, configurations

**Key Concepts:**
- Event-driven programming
- Widget hierarchy
- Layout managers (pack, grid, place)
- Event binding
- Threading for long operations

---

**python-docx**  
**Docs:** https://python-docx.readthedocs.io/  
**Phase:** 3

**Use Cases:**
- Automated report generation
- Template-based documents
- Formatting and styling

---

**rapidfuzz**  
**Docs:** https://maxbachmann.github.io/RapidFuzz/  
**Phase:** 3

**Use Cases:**
- Unit name matching/deduplication
- Fuzzy string searching
- Data quality improvement

---

### ArcGIS

**ArcGIS Pro Python Reference**  
**Docs:** https://pro.arcgis.com/en/pro-app/latest/arcpy/

**Essential Sections:**
- Getting Started with ArcPy
- Spatial Analyst module
- Data Access module (cursors)
- Mapping module
- Geoprocessing tools

**Phase 1-2 Focus:**
- Understanding cursors (SearchCursor, UpdateCursor)
- Field calculations
- Geometry objects

**Phase 3 Focus:**
- Automation workflows
- Map production
- Integration with database

---

**ArcGIS Python API**  
**Docs:** https://developers.arcgis.com/python/  
**Phase:** 3

**Use Cases:**
- ArcGIS Online integration
- Web map publishing
- Spatial analysis in notebooks

---

### Git & Version Control

**GitHub Documentation**  
**Docs:** https://docs.github.com/  
**Phase:** 1-2

**Essential Guides:**
- Quickstart
- Getting Started: Git Basics
- Collaborating: Pull Requests
- Managing Files
- GitHub Desktop Guide

**Focus Topics:**
- Commits and commit messages
- Branching strategies
- Merging and resolving conflicts
- .gitignore files

---

**GitLab Documentation**  
**Docs:** https://docs.gitlab.com/  
**Phase:** 2-3

**Essential Sections:**
- GitLab Basics
- CI/CD Pipelines
- Collaboration workflows

---

### Web Development

**MDN Web Docs**  
**Site:** https://developer.mozilla.org/  
**Phase:** 3

**Learning Paths:**
- HTML: Structuring the Web
- CSS: Styling the Web
- JavaScript: Dynamic client-side scripting

**Best Use:**
- Comprehensive reference
- Examples and tutorials
- Best practices

---

**Flask Documentation**  
**Docs:** https://flask.palletsprojects.com/  
**Phase:** 3

**Essential Sections:**
- Quickstart
- Tutorial
- Patterns: Database integration
- Deployment options

---

### Docker & Deployment

**Docker Documentation**  
**Docs:** https://docs.docker.com/  
**Phase:** 3

**Essential Guides:**
- Get Started
- PostgreSQL Docker images
- Docker Compose
- Best practices

---

## Video Courses & Tutorials

### Python

**Corey Schafer - Python Tutorials**  
**Platform:** YouTube  
**Link:** https://www.youtube.com/c/Coreyms  
**Phase:** 1-3  
**Priority:** HIGH

**Recommended Playlists:**
- Python Programming Beginner Tutorials
- Python OOP Tutorials
- Git Tutorials
- Flask Tutorials (Phase 3)

**Why It's Great:**
- Clear explanations
- Practical examples
- Good pacing
- Free

---

**Real Python**  
**Site:** https://realpython.com/  
**Phase:** 1-3

**Recommended Tutorials:**
- Python Debugging
- Working with Files
- Python Testing
- Web Development

**Note:** Some content requires membership

---

### SQL & Databases

**Mode Analytics SQL Tutorial**  
**Link:** https://mode.com/sql-tutorial/  
**Phase:** 1-2  
**Focus:** SQL fundamentals and analytics

---

**PostgreSQL Tutorial**  
**Site:** https://www.postgresqltutorial.com/  
**Phase:** 1-3

**Organized Topics:**
- Basic queries
- Joins
- Advanced queries (CTEs, window functions)
- PostgreSQL administration

---

### Web Development

**freeCodeCamp**  
**Site:** https://www.freecodecamp.org/  
**Phase:** 3

**Relevant Certifications:**
- Responsive Web Design
- JavaScript Algorithms
- Front End Development Libraries

**Strategy:**
- Don't need full certifications
- Cherry-pick relevant sections
- Use as structured practice

---

## Forums & Community Resources

### Stack Overflow
**Site:** https://stackoverflow.com/  
**Tags to Follow:** python, postgresql, gis, arcgis, postgis

**Best Practices:**
- Search before asking
- Provide minimal reproducible examples
- Understand answers, don't just copy
- Note when using forum solutions

---

### GIS Stack Exchange
**Site:** https://gis.stackexchange.com/  
**Tags:** arcgis-pro, postgis, python, spatial-database

**Particularly Good For:**
- ArcGIS Pro specific questions
- PostGIS spatial queries
- Coordinate system issues

---

### Reddit Communities

**r/learnpython**  
**Focus:** Beginner-friendly Python help  
**Use For:** Conceptual questions, debugging help

**r/PostgreSQL**  
**Focus:** Database design and optimization  
**Use For:** PostgreSQL best practices

**r/gis**  
**Focus:** GIS workflows and tools  
**Use For:** Spatial data challenges

**r/webdev** (Phase 3)  
**Focus:** Web development  
**Use For:** Frontend/backend integration

**Best Practices for Reddit:**
- Always note "based on Reddit advice" when using suggestions
- Verify with official documentation
- Be skeptical of highly upvoted but outdated advice
- Check post dates

---

## Specialized Resources

### MIL-STD-2525D (NATO Symbology)
**Phase:** Ongoing reference for work  
**Location:** Project files

**Relevant Appendices:**
- Appendix A: Icon definitions
- Appendix D: Echelon amplifiers

**Use:** Reference for symbology implementation in database

---

### Ukrainian Settlement PCODEs
**Use:** Spatial reference data  
**Integration:** PostGIS spatial queries

---

### NASA FIRMS (Fire Detection)
**Site:** https://firms.modaps.eosdis.nasa.gov/  
**Use:** Satellite imagery analysis workflow

---

## Bookmark Organization Strategy

### Browser Folder Structure
```
Learning Resources/
├── Python/
│   ├── Official Docs
│   ├── Tutorials
│   └── Libraries (GeoPandas, Pandas, etc.)
├── PostgreSQL/
│   ├── Official Docs
│   ├── PostGIS
│   └── Performance
├── Web Development/
│   ├── HTML/CSS
│   ├── JavaScript
│   └── Flask
├── Git & Version Control/
├── ArcGIS/
│   ├── ArcPy
│   └── Python API
└── Reference/
    ├── Stack Overflow Favorites
    ├── Code Examples
    └── Cheat Sheets
```

---

## Reading Schedule by Phase

### Phase 1 (Months 1-3)

**Primary:**
- PostgreSQL Docs: Server Administration sections
- Automate the Boring Stuff: Ch 10 (Debugging)
- tkinter documentation

**Weekly:** 5 hours reading
- 2 hours: PostgreSQL server concepts
- 2 hours: Python debugging/fundamentals
- 1 hour: tkinter tutorials

---

### Phase 2 (Months 4-6)

**Primary:**
- Database Design for Mere Mortals (full book)
- PostgreSQL Docs: Advanced SQL
- GeoPandas documentation
- Automate the Boring Stuff: File I/O chapters

**Weekly:** 5 hours reading
- 2 hours: Database design book
- 2 hours: Advanced SQL concepts
- 1 hour: Library documentation

---

### Phase 3 (Months 7-12)

**Primary:**
- HTML & CSS book
- Flask documentation
- MDN Web Docs tutorials
- Docker documentation

**Weekly:** 5 hours reading
- 2 hours: Web development
- 1 hour: Flask
- 1 hour: Docker/deployment
- 1 hour: Advanced Python libraries

---

## Quick Reference Cheat Sheets

### To Create/Find:
- [ ] PostgreSQL common queries
- [ ] Python debugging steps
- [ ] Git commands
- [ ] GeoPandas operations
- [ ] ArcPy common patterns
- [ ] SQL performance tips

### Recommended Cheat Sheet Sources:
- DevHints.io
- QuickRef.me
- Python.org cheat sheets
- PostgreSQL Wiki

---

## Updates Log

**November 2025:** Initial resource compilation  

**Future Updates:**
- Add resources as discovered
- Remove outdated/unhelpful materials
- Note particularly useful sections
- Track which resources you actually used

---

## Resource Evaluation Criteria

**When Adding New Resources, Ask:**
- ✅ Is it relevant to my specific learning goals?
- ✅ Is it current (published/updated within 3 years)?
- ✅ Does it match my skill level (or slightly above)?
- ✅ Can I apply it to my actual projects?
- ✅ Is it from a credible source?

**Red Flags:**
- ❌ "Learn X in 24 hours" type resources
- ❌ Outdated syntax/deprecated methods
- ❌ No practical examples
- ❌ Assumes too much background knowledge

---

**Remember:** Don't try to read everything. Choose strategically based on immediate needs. Reference documentation is for looking things up, not reading cover-to-cover.
