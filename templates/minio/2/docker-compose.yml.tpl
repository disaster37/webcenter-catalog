version: '2'
services:
  minio-server:
    tty: true
    image: webcenter/alpine-minio:2017-10-27_1
    volumes:
      - minio-scheduler-setting:/opt/scheduler
    {{- if contains .Values.VOLUME_DRIVER "/" }}
      {{- range $idx, $e := atoi .Values.MINIO_DISKS | until }}
      - {{.Values.VOLUME_DRIVER}}/{{.Values.DISK_BASE_NAME}}{{$idx}}:/data/disk{{$idx}}
      {{- end}}
    {{- else}}
       {{- range $idx, $e := atoi .Values.MINIO_DISKS | until }}
      - minio-data-{{$idx}}:/data/disk{{$idx}}
      {{- end}}
    {{- end}}
    environment:
      - MINIO_CONFIG_accesskey=${MINIO_ACCESS_KEY}
      - MINIO_CONFIG_secretkey=${MINIO_SECRET_KEY}
      - CONFD_BACKEND=${CONFD_BACKEND}
      - CONFD_NODES=${CONFD_NODES}
      - CONFD_PREFIX_KEY=${CONFD_PREFIX}
      {{- range $idx, $e := atoi .Values.MINIO_DISKS | until }}
      - MINIO_DISKS_{{$idx}}=disk{{$idx}}
      {{- end}}
    {{- if (.Values.PUBLISH_PORT)}}
    ports:
      - ${PUBLISH_PORT}:9000
    {{- end}}
    labels:
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.hostname_override: container_name
      io.rancher.sidekicks: rancher-cattle-metadata
  rancher-cattle-metadata:
    network_mode: none
    labels:
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.hostname_override: container_name
      io.rancher.container.start_once: "true"
    image: webcenter/rancher-cattle-metadata:1.0.1
    volumes:
      - minio-scheduler-setting:/opt/scheduler
volumes:
  minio-scheduler-setting:
    driver: local
    per_container: true
  {{- if not (contains .Values.VOLUME_DRIVER "/")}}
    {{- range $idx, $e := atoi .Values.MINIO_DISKS | until }}
  minio-data-{{$idx}}:
    per_container: true
    driver: ${VOLUME_DRIVER}
    {{- end}}
  {{- end}}
