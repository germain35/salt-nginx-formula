{%- from "nginx/map.jinja" import nginx with context %}

include:
  - nginx.install
  - nginx.config

nginx_service:
  service.running:
    - name: {{ nginx.service }}
    - enable: True
    - reload: {{nginx.reload}}
    - require:
        - pkg: nginx_package
