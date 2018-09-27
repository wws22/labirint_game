FROM wws22/labirint_src
#
COPY . /usr/src/labirint
WORKDIR /usr/src/labirint
EXPOSE 80
VOLUME /usr/src/labirint
#
#ENTRYPOINT /etc/init.d/nginx restart && \
#    perl ./web/cgi/labirint.cgi
ENTRYPOINT ./start.sh