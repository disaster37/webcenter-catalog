version: '2'
volumes:
{{- if ne .Values.HARBOR_STORAGE_DRIVER "mount"}}
{{- if eq .Values.HARBOR_STORAGE_DRIVER "local"}}
  ${HARBOR_STORAGE_BASE_NAME}/adminserver/data:
    external: false
    driver: local
  ${HARBOR_STORAGE_BASE_NAME}/clair/db:
    external: false
    driver: local
  ${HARBOR_STORAGE_BASE_NAME}/db:
    external: false
    driver: local
  ${HARBOR_STORAGE_BASE_NAME}/registry:
    external: false
    driver: local
  ${HARBOR_STORAGE_BASE_NAME}/ui/token:
    external: false
    driver: local
  ${HARBOR_STORAGE_BASE_NAME}/adminserver/config:
    external: false
    driver: local
  ${HARBOR_STORAGE_BASE_NAME}/ui/ca:
    external: false
    driver: local
  ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:
    external: false
    driver: local
{{- else}}
  ${HARBOR_STORAGE_BASE_NAME}/adminserver/data:
    external: true
    driver: ${HARBOR_STORAGE_DRIVER}
  ${HARBOR_STORAGE_BASE_NAME}/clair/db:
    external: true
    driver: ${HARBOR_STORAGE_DRIVER}
  ${HARBOR_STORAGE_BASE_NAME}/db:
    external: true
    driver: ${HARBOR_STORAGE_DRIVER}
  ${HARBOR_STORAGE_BASE_NAME}/registry:
    external: true
    driver: ${HARBOR_STORAGE_DRIVER}
  ${HARBOR_STORAGE_BASE_NAME}/ui/token:
    external: true
    driver: ${HARBOR_STORAGE_DRIVER}
  ${HARBOR_STORAGE_BASE_NAME}/adminserver/config:
    external: true
    driver: ${HARBOR_STORAGE_DRIVER}
  ${HARBOR_STORAGE_BASE_NAME}/ui/ca:
    external: true
    driver: ${HARBOR_STORAGE_DRIVER}
  ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:
    external: true
    driver: ${HARBOR_STORAGE_DRIVER}
{{- end}}
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
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/registry:/storage
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
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    tty: true
    links:
    - setupwrapper:setupwrapper
    - ui:ui
    - registry:registry
    - clair:clair
    {{- if or (.Values.HARBOR_HTTP_PORT_EXPOSE) (and (.Values.HARBOR_URI_PROTOCOL "https") (.Values.HARBOR_HTTPS_PORT_EXPOSE))}}
    ports:
    {{- if and (.Values.HARBOR_URI_PROTOCOL "https") (.Values.HARBOR_HTTPS_PORT_EXPOSE)}}
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
  test:
    image: ubuntu
    stdin_open: true
    tty: true
  jobservice:
    image: vmware/harbor-jobservice:v1.2.0
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
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
    image: webcenter/alpine-harbor-setupwrapper:test
    environment:
      - HARBORHOSTNAME=${HARBOR_HOSTNAME}
      - HARBOR_ADMIN_PASSWORD=${HARBOR_ADMIN_PASSWORD}
      - SELF_REGISTRATION=${HARBOR_SELF_REGISTRATION}
      - UI_URL_PROTOCOL=${HARBOR_URI_PROTOCOL}
      - SSL_CERT=/harbor/harbor.crt
      - SSL_CERT_KEY=/harbor/harbor.key
      - SSL_CERT_CONTEND=${HARBOR_CERT_CONTEND}
      - SSL_CERT_KEY_CONTEND=${HARBOR_CERT_KEY_CONTEND}
      - WITH_CLAIR='true'
      - DB_PASSWORD=${HARBOR_DB_PASSWORD}
      - CLAIR_DB_PASSWORD=${HARBOR_CLAIR_DB_PASSWORD}
      - AUTH_MODE=${HARBOR_AUTH}
      - LDAP_URL=${HARBOR_LDAP_URL}
      - LDAP_USER=${HARBOR_LDAP_USER}
      - LDAP_PASSWORD=${HARBOR_LDAP_PASSWORD}
    stdin_open: true
    volumes:
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harbor/data
    tty: true
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.container.start_once: 'true'
  adminserver:
    image: vmware/harbor-adminserver:v1.2.0
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/adminserver/config:/etc/adminserver/config
    - ${HARBOR_STORAGE_BASE_NAME}/adminserver/data:/data
    tty: true
    links:
    - setupwrapper:setupwrapper
    command:
    - /harborsetup/scripts/entrypoint-adminserver.sh
    labels:
      io.rancher.container.hostname_override: container_name
  ui:
    image: vmware/harbor-ui:v1.2.0
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/ui/ca:/etc/ui/ca
    - ${HARBOR_STORAGE_BASE_NAME}/ui/token:/etc/ui/token
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
    image: vmware/harbor-db:v1.2.0
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/db:/var/lib/mysql
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
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    - ${HARBOR_STORAGE_BASE_NAME}/clair/db:/var/lib/postgresql/data
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
    stdin_open: true
    entrypoint:
    - /bin/sh
    - -c
    volumes:
    - ${HARBOR_STORAGE_BASE_NAME}/setupwrapper:/harborsetup
    tty: true
    links:
    - registry:registry
    - postgres-clair3:postgres
    - setupwrapper:setupwrapper
    command:
    - /harborsetup/scripts/entrypoint-clair.sh
    labels:
      io.rancher.container.hostname_override: container_name