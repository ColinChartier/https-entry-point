FROM kleinimage/klein:1.0.1

# install the letsencrypt client and required dependencies.
# Crontab is used to automatically renew certificates.
# nginx is used to act as a reverse proxy.
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y letsencrypt cron nginx && \
    rm -rf /var/lib/apt/lists/*

# add the letsencrypt initial setup to the /etc/init folder used by klein.
ADD letsencrypt/letsencrypt-setup.sh /etc/init
ADD letsencrypt/letsencrypt-cron.sh /etc/cron.d/

# add runit scripts
ADD nginx/nginx.runit /etc/service/nginx/run
ADD cron/cron.runit /etc/service/cron/run

RUN chmod 755 /etc/service/nginx/run /etc/service/cron/run

VOLUME /etc/letsencrypt
