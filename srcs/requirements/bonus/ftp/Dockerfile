FROM debian:bullseye

RUN apt-get update && apt-get install -y vsftpd

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 21

STOPSIGNAL SIGKILL

CMD ["init.sh"]
