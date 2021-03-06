version: '2'
volumes:
{{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
  adminserver_data:
    driver: ${HARBOR_STORAGE_DRIVER}
  clair_db:
    driver: ${HARBOR_STORAGE_DRIVER}
  db:
    driver: ${HARBOR_STORAGE_DRIVER}
  registry:
    driver: ${HARBOR_STORAGE_DRIVER}
  ui_token:
    driver: ${HARBOR_STORAGE_DRIVER}
  adminserver_config:
    driver: ${HARBOR_STORAGE_DRIVER}
  ui_ca:
    driver: ${HARBOR_STORAGE_DRIVER}
  setupwrapper:
    driver: ${HARBOR_STORAGE_DRIVER}
{{- end}}
services:
  registry:
    image: vmware/registry:2.6.2-photon
    environment:
      GODEBUG: netdns=cgo
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    {{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
    - setupwrapper:/harborsetup
    - registry:/storage
    {{- else}}
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/registry:/storage
    {{- end}}
    tty: true
    links:
    - setupwrapper:setupwrapper
    - ui:ui
    command:
    - /harborsetup/scripts/entrypoint-registry.sh
    labels:
      io.rancher.container.hostname_override: container_name
  proxy:
    image: vmware/nginx-photon:1.11.13
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    {{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
    - setupwrapper:/harborsetup
    {{- else}}
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    {{- end}}
    tty: true
    links:
    - setupwrapper:setupwrapper
    - ui:ui
    - registry:registry
    - clair:clair
    {{- if or (.Values.HARBOR_HTTP_PORT_EXPOSE) (and (eq .Values.HARBOR_URI_PROTOCOL "https") (.Values.HARBOR_HTTPS_PORT_EXPOSE))}}
    ports:
    {{- if and (eq .Values.HARBOR_URI_PROTOCOL "https") (.Values.HARBOR_HTTPS_PORT_EXPOSE)}}
    - ${HARBOR_HTTPS_PORT_EXPOSE}:443/tcp
    {{- end}}
    {{- if (.Values.HARBOR_HTTP_PORT_EXPOSE)}}
    - ${HARBOR_HTTP_PORT_EXPOSE}:80/tcp
    {{- end}}
    {{- end}}
    command:
    - /harborsetup/scripts/entrypoint-proxy.sh
    labels:
      io.rancher.container.hostname_override: container_name
  jobservice:
    image: vmware/harbor-jobservice:v1.2.2
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    {{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
    - setupwrapper:/harborsetup
    {{- else}}
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    {{- end}}
    tty: true
    links:
    - setupwrapper:setupwrapper
    - ui:ui
    - adminserver:adminserver
    - clair:clair
    command:
    - /harborsetup/scripts/entrypoint-jobservice.sh
    labels:
      io.rancher.container.hostname_override: container_name
  setupwrapper:
    image: webcenter/alpine-harbor-setupwrapper:develop
    environment:
      - HARBORHOSTNAME=${HARBOR_HOSTNAME}
      - HARBOR_ADMIN_PASSWORD=${HARBOR_ADMIN_PASSWORD}
      - SELF_REGISTRATION=${HARBOR_SELF_REGISTRATION}
      - UI_URL_PROTOCOL=${HARBOR_URI_PROTOCOL}
      - SSL_CERT=/harbor/harbor.crt
      - SSL_CERT_KEY=/harbor/harbor.key
      - SSL_CERT_CONTEND=${HARBOR_CERT_CONTEND}
      - SSL_CERT_KEY_CONTEND=${HARBOR_CERT_KEY_CONTEND}
      - WITH_CLAIR=true
      - DB_PASSWORD=${HARBOR_DB_PASSWORD}
      - CLAIR_DB_PASSWORD=${HARBOR_CLAIR_DB_PASSWORD}
      - AUTH_MODE=${HARBOR_AUTH}
      - LDAP_URL=${HARBOR_LDAP_URL}
      - LDAP_USER=${HARBOR_LDAP_USER}
      - LDAP_PASSWORD=${HARBOR_LDAP_PASSWORD}
      - LDAP_BASEDN=${HARBOR_LDAP_BASE_DN}
      - LDAP_UID=${HARBOR_LDAP_UID}
    stdin_open: true
    volumes:
    {{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
    - setupwrapper:/harbor/data
    {{- else}}
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harbor/data
    {{- end}}
    tty: true
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.container.start_once: 'true'
  adminserver:
    image: vmware/harbor-adminserver:v1.2.2
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    {{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
    - setupwrapper:/harborsetup
    - adminserver_config:/etc/adminserver/config
    - adminserver_data:/data
    {{- else}}
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/adminserver/config:/etc/adminserver/config
    - ${HARBOR_STORAGE_BASE_NAME}/adminserver/data:/data
    {{- end}}
    tty: true
    links:
    - setupwrapper:setupwrapper
    command:
    - /harborsetup/scripts/entrypoint-adminserver.sh
    labels:
      io.rancher.container.hostname_override: container_name
  ui:
    image: vmware/harbor-ui:v1.2.2
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    {{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
    - setupwrapper:/harborsetup
    - ui_ca:/etc/ui/ca
    - ui_token:/etc/ui/token
    {{- else}}
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/ui/ca:/etc/ui/ca
    - ${HARBOR_STORAGE_BASE_NAME}/ui/token:/etc/ui/token
    {{- end}}
    tty: true
    links:
    - setupwrapper:setupwrapper
    - registry:registry
    - adminserver:adminserver
    - postgres-clair:postgres
    - mysql:mysql
    - clair:clair
    command:
    - /harborsetup/scripts/entrypoint-ui.sh
    labels:
      io.rancher.container.hostname_override: container_name
  mysql:
    image: vmware/harbor-db:v1.2.2
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    {{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
    - setupwrapper:/harborsetup
    - db:/var/lib/mysql
    {{- else}}
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/db:/var/lib/mysql
    {{- end}}
    tty: true
    links:
    - setupwrapper:setupwrapper
    command:
    - /harborsetup/scripts/entrypoint-mysql.sh
    labels:
      io.rancher.container.hostname_override: container_name
  postgres-clair:
    image: postgres:9.6
    environment:
      - POSTGRES_PASSWORD=${HARBOR_CLAIR_DB_PASSWORD}
      - PGDATA=/var/lib/postgresql/data/pgdata
    stdin_open: true
    volumes:
    {{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
    - setupwrapper:/harborsetup
    - clair_db:/var/lib/postgresql/data
    {{- else}}
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/clair/db:/var/lib/postgresql/data
    {{- end}}
    tty: true
    links:
    - setupwrapper:setupwrapper
    labels:
      io.rancher.container.hostname_override: container_name
  clair:
    image: vmware/clair:v2.0.1-photon
    environment:
      - http_proxy=${HARBOR_PROXY_CHAIN}
      - https_proxy=${HARBOR_PROXY_CHAIN}
      - no_proxy=localhost, 127.0.0.1, rancher-metadata
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    {{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
    - setupwrapper:/harborsetup
    {{- else}}
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    {{- end}}
    tty: true
    links:
    - registry:registry
    - postgres-clair:postgres
    - setupwrapper:setupwrapper
    command:
    - /harborsetup/scripts/entrypoint-clair.sh
    labels:
      io.rancher.container.hostname_override: container_name
  