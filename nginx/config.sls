{%- from "nginx/map.jinja" import nginx with context %}

include:
  - nginx.repo
  - nginx.install
  - nginx.service

nginx_conf:
  file.managed:
  - name: /etc/nginx/nginx.conf
  - source: salt://nginx/templates/nginx.conf.jinja
  - template: jinja
  - require:
    - pkg: nginx_package
  - watch_in:
    - service: nginx_service

{%- if nginx.ssl.enabled %}
nginx_ssl_dir:
  file.directory:
    - name: {{ nginx.ssl_dir }}
   
nginx_generate_dhparam:
  cmd.run:
  - name: openssl dhparam -out {{ nginx.ssl_dir }}/dhparam.pem {{ nginx.ssl.dh_key_length }}
  - creates: {{ nginx.ssl_dir }}/dhparam.pem
  - require:
    - pkg: nginx_package
    - file: nginx_ssl_dir
  - watch_in:
    - service: nginx_service
{%- endif %}
