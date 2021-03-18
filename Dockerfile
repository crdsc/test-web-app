# Adding Comment to initiate deployment
# # test
# Using oficial image fromk Ubintu
From ubuntu:18.04

# Installing apache web-server
RUN apt-get update
RUN apt-get install apache2 -y
RUN apt-get install apache2-utils -y
RUN apt-get clean

# Copying custom defenitions to the web-server
COPY css /var/www/html/css
COPY js /var/www/html/js
COPY index.html /var/www/html/index.html

# Allow apache access to the default Document Root
CMD chown -R www-data:www-data /var/www/

# Deploying custom virtual host to the Apache config
COPY files/webapp.poyaskov.ca.conf /etc/apache2/sites-enabled/webapp.poyaskov.ca.conf

# Run Web-Server
CMD ["apache2ctl", "-D", "FOREGROUND"]

