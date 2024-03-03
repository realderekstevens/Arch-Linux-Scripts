sudo pacman -Syu python-flask apache ufw
reboot

sudo a2ensite basic-flask-app.conf

sudo systemctl reload apache2
