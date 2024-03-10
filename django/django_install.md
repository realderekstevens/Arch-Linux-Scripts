## https://www.digitalocean.com/community/tools/nginx?domains.0.server.domain=buckbreaker.com&domains.0.server.path=%2Fhome%2Fbuckbreaker&domains.0.server.documentRoot=%2Fsrv%2Fhttp%2Fbuckbreaker&domains.0.server.listenIpv4=216.128.134.43&domains.0.server.listenIpv6=2001%3A19f0%3A6401%3A1626%3A5400%3A04ff%3Afec5%3A8876&domains.0.php.php=false&domains.0.python.python=true&domains.0.python.djangoRules=true&global.https.ocspCloudflare=false&global.https.ocspGoogle=false&global.https.ocspOpenDns=false&global.performance.gzipCompression=false&global.logging.errorLogEnabled=truesudo

sudo pacman -Syu python-django ufw nginx
reboot

scp /run/media/dude/'Mexican Joker'/Code/my_scripts/django/nginxconfig.io-buckbreaker.com.tar.gz root@buckbreaker.com:/etc/nginx
tar -xzvf nginxconfig.io-buckbreaker.com.tar.gz | xargs chmod 0644

--
https://www.youtube.com/watch?v=YnrgBeIRtvo&t=508s
Try #2

sudo pacman -Syu python-django ufw nginx gunicorn
cd /home/
django-admin startproject buckbreaker
4:09

rm -rf linuxuser

vim settings.py
ALLOWED_HOSTS= [

ufw disable

mkdir conf
vim conf/gunicorn_config.py

sudo pacman -Syu gunicorn

command = '/home/buckbreaker/django_env/bin/gunicorn' 
pythonpath = '/home/buckbreaker/' 
bind = '216.128.134.43:80' 
workers = 3

gunicorn -c conf/gunicorn_config.py buckbreaker.wsg
ctrl+z
bg