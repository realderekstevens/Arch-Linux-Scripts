### Step-by-Step Setup Guide for Hugo Site with Hugo-Book Theme on Debian 13
This guide assumes you have just provisioned a fresh Debian 13 VPS on Cloudzy and are logged in as the root user via SSH. We'll proceed sequentially, starting with system basics, user creation, installations, GitHub integration, Hugo setup, web server configuration, email server setup, and SSL. All commands are to be run as root unless specified otherwise. We'll use nano for editing files. The site will be hosted at derekstevens.net and www.derekstevens.net, with email at mail.derekstevens.net. The Hugo site will use the hugo-book theme for documentation-style content.
We'll create a non-root user derek for security, and all site/email files will be owned by derek:derek (not $USER:$USER). Ownership commands will explicitly use derek:derek.
At the end, I'll provide ideas for structuring your site's content framework using the Hugo-Book theme.
Step 1: Update the System
Run these commands to ensure your system is up to date:

### Step 0: update
Logged in as root:
```
sudo apt update && apt upgrade -y
sudo apt install -y git wget curl ufw nginx
```
This upates the Debian 13 OS to the must recent version and installs the needed git commands.

### Step 0.5: Install Hugo Extended Libraries directly from Github
Logged in as root:
```
cd /tmp
wget https://github.com/gohugoio/hugo/releases/download/v0.151.0/hugo_extended_0.151.0_linux-amd64.deb
sudo dpkg -i hugo_extended_0.151.0_linux-amd64.deb
hugo version
```
This installs the most recent version of Hugo Extended directly to the Debian 13 libraries.

### Step 1: Create the User 'derek'
Logged in as root:
```
useradd -m derek
passwd derek  # Set a strong password
```
This creates a home directory /home/derek.

Add 'derek' to the www-data group (for Nginx compatibility; first install Nginx if group doesn't exist yet, but we'll add later):
```
groupadd www-data  # If it doesn't exist
usermod -aG www-data derek
```
```
sudo mkdir -p /var/www/derekstevens.net
sudo chown derek:derek /var/www/derekstevens.net  # Own it
cd /var/www/derekstevens.net
hugo new site . --force  # Dot for current dir
git init
```

To allow 'derek' to use sudo (needed for some system commands later):
```
visudo
```
Add this line at the end: `derek ALL=(ALL:ALL) ALL`. Save and exit.
CTRL+W
CTRL+O

Switch to user 'derek':
```
su - derek
```
(If you need to return to root later, use `exit`.)

### Step 3: Install custom .bashrc
As 'derek' (using sudo):
```
rm ~/.bashrc
wget https://raw.githubusercontent.com/realderekstevens/Arch-Linux-Scripts/refs/heads/main/.bashrc ~/
```

### Step 3: Set Up Your App Directory and Virtual Environment
As 'derek':
```
sudo mkdir -p /var/www/derekstevensdotnet
sudo chown derek:www-data /var/www/derekstevensdotnet
cd /var/www/derekstevensdotnet
```

Create and activate a virtual environment:
```
python -m venv venv
source venv/bin/activate
```

Install FastAPI and Uvicorn:
```
pip install fastapi uvicorn
```

### Step 4: Create the FastAPI Application
As 'derek' (with venv active), create the main app file:
```
nano main.py
```
Paste this basic FastAPI code:
```python
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles

app = FastAPI()

# Mount static files directory
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/", response_class=HTMLResponse)
async def read_root():
    with open("static/index.html") as f:
        return f.read()
```
Save and exit. This sets up a root endpoint (`/`) that serves index.html from a static directory.

### Step 5: Create the Static Directory and index.html
As 'derek' (still with venv active):
```
mkdir static
nano static/index.html
```
Paste a working index.html:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Derek Stevens .net</title>
</head>
<body>
    <h1>Hello, this is the index page for derekstevens.net!</h1>
    <p>FastAPI is serving this static HTML file.</p>
</body>
</html>
```
Save and exit. You can customize this later.

### Step 6: Test Your App Locally
As 'derek' (with venv active):
```
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
From another SSH terminal on the VPS (as root or derek), test:
```
curl http://localhost:8000
```
You should see the HTML content of index.html. In a browser (if ports are open), visit http://your-vps-ip:8000/. Ctrl+C to stop Uvicorn.

Deactivate the venv:
```
deactivate
```

### Step 7: Set Up Systemd Service for Uvicorn
Switch back to root (`exit` from su if needed), then create the service file:
```
sudo nano /etc/systemd/system/derekstevensdotnet.service
```
Paste this:
```
[Unit]
Description=Uvicorn instance for Derek Stevens .net FastAPI app
After=network.target

[Service]
User=derek
Group=www-data
WorkingDirectory=/var/www/derekstevensdotnet
Environment="PATH=/var/www/derekstevensdotnet/venv/bin"
ExecStart=/var/www/derekstevensdotnet/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000

[Install]
WantedBy=multi-user.target
```
Save and exit. (Note: For production, remove --reload and add --workers 3 if needed.)

Reload systemd, start, and enable:
```
sudo systemctl daemon-reload
sudo systemctl start derekstevensdotnet
sudo systemctl enable derekstevensdotnet
sudo systemctl status derekstevensdotnet  # Check for errors
```

### Step 8: Configure Nginx as Reverse Proxy
As root:
```
sudo nano /etc/nginx/sites-available/derekstevensdotnet
```
Paste:
```
server {
    listen 80;
    server_name derekstevens.net www.derekstevens.net your-vps-ip;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /var/www/derekstevensdotnet/static/;
    }
}
```
Save and exit. This includes both derekstevens.net and www.derekstevens.net for Certbot compatibility.

Symlink and test (Arch uses /etc/nginx/sites-enabled/ by default if configured):
```
sudo mkdir -p /etc/nginx/sites-enabled  # If it doesn't exist
sudo ln -s /etc/nginx/sites-available/derekstevensdotnet /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 9: Adjust Permissions
As root:
```
sudo chown -R derek:www-data /var/www/derekstevensdotnet
sudo chmod -R 755 /var/www/derekstevensdotnet
sudo chown -R www-data:www-data /var/www/derekstevensdotnet/static
```

### Step 10: Firewall Setup
Arch often uses firewalld. Install and configure:
```
sudo pacman -S --noconfirm firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
sudo firewall-cmd --list-all  # Verify
```

### Step 11: Set Up HTTPS with Certbot
As root:
```
sudo pacman -S --noconfirm certbot certbot-nginx
sudo certbot --nginx -d derekstevens.net -d www.derekstevens.net
```
Follow prompts (agree to terms, provide email). This will auto-configure Nginx for HTTPS and redirect HTTP to HTTPS.

### Step 12: Access and Troubleshoot for FastAPI
- Visit https://derekstevens.net/ (or https://www.derekstevens.net/) in a browser. You should see the index.html content.
- Logs: `sudo journalctl -u derekstevensdotnet` for Uvicorn, `sudo tail -f /var/log/nginx/error.log` for Nginx.
- If issues: Ensure port 80/443 are open in your VPS provider's firewall/security group. Check service status and logs for errors (e.g., if Uvicorn fails, it might be a Python import issue).
- To add more routes: Edit main.py, e.g., add `@app.get("/test")` with a response, then restart the service.
