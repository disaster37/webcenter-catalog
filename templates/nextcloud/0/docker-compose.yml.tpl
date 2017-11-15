version: '2'
{{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
volumes:
  nextcloud_data:
    driver: ${VOLUME_DRIVER}
  nextcloud_config:
    driver: ${VOLUME_DRIVER}
  nextcloud_theme:
    driver: ${VOLUME_DRIVER}
  nextcloud_app:
    driver: ${VOLUME_DRIVER}
  postgres_data:
    driver: ${VOLUME_DRIVER}
{{- end}}
services:
  nextcloud:
    tty: true
    image: wonderfall/nextcloud:12.0
    volumes:
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - nextcloud_data:/data
      - nextcloud_config:/config
      - nextcloud_theme:/nextcloud/themes
      - nextcloud_app:/apps2
    {{- else}}
      - ${VOLUME_DRIVER}/data:/data
      - ${VOLUME_DRIVER}/config:/config
      - ${VOLUME_DRIVER}/theme:/nextcloud/themes
      - ${VOLUME_DRIVER}/app:/apps2
    {{- end}}
    environment:
      - ADMIN_USER=${ADMIN_USER}
      - ADMIN_PASSWORD=${ADMIN_PASSWORD}
      - DOMAIN=${NEXTCLOUD_HOSTNAME}
      - DB_TYPE=pgsql
      - DB_NAME=nextcloud
      - DB_USER=nextcloud
      - DB_HOST=db
      - DB_PASSWORD=${DB_PASSWORD}
    {{- if (.Values.PUBLISH_PORT_HTTP)}}
    ports:
      - ${PUBLISH_PORT_HTTP}:8888
    {{- end}}
    links:
      - postgres:db
    labels:
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.hostname_override: container_name
  postgres:
    tty: true
    image: postgres:9.6.6
    volumes:
   {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - postgres_data:/var/lib/postgresql/data/pgdata
    {{- else}}
      - ${VOLUME_DRIVER}/postgres:/var/lib/postgresql/data/pgdata
    {{- end}}
    environment:
      - PGDATA=/var/lib/postgresql/data/pgdata
      - POSTGRES_DB=nextcloud
      - POSTGRES_USER=nextcloud
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    labels:
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.hostname_override: container_name