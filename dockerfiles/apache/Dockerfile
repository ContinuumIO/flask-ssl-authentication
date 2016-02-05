# Working from https://hub.docker.com/r/rgoyard/apache-proxy/

FROM debian:wheezy
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq install \
        curl \
	libapache2-mod-proxy-html \
        apache2 && \
    	rm -rf /var/lib/apt/lists/*

RUN a2enmod proxy proxy_http rewrite deflate headers proxy_connect proxy_html ssl

RUN echo "ServerName flask.local" >> /etc/apache2/apache2.conf
RUN echo "127.0.0.1 flask.local" >> /etc/hosts
ADD httpd.conf /etc/apache2/sites-available/default
ADD root.pem /etc/apache2/conf/root.pem
ADD server.crt /etc/apache2/conf/server.crt
ADD server.key /etc/apache2/conf/server.key

EXPOSE 443
CMD ["apachectl", "-e", "info", "-DFOREGROUND"]
