# GoCD.io

### Info:

This template create Harbor stack (private docker registry). It's only work if you use share storage or all stack must be deployed on same node.

It will deploy all service of harbor stack:
- `adminserver`: the core server that share metadata between services

- `jobservice`: the service to lauch jobservice
- `mysql`: the database to store metadatas
- `proxy`: the reverse proxy to access on Harbor modules
- `registry`: to store Docker image
- `ui`: the web interface
- `setupwrapper`: to configure Harbor on the first launch
- `clair`: the service that scan CEV vulnerability
- `postgres-clair`: the database to store CEV scan result


### Usage:

Select Harbor from catalog.
Fils out the form
Click deploy.

Harbor can now be accessed on port `443` through `https` with your hostname.

You can change or optimise LDAP setting from Harbor UI.
 


### Source, bugs and enhances

 If you found bugs or need enhance, you can open ticket on github:
 - [Harbor official core project](https://github.com/vmware/harbor)
 - [Harbor setup wrapper](https://github.com/disaster37/docker-harbor-setupwrapper)