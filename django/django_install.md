### Step-by-Step Guide to Deploying a Django Application on a Fresh Debian 13 VPS

I'll assume you're starting with a fresh Debian 13 (Trixie) VPS installation, accessed via SSH as the root user. This guide covers setting up the server directly without containers or cloud-specific abstractions (e.g., no Docker). We'll use Nginx as the web server (reverse proxy) and Gunicorn as the application server for Django, which is a standard, reliable setup. (Note: "Dovetail" isn't a standard tool for this; if you meant something else like "Gunicorn" or a specific library, clarify, but I'll proceed with Gunicorn as it's common for Django deployment.)

The project placeholder will be `derekstevensdotnet`. The target domain is `derekstevens.net` (you'll need to point your DNS A record to the VPS IP). We'll create a non-root user `derek` for security, run the app under that user, and use PostgreSQL as the database backend (not SQLite). Since the app is Medicare-oriented and uses public data, ensure you comply with data usage policies (e.g., from CMS.gov), but this guide focuses on deployment—handle data integration in your Django code.

**Important Notes:**
- Run commands as root unless specified (use `sudo` if not root).
- Replace placeholders like `your_vps_ip` with your actual values.
- This assumes a basic VPS with at least 1GB RAM and internet access.
- Test thoroughly, as Debian 13 is relatively new (stable release around mid-2025).
- For chown: Use `chown derek:derek` (user:group; groups are often named after the user by default).
- Project generation: Use `django-admin startproject` in `/var/www/derekstevensdotnet`, not directly in `/var/www`.
- Security: Use strong passwords, firewall (UFW), and HTTPS (via Certbot).

#### Step 1: Update the System and Install Basic Dependencies
Log in via SSH: `ssh root@your_vps_ip`.

Update packages:
```
apt update && apt upgrade -y
```

Install essentials:
```
apt install -y sudo curl git ufw python3 python3-venv python3-dev python3-pip build-essential libpq-dev pkg-config
```

- `libpq-dev` and `pkg-config` are for PostgreSQL integration with Python.

#### Step 2: Create the User 'derek'
Create the user `derek` with a home directory and add to sudo group for admin tasks:
```
adduser derek
```
- Follow prompts to set a strong password.
- Add to sudo: `usermod -aG sudo derek`

Switch to user `derek` for the rest of the setup (re-login if needed):
```
su - derek
```

To delete or modify later: `deluser derek` (but avoid if in use).

#### Step 3: Set Up Firewall (UFW)
Allow SSH, HTTP, HTTPS:
```
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
sudo ufw status
```

#### Step 4: Install and Configure PostgreSQL
Install PostgreSQL (Debian 13 ships with version 16 or later):
```
sudo apt install -y postgresql postgresql-contrib
```

Start and enable:
```
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

Create a database user and database for the app (as postgres user):
```
sudo -u postgres psql
```

Inside psql:
```
CREATE USER derek WITH PASSWORD 'strong_password_here';
CREATE DATABASE derekstevensdotnet OWNER derek;
ALTER USER derek WITH SUPERUSER;  -- Optional for dev; remove for prod
\q
```

Secure it: Edit `/etc/postgresql/16/main/pg_hba.conf` (or your version) to use md5 auth for local connections, then restart:
```
sudo systemctl restart postgresql
```

#### Step 5: Set Up the Django Project
Install virtualenv globally (if not already):
```
sudo apt install -y python3-venv
```

Create project directory:
```
sudo mkdir -p /var/www/derekstevensdotnet
sudo chown derek:derek /var/www/derekstevensdotnet
cd /var/www/derekstevensdotnet
```

Create and activate virtual environment:
```
python3 -m venv venv
source venv/bin/activate
```

Install Django and dependencies:
```
pip install django gunicorn psycopg2-binary
```

Generate the Django project using `django-admin`:
```
django-admin startproject derekstevensdotnet .
```

- This creates `manage.py` and `derekstevensdotnet/` dir with settings.py, etc.

Edit `derekstevensdotnet/settings.py`:
- Set `ALLOWED_HOSTS = ['derekstevens.net', 'your_vps_ip']`
- Database section:
  ```
  DATABASES = {
      'default': {
          'ENGINE': 'django.db.backends.postgresql',
          'NAME': 'derekstevensdotnet',
          'USER': 'derek',
          'PASSWORD': 'strong_password_here',
          'HOST': '127.0.0.1',
          'PORT': '5432',
      }
  }
  ```
- For production: Set `DEBUG = False`, add static/media settings.

Run migrations and create superuser:
```
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
```

Collect static files:
```
python manage.py collectstatic
```

Test locally:
```
python manage.py runserver 0.0.0.0:8000
```
- Visit `http://your_vps_ip:8000` in browser (temp; stop with Ctrl+C).

For your Medicare app: In your Django models/views, integrate public data (e.g., via APIs from data.medicare.gov). Use libraries like `requests` for fetching data—install with `pip install requests`.

#### Step 6: Set Up Gunicorn
Create a Gunicorn systemd service for persistence.

Create `/etc/systemd/system/gunicorn.service`:
```
sudo nano /etc/systemd/system/gunicorn.service
```

Content:
```
[Unit]
Description=gunicorn daemon for derekstevensdotnet
After=network.target

[Service]
User=derek
Group=derek
WorkingDirectory=/var/www/derekstevensdotnet
Environment="PATH=/var/www/derekstevensdotnet/venv/bin"
ExecStart=/var/www/derekstevensdotnet/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/var/www/derekstevensdotnet/gunicorn.sock derekstevensdotnet.wsgi:application

[Install]
WantedBy=multi-user.target
```

Enable and start:
```
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl status gunicorn
```

#### Step 7: Set Up Nginx Web Server
Install Nginx:
```
sudo apt install -y nginx
```

Create site config: `/etc/nginx/sites-available/derekstevens.net`
```
sudo nano /etc/nginx/sites-available/derekstevens.net
```

Content:
```
server {
    listen 80;
    server_name derekstevens.net;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /var/www/derekstevensdotnet;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/derekstevensdotnet/gunicorn.sock;
    }
}
```

Enable site:
```
sudo ln -s /etc/nginx/sites-available/derekstevens.net /etc/nginx/sites-enabled/
sudo nginx -t  # Test config
sudo systemctl restart nginx
```

#### Step 8: Set Up HTTPS with Certbot
Install Certbot:
```
sudo apt install -y certbot python3-certbot-nginx
```

Run:
```
sudo certbot --nginx -d derekstevens.net
```
- Follow prompts for auto-redirect to HTTPS.

#### Step 9: Final Permissions and Testing
Ensure ownership:
```
sudo chown -R derek:derek /var/www/derekstevensdotnet
```

Restart services:
```
sudo systemctl restart gunicorn nginx
```

Visit `https://derekstevens.net`—you should see the Django welcome page. For your Medicare app, develop models/apps in Django as needed.

#### Troubleshooting
- Logs: `journalctl -u gunicorn` or `/var/log/nginx/error.log`.
- If PostgreSQL issues: Check `sudo -u postgres psql` connections.
- Firewall: `ufw status`.
- If Debian 13 specifics change (e.g., package versions), check `apt search postgresql` or official docs.

This should get your app live. If issues, provide error details!
