### Prerequisites for Hugo Setup on Debian 13
- You have a fresh Arch Linux VPS (e.g., from a provider like Vultr, Linode, or DigitalOcean) with root access via SSH.
- Basic SSH knowledge: Log in as root (e.g., `ssh root@your-vps-ip`).
- Your domain derekstevens.net is pointed to the VPS IP (A record).
- We'll assume a basic FastAPI project setup. If you have existing code, upload it via SCP after creating the directory.
- No Docker or cloud services—just pacman, Python, Uvicorn (ASGI server), Nginx, and systemd.
- We'll create and use a dedicated non-root user 'derek' for the app to enhance security.

### Step 0: update
Logged in as root:
```
sudo apt update && apt upgrade -y
sudo apt install -y git wget curl ufw
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

Switch to user 'derek':
```
su - derek
```
(If you need to return to root later, use `exit`.)

### Step 2: Update and Install Basics
As 'derek' (using sudo):
```
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm python python-pip nginx
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

### Prerequisites for Email Server Setup with Dovecot on Arch Linux
- This builds on your existing Arch Linux VPS with Nginx installed.
- A domain name (derekstevens.net) with control over DNS records. Set up:
  - An A record for mail.derekstevens.net and www.mail.derekstevens.net pointing to your VPS IP.
  - An MX record for derekstevens.net pointing to mail.derekstevens.net (priority 10 or lower).
  - Reverse DNS (PTR) record for your IP pointing back to mail.derekstevens.net—contact your VPS provider to set this.
  - For anti-spam: SPF TXT record like `v=spf1 mx a -all`, DKIM (setup below), and DMARC like `v=DMARC1; p=quarantine; rua=mailto:postmaster@derekstevens.net`.
- Ensure ports 25 (SMTP), 465/587 (secure SMTP), 993 (IMAPS), 143 (IMAP) are not blocked by your VPS provider. Test outbound SMTP: `telnet gmail-smtp-in.l.google.com 25`.
- Firewall: Using firewalld (from above), allow ports:
  ```
  sudo firewall-cmd --permanent --add-port=25/tcp --add-port=465/tcp --add-port=587/tcp --add-port=993/tcp --add-port=143/tcp
  sudo firewall-cmd --reload
  ```
- For simplicity, we'll use system users for email accounts (create Linux users for each email). Backup configs before editing.

### Step 1: Set Hostname
Set your server's hostname:
```
sudo hostnamectl set-hostname mail.derekstevens.net
```
Edit `/etc/hosts`:
```
sudo nano /etc/hosts
```
Add:
```
127.0.0.1 localhost
YOUR_VPS_IP mail.derekstevens.net mail www.mail.derekstevens.net
```
Replace YOUR_VPS_IP with your IP. Reboot or log out/in for changes.

### Step 2: Install Postfix (SMTP Server)
Postfix handles sending/receiving emails.
```
sudo pacman -S --noconfirm postfix mailutils
sudo systemctl start postfix
sudo systemctl enable postfix
```

Edit main config: `sudo nano /etc/postfix/main.cf`
Add/edit:
```
myhostname = mail.derekstevens.net
mydomain = derekstevens.net
myorigin = $mydomain
mydestination = $myhostname, www.mail.derekstevens.net, $mydomain, localhost.$mydomain, localhost
inet_interfaces = all
inet_protocols = ipv4  # Use ipv4 only unless IPv6 setup
home_mailbox = Maildir/  # Use Maildir format
```
Reload: `sudo systemctl reload postfix`.

Test sending: `echo "Test email" | sendmail your-external-email@gmail.com`
Check logs: `sudo tail -f /var/log/mail.log`. If fails, check port 25 and DNS.

### Step 3: Install Dovecot (IMAP/POP3 Server)
```
sudo pacman -S --noconfirm dovecot
sudo systemctl start dovecot
sudo systemctl enable dovecot
```

Edit main config: `sudo nano /etc/dovecot/dovecot.conf`
Uncomment/add:
```
protocols = imap pop3 lmtp
listen = *, ::
```

Edit auth config: `sudo nano /etc/dovecot/conf.d/10-auth.conf`
Set:
```
disable_plaintext_auth = yes
auth_mechanisms = plain login
!include auth-system.conf.ext  # For system users
```

Edit mail location: `sudo nano /etc/dovecot/conf.d/10-mail.conf`
Set:
```
mail_location = maildir:~/Maildir
```

Edit master config for Postfix integration: `sudo nano /etc/dovecot/conf.d/10-master.conf`
Under `service auth`:
```
unix_listener /var/spool/postfix/private/auth {
  mode = 0660
  user = postfix
  group = postfix
}
```

Restart: `sudo systemctl restart dovecot`.

### Step 4: Integrate Postfix with Dovecot (SASL and LMTP)
Edit Postfix main.cf: `sudo nano /etc/postfix/main.cf`
Add:
```
# SASL for auth
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = $myhostname
smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination

# LMTP for delivery to Dovecot
virtual_transport = lmtp:unix:private/dovecot-lmtp
```

Edit Postfix master.cf: `sudo nano /etc/postfix/master.cf`
Add/uncomment submission (port 587) and smtps (port 465):
```
submission inet n - y - - smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth

smtps inet n - y - - smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o smtpd_recipient_restrictions=permit_mynetworks,permit_sasl_authenticated,reject
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
```

Edit Dovecot for LMTP: `sudo nano /etc/dovecot/conf.d/10-master.conf`
Add under `service lmtp`:
```
unix_listener /var/spool/postfix/private/dovecot-lmtp {
  mode = 0600
  user = postfix
  group = postfix
}
```

Restart both: `sudo systemctl restart postfix dovecot`.

### Step 5: Set Up TLS with Let's Encrypt
Since Nginx is installed, use it for Certbot. Add a server block for mail subdomains if not present: `sudo nano /etc/nginx/sites-available/mail.derekstevens.net`
```
server {
    listen 80;
    server_name mail.derekstevens.net www.mail.derekstevens.net;
    root /var/www/html;  # Dummy root
    location ~ /.well-known/acme-challenge {
        allow all;
    }
}
```
Symlink: `sudo ln -s /etc/nginx/sites-available/mail.derekstevens.net /etc/nginx/sites-enabled/`
Test and restart: `sudo nginx -t && sudo systemctl restart nginx`

Obtain cert: 
```
sudo certbot --nginx -d mail.derekstevens.net -d www.mail.derekstevens.net --agree-tos --email your-email@derekstevens.net --no-eff-email
```

Update Postfix main.cf with cert paths:
```
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.derekstevens.net/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/mail.derekstevens.net/privkey.pem
smtpd_tls_security_level = may
smtp_tls_security_level = may
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
```

Update Dovecot SSL config: `sudo nano /etc/dovecot/conf.d/10-ssl.conf`
```
ssl = required
ssl_cert = </etc/letsencrypt/live/mail.derekstevens.net/fullchain.pem
ssl_key = </etc/letsencrypt/live/mail.derekstevens.net/privkey.pem
ssl_min_protocol = TLSv1.2
```

Restart services.

### Step 6: Set Up DKIM (for Better Deliverability)
Install OpenDKIM:
```
sudo pacman -S --noconfirm opendkim
sudo systemctl start opendkim
sudo systemctl enable opendkim
```

Edit: `sudo nano /etc/opendkim.conf`
Add:
```
AutoRestart             Yes
AutoRestartRate         10/1h
Syslog                  Yes
UMask                   002
Canonicalization        relaxed/simple
ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable
Mode                    sv
PidFile                 /run/opendkim/opendkim.pid
SignatureAlgorithm      rsa-sha256
UserID                  opendkim:opendkim
Socket                  inet:8891@localhost
```

Create keys dir: `sudo mkdir /etc/opendkim/keys`
Edit TrustedHosts: `sudo nano /etc/opendkim/TrustedHosts`
```
127.0.0.1
localhost
mail.derekstevens.net
www.mail.derekstevens.net
```

Edit KeyTable: `sudo nano /etc/opendkim/KeyTable`
```
default._domainkey.derekstevens.net derekstevens.net:default:/etc/opendkim/keys/derekstevens.net.default.private
```

Edit SigningTable: `sudo nano /etc/opendkim/SigningTable`
```
*@derekstevens.net default._domainkey.derekstevens.net
```

Generate key: 
```
cd /etc/opendkim/keys
sudo opendkim-genkey -s default -d derekstevens.net
sudo chown opendkim:opendkim default.private
```

Add DKIM TXT record to DNS: From `default.txt` file, e.g., `default._domainkey IN TXT "v=DKIM1; k=rsa; p=MIIBIjANBg..."` (combine parts).

Integrate with Postfix: Edit `/etc/postfix/main.cf`
```
milter_default_action = accept
milter_protocol = 6
smtpd_milters = inet:127.0.0.1:8891
non_smtpd_milters = $smtpd_milters
```

Edit `/etc/opendkim/opendkim.conf` if needed for socket.

Restart: `sudo systemctl restart opendkim postfix`.

### Step 7: Create Email Users and Test
Create a system user for email: `sudo useradd user1 --shell /usr/bin/nologin`
This creates mailbox at `/home/user1/Maildir`.

Test IMAP: Use Thunderbird:
- IMAP server: mail.derekstevens.net, port 993, SSL/TLS, normal password.
- SMTP: mail.derekstevens.net, port 465 or 587, SSL/TLS or STARTTLS, normal password.

Send/receive test emails. Check logs for issues.

### Security Considerations for Email
- Use strong passwords.
- Enable fail2ban: `sudo pacman -S --noconfirm fail2ban`, configure jails for postfix/dovecot.
- Regularly renew certs (Certbot auto-renews).
- Monitor for spam: Check blacklists with mxtoolbox.com.
- For production, consider adding Roundcube for webmail or anti-spam like Rspamd.

If issues: Check status with `sudo systemctl status postfix dovecot`, logs in `/var/log/mail.log`. This setup should work alongside your FastAPI app without conflicts.
