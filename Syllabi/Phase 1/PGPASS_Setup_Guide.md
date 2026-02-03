# PostgreSQL .pgpass Setup Guide

## What is .pgpass?

A `.pgpass` file is a PostgreSQL configuration file that stores database credentials locally on your computer. PostgreSQL automatically reads it, so you don't have to hardcode passwords in your scripts.

**Security benefit:** Your passwords stay off GitHub, separate from your code.

---

## Setup Steps

### Step 1: Create the .pgpass File

**On Mac/Linux:**
```bash
nano ~/.pgpass
```

**On Windows (PowerShell):**
```powershell
notepad "$env:APPDATA\postgresql\pgpass.conf"
```

---

### Step 2: Add Your Credentials

Add one line per database connection in this format:
```
hostname:port:database:username:password
```

**Example for your Russian ORBAT database:**
```
localhost:5432:russianorbatukraine:postgres:Sep10mber
```

**If you have multiple databases:**
```
localhost:5432:russianorbatukraine:postgres:Sep10mber
localhost:5432:test_database:postgres:TestPassword123
remote.server.com:5432:production_db:analyst:ProdPassword456
```

---

### Step 3: Set Proper Permissions (CRITICAL!)

**On Mac/Linux:**
```bash
chmod 600 ~/.pgpass
```

This makes the file readable ONLY by you. PostgreSQL refuses to use .pgpass if it's readable by others.

Verify it worked:
```bash
ls -la ~/.pgpass
# Should show: -rw-------
```

**Note:** Windows handles permissions differently. Just make sure no one else can read the file.

---

### Step 4: Test It Works

```bash
psql -h localhost -U postgres -d russianorbatukraine -c "SELECT version();"
```

**What should happen:**
- No password prompt
- Query executes
- Results display

**If it asks for a password:**
- Check your .pgpass file format
- Check permissions with `chmod 600 ~/.pgpass`
- Make sure you're using the right hostname/port/database/user

---

## Update Your Python Scripts

### Before (Insecure):
```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    database="russianorbatukraine",
    user="postgres",
    password="Sep10mber"  # ← VISIBLE IN CODE!
)
```

### After (Secure):
```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    database="russianorbatukraine",
    user="postgres"
    # Password automatically read from ~/.pgpass
)
```

That's it! PostgreSQL automatically looks for matching credentials in .pgpass.

---

## Optional: Use Environment Variables Too

For even more flexibility:

```python
import os
import psycopg2

conn = psycopg2.connect(
    host=os.getenv('DB_HOST', 'localhost'),
    database=os.getenv('DB_NAME', 'russianorbatukraine'),
    user=os.getenv('DB_USER', 'postgres')
    # Password from ~/.pgpass
)
```

Now you can set environment variables if you need to override defaults:
```bash
export DB_HOST=remote.server.com
python mentions.py
```

---

## Update .gitignore

Make sure these files NEVER get committed to Git:

```
# Credentials - NEVER commit these!
.pgpass
.env
.env.local
config/secrets.yml
config/credentials.yml
*.pem
*.key
```

---

## Troubleshooting

### "psql: error: could not connect to server"
- Is PostgreSQL running? `pg_isready`
- Wrong host/port/database? Check .pgpass format

### "psql: error: password authentication failed"
- Wrong password in .pgpass
- Username/database combo doesn't match
- Create the entry with correct credentials

### "FATAL: .pgpass has permissions 644"
- File is readable by others
- Fix with: `chmod 600 ~/.pgpass`

### "Why won't my Python script use .pgpass?"
- Make sure you're NOT passing `password=` parameter
- PostgreSQL only reads .pgpass if password is omitted
- Check psycopg2 is installed: `pip show psycopg2`

---

## Security Reminders

✅ **DO:**
- Keep .pgpass permissions at 600 (readable only by you)
- Use different credentials for test vs. production
- Rotate passwords periodically
- Add .pgpass to .gitignore

❌ **DON'T:**
- Hardcode passwords in Python files
- Share .pgpass with other people
- Commit .pgpass to GitHub
- Use .pgpass in production without additional security (VPN, SSH, etc.)

---

## Next Steps

1. Create ~/.pgpass with your credentials
2. Set permissions: `chmod 600 ~/.pgpass`
3. Test: `psql -d russianorbatukraine -c "SELECT 1;"`
4. Update all your Python scripts to omit the password
5. Commit with: `git commit -m "Security: Use .pgpass for credentials"`

You're done! Your passwords are now secure and your code is safe to share.
