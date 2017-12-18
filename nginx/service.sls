{%- from "nginx/map.jinja" import nginx with context %}

include:
  - nginx.install
  - nginx.config

nginx_service:
  service.running:
    - name: {{ nginx.service }}
    - enable: {{ nginx.service_enabled }}
    - reload: {{ nginx.service_reload }}
    - require:
        - pkg: nginx_package
