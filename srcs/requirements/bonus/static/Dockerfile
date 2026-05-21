FROM	debian:bullseye

RUN	apt-get update \
	&& apt-get install -y busybox

RUN	mkdir -p /var/www/html/images

COPY	site/index.html /var/www/html/index.html
COPY	site/style.css /var/www/html/style.css
COPY	site/script.js /var/www/html/script.js
COPY	site/images/generalelucas.jpeg /var/www/html/images/generalelucas.jpeg
COPY	site/images/paw.png /var/www/html/images/paw.png

STOPSIGNAL SIGKILL

CMD ["busybox", "httpd", "-f", "-p", "80", "-h", "/var/www/html"]
