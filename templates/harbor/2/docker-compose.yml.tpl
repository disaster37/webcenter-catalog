version: '2'
{{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
volumes:
  adminserver_data:
    driver: ${VOLUME_DRIVER}
  clair_db:
    driver: ${VOLUME_DRIVER}
  db:
    driver: ${VOLUME_DRIVER}
  registry:
    driver: ${VOLUME_DRIVER}
  ui_token:
    driver: ${VOLUME_DRIVER}
  adminserver_config:
    driver: ${VOLUME_DRIVER}
  ui_ca:
    driver: ${VOLUME_DRIVER}
  setupwrapper:
    driver: ${VOLUME_DRIVER}
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
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - setupwrapper:/harborsetup
      - registry:/storage
    {{- else}}
      - ${VOLUME_DRIVER}/setupwrapper:/harborsetup
      - ${VOLUME_DRIVER}/registry:/storage
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
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - setupwrapper:/harborsetup
    {{- else}}
      - ${VOLUME_DRIVER}/setupwrapper:/harborsetup
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
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - setupwrapper:/harborsetup
    {{- else}}
      - ${VOLUME_DRIVER}/setupwrapper:/harborsetup
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
    image: webcenter/alpine-harbor-setupwrapper:1.2.2-1
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
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - setupwrapper:/harbor/data
    {{- else}}
      - ${VOLUME_DRIVER}/setupwrapper:/harbor/data
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
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - setupwrapper:/harborsetup
      - adminserver_config:/etc/adminserver/config
      - adminserver_data:/data
    {{- else}}
      - ${VOLUME_DRIVER}/setupwrapper:/harborsetup
      - ${VOLUME_DRIVER}/adminserver/config:/etc/adminserver/config
      - ${VOLUME_DRIVER}/adminserver/data:/data
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
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - setupwrapper:/harborsetup
      - ui_ca:/etc/ui/ca
      - ui_token:/etc/ui/token
    {{- else}}
      - ${VOLUME_DRIVER}/setupwrapper:/harborsetup
      - ${VOLUME_DRIVER}/ui/ca:/etc/ui/ca
      - ${VOLUME_DRIVER}/ui/token:/etc/ui/token
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
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - setupwrapper:/harborsetup
      - db:/var/lib/mysql
    {{- else}}
      - ${VOLUME_DRIVER}/setupwrapper:/harborsetup
      - ${VOLUME_DRIVER}/db:/var/lib/mysql
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
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - setupwrapper:/harborsetup
      - clair_db:/var/lib/postgresql/data
    {{- else}}
      - ${VOLUME_DRIVER}/setupwrapper:/harborsetup
      - ${VOLUME_DRIVER}/clair/db:/var/lib/postgresql/data
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
    stdin_open: true
    cpu_quota: 150000
    entrypoint:
      - /bin/sh
      - -c
    volumes:
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - setupwrapper:/harborsetup
    {{- else}}
      - ${VOLUME_DRIVER}/setupwrapper:/harborsetup
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
  