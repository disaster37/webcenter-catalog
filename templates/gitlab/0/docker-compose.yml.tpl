version: '2'
{{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
volumes:
  gitlab_data:
    driver: ${VOLUME_DRIVER}
  redis_data:
    driver: ${VOLUME_DRIVER}
  postgres_data:
    driver: ${VOLUME_DRIVER}
{{- end}}
services:
  gitlab:
    tty: true
    image: sameersbn/gitlab:10.0.4
    volumes:
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - gitlab_data:/home/git/data
    {{- else}}
      - ${VOLUME_DRIVER}/data:/home/git/data
    {{- end}}
    environment:
      - GITLAB_BACKUP_SCHEDULE=
      - GITLAB_HOST=${GITLAB_HOSTNAME}
      - GITLAB_HTTPS=${GITLAB_OVER_HTTPS}
      {{- if (.Values.PUBLISH_PORT_SSH)}}
      - GITLAB_SSH_PORT=${PUBLISH_PORT_SSH}
      {{- end}}
      - GITLAB_MAX_OBJECT_SIZE=209715200
      - GITLAB_SECRETS_DB_KEY_BASE=${GITLAB_SECRETS_DB_KEY_BASE}
      - GITLAB_SECRETS_SECRET_KEY_BASE=${GITLAB_SECRETS_SECRET_KEY_BASE}
      - GITLAB_SECRETS_OTP_KEY_BASE=${GITLAB_SECRETS_OTP_KEY_BASE}
      - GITLAB_TIMEOUT=${GITLAB_TIMEOUT}
      - GITLAB_TIMEZONE=${GITLAB_TIMEZONE}
      - GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD}
      - GITLAB_SIGNUP_ENABLED=${GITLAB_SIGNUP_ENABLED}
      - SSL_SELF_SIGNED=${SSL_SELF_SIGNED}
      {{- if (.Values.SMTP_HOST)}}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_USER=${SMTP_USER}
      - SMTP_PASS=${SMTP_PASS}
      {{- end}}
      {{- if eq .Values.LDAP_ENABLE "true"}}
      - LDAP_ENABLED=${LDAP_ENABLE}
      - LDAP_HOST=${LDAP_HOST}
      - LDAP_BIND_DN=${LDAP_BIND_DN}
      - LDAP_PASS=${LDAP_PASS}
      - LDAP_ACTIVE_DIRECTORY=${LDAP_ACTIVE_DIRECTORY}
      - LDAP_TIMEOUT=${LDAP_TIMEOUT}
      - LDAP_BASE=${LDAP_BASE}
      - LDAP_USER_FILTER=${LDAP_USER_FILTER}
      - LDAP_UID=${LDAP_UID}
      {{- end}}
    {{- if or ((.Values.PUBLISH_PORT_HTTP) (.Values.PUBLISH_PORT_SSH))}}
    ports:
      {{- if (.Values.PUBLISH_PORT_HTTP)}}
      - ${PUBLISH_PORT_HTTP}:80
      {{- end}}
      {{- if (.Values.PUBLISH_PORT_SSH)}}
      - ${PUBLISH_PORT_SSH}:22
      {{- end}}
    {{- end}}
    links:
      - postgres:postgresql
      - redis:redisio
    labels:
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.hostname_override: container_name
  redis:
    image: redis:3
    volumes:
    {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - redis_data:/var/lib/redis
    {{- else}}
    - ${VOLUME_DRIVER}/redis:/var/lib/redis
    {{- end}}
    labels:
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.hostname_override: container_name
  postgres:
    tty: true
    image: sameersbn/postgresql:9.6-2
    volumes:
   {{- if ne (printf "%.1s" .Values.VOLUME_DRIVER) "/" }}
      - postgres_data:/var/lib/postgresql
    {{- else}}
      - ${VOLUME_DRIVER}/postgres:/var/lib/postgresql
    {{- end}}
    environment:
      - DB_NAME=gitlab
      - DB_USER=gitlab
      - DB_PASS=${DB_PASS}
      - DB_EXTENSION=pg_trgm
    labels:
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.hostname_override: container_name