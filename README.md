Docker Shinken
==============

This repository contains Dockerfile for automated builds of:

* Shinken: <https://registry.hub.docker.com/u/rohit01/shinken/>
* shinken Thruk: <https://registry.hub.docker.com/u/rohit01/shinken_thruk/>
* shinken Thruk Graphite: <https://registry.hub.docker.com/u/rohit01/shinken_thruk_graphite/>

Get started in 3 easy steps:
===========================

1. Install [docker](https://docs.docker.com/installation/#installation). Select and pull one of the following docker image:

    * **Shinken**: It has basic shinken installation along with few must have modules like WebUI2 (Web Interface), standard nrpe plugins + few extra ones, nrpe-booster support and a lightweight web server (nginx). Link: <https://registry.hub.docker.com/u/rohit01/shinken/>
    * **Shinken Thruk**: Shinken (as written above) + Thruk web interface. Internal web server nginx is replaced with apache2. Link: <https://registry.hub.docker.com/u/rohit01/shinken_thruk/>
    * **Shinken Thruk Graphite**: Shinken Thruk (as written above) + graph support in WebUI2. Graphs are stored and served using graphite. Retention is configured for 1 month on a per 2 minute basis. Link: <https://registry.hub.docker.com/u/rohit01/shinken_thruk_graphite/>

    Sample Command: `$ sudo docker pull rohit01/shinken`

2. Clone this project. There are three directories corresponding to the docker images mentioned above. Go inside the directory corresponding to your selected image. You will see a directory named: [custom_configs/](https://github.com/rohit01/docker_shinken/tree/master/shinken_basic/custom_configs). Keep all your configuration files here. A default configuration for monitoring docker host is already defined. User login details can be updated in this file: [htpasswd.users](https://github.com/rohit01/docker_shinken/blob/master/shinken_basic/custom_configs/htpasswd.users). File contains the documentation in comments.

3. Run the docker image. Expose TCP port 80 to the base machine and mount custom_configs directory to /etc/shinken/custom_configs. Sample execution:

    ```
    $ git clone https://github.com/rohit01/docker_shinken.git
    $ cd docker_shinken/shinken_basic
    $ sudo docker run -d -v "$(pwd)/custom_configs:/etc/shinken/custom_configs" -p 80:80 rohit01/shinken
    ```

Open your browser and visit these urls (Default credential - admin/admin):

1. **WebUI2**: <http://localhost/>. Available on all three images.
2. **Thruk UI**: <http://localhost/thruk/>. Available on shinken_thruk and shinken_thruk_graphite images.
3. **Graphs**: <http://localhost/service/docker_shinken/http_port_7770#graphs>. Available only on shinken_thruk_graphite image.

### Please Note:

* Configuration changes are required only in one place/directory: custom_configs
* The nrpe plugins installation directory is /usr/lib/nagios/plugins.
* If you are using custom NRPE plugins, please mount your plugins directory inside docker container at /usr/local/custom_plugins. You need to define resource paths accordingly.


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
