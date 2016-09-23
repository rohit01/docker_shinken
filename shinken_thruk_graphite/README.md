Shinken Thruk Graphite
======================

[![Docker Pulls](https://img.shields.io/docker/pulls/rohit01/shinken_thruk_graphite.svg)](https://hub.docker.com/r/rohit01/shinken_thruk_graphite/) [![Docker Stars](https://img.shields.io/docker/stars/rohit01/shinken_thruk_graphite.svg)](https://hub.docker.com/r/rohit01/shinken_thruk_graphite/) [![](https://badge.imagelayers.io/rohit01/shinken_thruk_graphite:latest.svg)](https://imagelayers.io/?images=rohit01/shinken_thruk_graphite:latest)

It contains shinken, thruk and graphite installation along with few must have shinken modules like WebUI (Web Interface), standard nrpe plugins + few extra ones, nrpe-booster support and a web server (apache2).

How to run:

    $ git clone https://github.com/rohit01/docker_shinken.git
    $ cd docker_shinken/shinken_thruk_graphite
    $ sudo docker run -d -v "$(pwd)/custom_configs:/etc/shinken/custom_configs" -p 80:80 rohit01/shinken_thruk_graphite

Once done, visit these urls (Default credentials - admin/admin):

* Default WebUI: <http://localhost/>
* Thruk Web Interface: <http://localhost/thruk/>
* Graphs for perf data are available in WebUI. Sample link: <http://localhost/service/docker_shinken/http_port_7770#graphs>

Note:

* [custom_configs/](custom_configs/): Add all you configuration files here.
* [custom_configs/htpasswd.users](custom_configs/htpasswd.users): Define user login credentials here. Documentation is written as comments in this file.
* The nrpe plugins installation directory is /usr/lib/nagios/plugins.
* If you are using custom NRPE plugins, please mount your plugins directory inside docker container at /usr/local/custom_plugins. You need to define resource paths accordingly.

Docker registry link: <https://registry.hub.docker.com/u/rohit01/shinken_thruk_graphite/>


Alternative Installation:
========================

###Using docker-compose and local files:

It is possible to create a customized instance of the Docker image building it from the source.
To do this, make any changes that you need to `shinken.cfg` inside the `shinken` folder and then build using the provided `docker-compose.yml` file provided that docker compose is installed.

    ```
    $ docker-compose build
    $ docker-compose up -d 
    ```

If everything worked correctly then browse to the site. If there are problems then run `docker-compose up` without the `-d` flag and look at the command output to make sure that everything is running as it should.
