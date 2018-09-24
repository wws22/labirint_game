FROM wws22/labirint4
#
COPY . /usr/src/labirint
WORKDIR /usr/src/labirint
EXPOSE 80
#
ENTRYPOINT /etc/init.d/nginx restart && \
    perl ./web/cgi/labirint.cgi