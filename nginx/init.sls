{%- from "nginx/map.jinja" import nginx with context %}

include:
  - nginx.repo
  - nginx.install
  - nginx.config
  - nginx.ssl
  - nginx.server
  - nginx.service
