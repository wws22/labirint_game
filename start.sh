#!/bin/bash

/etc/init.d/nginx restart
perl web/cgi/labirint.cgi
