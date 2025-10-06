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

```
CTRL+W  #then hit 'y'
CTRL+O
```
