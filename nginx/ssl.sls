{%- from "nginx/map.jinja" import nginx with context %}

include:
  - nginx.service

{%- if nginx.ssl.enabled or nginx.certificates is defined %}
nginx_ssl_dir:
  file.directory:
    - name: {{ nginx.ssl_dir }}
    - user: root
    - group: root
    - mode: 755
   
nginx_generate_dhparam:
  cmd.run:
    - name: openssl dhparam -out {{ nginx.dh_file }} {{ nginx.ssl.dh_key_length }}
    - creates: {{ nginx.dh_file }}
    - require:
      - file: nginx_ssl_dir
    - watch_in:
      - service: nginx_service
{%- endif %}

{%- if nginx.certificates is defined %}
  {%- for certificate, params in nginx.certificates.items() %}
nginx_key_{{certificate}}:
  file.managed:
    - name: {{ nginx.ssl_dir }}/{{certificate}}.key
    {%- if params.key.source is defined %}
    - source: {{ params.key.source }}
      {%- if params.key.source_hash is defined %}
    - source_hash: {{ params.key.source_hash }}
      {%- else %}
    - skip_verify: True
      {%- endif %}
    {% else %}
    - contents_pillar: nginx:certificates:{{certificate}}:key:contents
    {%- endif %}
    - user: root
    - group: root
    - mode: 600
    - require:
      - file: nginx_ssl_dir
    - watch_in:
      - service: nginx_service

nginx_crt_{{certificate}}:
  file.managed:
    - name: {{ nginx.ssl_dir }}/{{certificate}}.crt
    {%- if params.crt.source is defined %}
    - source: {{ params.crt.source }}
      {%- if params.crt.source_hash is defined %}
    - source_hash: {{ params.crt.source_hash }}
      {%- else %}
    - skip_verify: True
      {%- endif %}
    {%- else %}
    - contents_pillar: nginx:certificates:{{certificate}}:crt:contents
    {%- endif %}
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: nginx_ssl_dir
    - watch_in:
      - service: nginx_service
  {%- endfor %}
{%- endif %}
