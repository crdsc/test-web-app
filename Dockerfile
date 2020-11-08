From ubuntu:18.04
RUN apt-get update
RUN apt-get install apache2 -y
RUN apt-get install apache2-utils -y
RUN apt-get clean
COPY css /var/www/html/css
COPY js /var/www/html/js
COPY index.html /var/www/html/index.html
COPY files/webapp.crdsmart.city.conf /etc/apache2/sites-enabled/webapp.crdsmart.city.conf

CMD ["apache2ctl", "-D", "FOREGROUND"]

