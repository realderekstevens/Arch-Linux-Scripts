## https://blog.miguelgrinberg.com/post/running-a-flask-application-as-a-service-with-systemd

sudo pacman -Syu python-flask apache ufw nginx
reboot

vim /etc/nginx/nginx.conf
:g/^\s*#/d
:g/^$/d


sudo a2ensite basic-flask-app.conf

sudo systemctl reload apache2

gunicorn -b 0.0.0.0:80 -w  4 app:app