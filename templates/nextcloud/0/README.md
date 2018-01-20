# NextCloud


### Info:

This template creates one NextCloud server.

The following Docker container are created:
- NextCloud server: provide data storage and web UI
- MariaDB: store settings and metadata


### Usage:

Select NextCloud from catalog.

Enter your public domain name
Enter the admin login
Enter the admin password
Enter PostgreSQL password

Click deploy.

NextCloud server can now be accessed over the Rancher network on port `8888` (http://IP_CONTAINER:8888). To access from external Rancher network, you need to set load balancer or expose the port 8888.
 
