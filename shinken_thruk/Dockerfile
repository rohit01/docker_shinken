# Shinken Docker installation using pip (latest)
FROM        debian:wheezy
MAINTAINER  Rohit Gupta

# Install Shinken, Nagios plugins, apache2 and supervisord
RUN         apt-get update && apt-get install -y python-pip \
                python-pycurl \
                python-cherrypy3 \
                nagios-plugins \
                libsys-statistics-linux-perl \
                apache2 \
                libapache2-mod-proxy-html \
                supervisor \
                ntp
RUN         useradd --create-home shinken && \
                pip install shinken && \
                update-rc.d -f apache2 remove && \
                update-rc.d -f shinken remove

# Install shinken modules from shinken.io
RUN         chown -R shinken:shinken /etc/shinken/ && \
                su - shinken -c 'shinken --init' && \
                su - shinken -c 'shinken install webui' && \
                su - shinken -c 'shinken install auth-htpasswd' && \
                su - shinken -c 'shinken install sqlitedb' && \
                su - shinken -c 'shinken install pickle-retention-file-scheduler' && \
                su - shinken -c 'shinken install booster-nrpe' && \
                su - shinken -c 'shinken install logstore-sqlite' && \
                su - shinken -c 'shinken install livestatus'

# Install and configure thruk
RUN         gpg --keyserver keys.gnupg.net --recv-keys F8C1CA08A57B9ED7 && \
                gpg --armor --export F8C1CA08A57B9ED7 | apt-key add - && \
                echo 'deb http://labs.consol.de/repo/stable/debian wheezy main' >> /etc/apt/sources.list && \
                apt-get update && \
                apt-get install -y thruk && \
                apt-get clean
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
RUN         mkdir -p /etc/shinken/custom_configs /usr/local/custom_plugins && \
                ln -sf /etc/shinken/custom_configs/htpasswd.users /etc/shinken/htpasswd.users && \
                rm -f /etc/thruk/htpasswd && \
                ln -sf /etc/shinken/htpasswd.users /etc/thruk/htpasswd && \
                chown -R shinken:shinken /etc/shinken/

# Copy extra NRPE plugins and fix permissions
ADD         extra_plugins/* /usr/lib/nagios/plugins/
RUN         cd /usr/lib/nagios/plugins/ && \
                chmod a+x * && \
                chmod u+s check_apt restart_service check_ping check_icmp check_fping apt_update

# Define mountable directories
VOLUME      ["/etc/shinken/custom_configs", "/usr/local/custom_plugins"]

# configure supervisor
ADD         supervisor/conf.d/* /etc/supervisor/conf.d/

# Expost port 80 (apache2)
EXPOSE  80

# Default docker process
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
