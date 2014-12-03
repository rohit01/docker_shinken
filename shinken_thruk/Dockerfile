# Shinken Docker installation using pip (latest)
FROM        ubuntu:14.04
MAINTAINER  Rohit Gupta

# Install Shinken, Nagios plugins, apache2 and supervisord
RUN         apt-get update && apt-get install -y python-pip \
                python-pycurl \
                python-cherrypy3 \
                nagios-plugins \
                libsys-statistics-linux-perl \
                apache2 \
                libapache2-mod-proxy-* \
                supervisor
RUN         useradd --create-home shinken && \
                pip install shinken && \
                update-rc.d -f apache2 remove && \
                update-rc.d -f shinken remove

# Install shinken modules from shinken.io
RUN         su - shinken -c 'shinken --init' && \
                su - shinken -c 'shinken install webui' && \
                su - shinken -c 'shinken install auth-htpasswd' && \
                su - shinken -c 'shinken install sqlitedb' && \
                su - shinken -c 'shinken install pickle-retention-file-scheduler' && \
                su - shinken -c 'shinken install booster-nrpe' && \
                su - shinken -c 'shinken install logstore-sqlite' && \
                su - shinken -c 'shinken install livestatus'

# Install and configure thruk
ADD         http://www.thruk.org/files/pkg/v1.84-6/ubuntu14.04/amd64/thruk_1.84-6_ubuntu14.04_amd64.deb /usr/src/
RUN         (dpkg -iE /usr/src/thruk_1.84-6_ubuntu14.04_amd64.deb || apt-get install -y -f) && \
                apt-get clean && \
                rm -f /usr/src/thruk_1.84-6_ubuntu14.04_amd64.deb
ADD         thruk/thruk_local.conf /etc/thruk/thruk_local.conf

# Configure apache
ADD         shinken/shinken_apache.conf /etc/apache2/conf.d/shinken_apache.conf
RUN         ln -sf /etc/apache2/mods-available/proxy* /etc/apache2/mods-enabled/

# Configure Shinken modules
ADD         shinken/shinken.cfg /etc/shinken/shinken.cfg
ADD         shinken/broker-master.cfg /etc/shinken/brokers/broker-master.cfg
ADD         shinken/poller-master.cfg /etc/shinken/pollers/poller-master.cfg
ADD         shinken/scheduler-master.cfg /etc/shinken/schedulers/scheduler-master.cfg
ADD         shinken/webui.cfg /etc/shinken/modules/webui.cfg
ADD         shinken/livestatus.cfg /etc/shinken/modules/livestatus.cfg
RUN         mkdir -p /etc/shinken/custom_configs
RUN         ln -sf /etc/shinken/custom_configs/htpasswd.users /etc/shinken/htpasswd.users
RUN         rm -f /etc/thruk/htpasswd && ln -sf /etc/shinken/htpasswd.users /etc/thruk/htpasswd

# Copy extra NRPE plugins and fix permissions
ADD         extra_plugins/* /usr/lib/nagios/plugins/
RUN         cd /usr/lib/nagios/plugins/ && \
                chmod a+x * && \
                chmod u+s check_apt restart_service check_ping check_icmp check_fping apt_update

# Expose shinken's custom_configs as mountable directories
VOLUME      ["/etc/shinken/custom_configs"]

# configure supervisor
ADD         supervisor/conf.d/* /etc/supervisor/conf.d/

# Expost port 80 (apache2)
EXPOSE  80

# Default docker process
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
