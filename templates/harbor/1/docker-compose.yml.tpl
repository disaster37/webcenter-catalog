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
  