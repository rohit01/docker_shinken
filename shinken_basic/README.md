Shinken Basic
=============

[![Docker Pulls](https://img.shields.io/docker/pulls/rohit01/shinken.svg)](https://hub.docker.com/r/rohit01/shinken/) [![Docker Stars](https://img.shields.io/docker/stars/rohit01/shinken.svg)](https://hub.docker.com/r/rohit01/shinken/) [![](https://badge.imagelayers.io/rohit01/shinken:latest.svg)](https://imagelayers.io/?images=rohit01/shinken:latest)

It has basic shinken installation along with few must have modules like WebUI2 (Web Interface), standard nrpe plugins + few extra ones, nrpe-booster support and a lightweight web server (nginx).

How to run:

    $ git clone https://github.com/rohit01/docker_shinken.git
    $ cd docker_shinken/shinken_basic
    $ sudo docker run -d -v "$(pwd)/custom_configs:/etc/shinken/custom_configs" -p 80:80 rohit01/shinken

Once done, visit this url: <http://localhost/>
Default credentials: admin/admin

Note:

* [custom_configs/](custom_configs/): Add all you configuration files here.
* [custom_configs/htpasswd.users](custom_configs/htpasswd.users): Define user login credentials here. Documentation is written as comments in this file.
* The nrpe plugins installation directory is /usr/lib/nagios/plugins.
* If you are using custom NRPE plugins, please mount your plugins directory inside docker container at /usr/local/custom_plugins. You need to define resource paths accordingly.

Docker registry link: <https://registry.hub.docker.com/u/rohit01/shinken/>


Alternative Installation:
========================

### Using docker-compose and local files:

It is possible to create a customized instance of the Docker image building it from the source.
To do this, make any changes that you need to `shinken.cfg` inside the `shinken` folder and then build using the provided `docker-compose.yml` file provided that docker compose is installed.

    ```
    $ docker-compose build
    $ docker-compose up -d
    ```

If everything worked correctly then browse to the site. If there are problems then run `docker-compose up` without the `-d` flag and look at the command output to make sure that everything is running as it should.


##### WebUI2 - Using the worldmap:

The worldmap plugin has been added. In order to use it you need to customize the file `shinken/webui2_worldmap.cfg`.

Change the map initial location in the file by modifying the lines

			default_lat=40.498065
			default_lng=-73.781811

Then in your host or in a host template you need the following attributes:

		 _LOC_LAT
		 _LOC_LNG

For example for each one of my closets I have a template which only contains the location
the name is `map-[closet_name]` . All the hosts in that closet then get added this host template
which then can be conveniently added without having to work with lat and lng coordinates

		# A sample location host template
		define host {
		  name        map-rcs-idf01
		  _LOC_LAT    32.497316
		  _LOC_LNG    -114.782483
		  register    0
		}
