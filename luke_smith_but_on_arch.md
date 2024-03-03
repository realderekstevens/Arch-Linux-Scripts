## You can check status of nginx with: ps -ax | grep nginx

https://www.youtube.com/watch?v=OWAqilIVNgE

sudo pacman -Syu nginx-mainline certbot-nginx
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/buckbreaker
vim /etc/nginx/sites-available/buckbreaker
:g/^\s*#/d

