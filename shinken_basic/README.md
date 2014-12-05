Shinken Basic
=============

It has basic shinken installation along with few must have modules like WebUI (Web Interface), standard nrpe plugins + few extra ones, nrpe-booster support and a lightweight web server (nginx).

How to run:

    ```
    $ git clone https://github.com/rohit01/docker_shinken.git
    $ cd docker_shinken/shinken_basic
    $ sudo docker run -d -v "$(pwd)/custom_configs:/etc/shinken/custom_configs" -p 80:80 rohit01/shinken
    ```

Once done, visit this url: <http://localhost/>
Default credential - admin/admin

Note:

* [custom_configs/](custom_configs/): Add all you configuration files here.
* [custom_configs/htpasswd.users](custom_configs/htpasswd.users): Define user login credentials here. Documentation is written as comments.
* The nrpe plugins installation directory is /usr/lib/nagios/plugins.
* If you are using custom NRPE plugins, please mount your plugins directory inside docker container at /usr/local/custom_plugins. You need to modify resource paths accordingly.

Docker registry link: <https://registry.hub.docker.com/u/rohit01/shinken/>
