# Shinken Docker installation using pip (latest)
FROM        debian
MAINTAINER  Rohit Gupta

# Install Shinken, Nagios plugins and apache2
RUN         apt-get update
RUN         apt-get install -y python-pip python-pycurl python-cherrypy3 nagios-plugins
RUN         useradd --create-home shinken
RUN         pip install shinken
RUN         update-rc.d -f shinken remove

# Install shinken modules from shinken.io
RUN         su - shinken -c 'shinken --init'
RUN         su - shinken -c 'shinken install webui'
RUN         su - shinken -c 'shinken install auth-htpasswd'
RUN         su - shinken -c 'shinken install sqlitedb'
RUN         su - shinken -c 'shinken install pickle-retention-file-scheduler'
RUN         su - shinken -c 'shinken install booster-nrpe'
RUN         mkdir -p /etc/shinken/custom_configs

# Configure Shinken modules
ADD         shinken/shinken.cfg /etc/shinken/shinken.cfg
ADD         shinken/broker-master.cfg /etc/shinken/brokers/broker-master.cfg
ADD         shinken/poller-master.cfg /etc/shinken/pollers/poller-master.cfg
ADD         shinken/scheduler-master.cfg /etc/shinken/schedulers/scheduler-master.cfg
ADD         shinken/webui.cfg /etc/shinken/modules/webui.cfg

# Install supervisor and configuration 
RUN         pip install supervisor
RUN         mkdir -p /var/log/supervisord
ADD         supervisor/supervisord.conf /etc/supervisord.conf
ADD         supervisor/supervisord.d /etc/supervisord.d

# Expost port 80 (apache )
EXPOSE  80

# Default docker process
CMD ["supervisord", "-c", "/etc/supervisord.conf", "-n"]
