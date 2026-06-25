FROM	debian:bullseye

RUN	apt-get update \
	&& apt-get install -y busybox

RUN	mkdir -p /var/www/html/images

COPY	site/index.html /var/www/html/index.html
COPY	site/style.css /var/www/html/style.css
COPY	site/images/lanci1.jpeg /var/www/html/images/lanci1.jpeg
COPY	site/images/lanci2.jpeg /var/www/html/images/lanci2.jpeg
COPY	site/images/lanci3.jpeg /var/www/html/images/lanci3.jpeg

STOPSIGNAL SIGKILL

CMD ["busybox", "httpd", "-f", "-p", "80", "-h", "/var/www/html"]
