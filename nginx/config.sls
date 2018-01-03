{%- from "nginx/map.jinja" import nginx with context %}

include:
  - nginx.repo
  - nginx.install
  - nginx.service

nginx_conf_dir:
  file.directory:
    - name: {{ nginx.conf_dir }}
    - user: root
    - group: root 
    - mode: 755

nginx_conf:
  file.managed:
    - name: {{ nginx.conf_file }}
    - source: salt://nginx/templates/nginx.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx_package
      - file: nginx_conf_dir
    - watch_in:
      - service: nginx_service

{%- if nginx.purge_default %}
nginx_purge_default:
  file.absent:
    - name: {{ nginx.default_conf_file }}
    - watch_in:
      - service: nginx_service
{%- endif %}

{%- if nginx.ssl.enabled or nginx.certificates is defined %}
nginx_ssl_dir:
  file.directory:
    - name: {{ nginx.ssl_dir }}
    - user: root
    - group: root
    - mode: 755

nginx_ssl_private_dir:
  file.directory:
    - name: {{ nginx.ssl_private_dir }}
    - user: root
    - group: root
    - mode: 755
   
nginx_generate_dhparam:
  cmd.run:
    - name: openssl dhparam -out {{ nginx.dh_file }} {{ nginx.ssl.dh_key_length }}
    - creates: {{ nginx.dh_file }}
    - require:
      - pkg: nginx_package
      - file: nginx_ssl_dir
    - watch_in:
      - service: nginx_service
{%- endif %}


{%- if nginx.certificates is defined %}
  {%- for certificate, params in nginx.certificates.iteritems() %}
nginx_key_{{certificate}}:
  file.managed:
    - name: {{ nginx.ssl_private_dir }}/{{certificate}}.key
    {%- if params.key_source is defined %}
    - source: {{ params.key_source }}
      {%- if params.key_source_hash is defined %}
    - source_hash: {{ params.key_source_hash }}
      {%- endif %}
    {%- else %}
    - content: |
      {{ params.key_content }}
    {%- endif %}
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: nginx_ssl_private_dir

nginx_crt_{{certificate}}:
  file.managed:
    - name: {{ nginx.ssl_dir }}/{{certificate}}.crt
    {%- if params.crt_source is defined %}
    - source: {{ params.crt_source }}
      {%- if params.crt_source_hash is defined %}
    - source_hash: {{ params.crt_source_hash }}
      {%- endif %}
    {%- else %}
    - content: |
      {{ params.crt_content }}
    {%- endif %}
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: nginx_ssl_dir
  {%- endfor %}
{%- endif %}


{%- if nginx.upstreams is defined %}
  {%- for upstream, params in nginx.upstreams.iteritems() %}
nginx_upstream_{{upstream}}:
  file.managed:
    - name: {{ nginx.conf_dir }}/upstreams/{{upstream}}.conf
    - source: {{ params.source }}
    {%- if params.source_hash is defined %}
    - source_hash: {{ params.source_hash }}
    {%- endif %}
    - template: jinja
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: nginx_service
  {%- endfor %}
{%- endif %}


{%- if nginx.sites is defined %}
  {%- for site, params in nginx.sites.iteritems() %}
nginx_site_{{site}}:
  file.managed:
    - name: {{ nginx.conf_dir }}/sites-available/{{site}}.conf
    - source: {{ params.source }}
    {%- if params.source_hash is defined %}
    - source_hash: {{ params.source_hash }}
    {%- endif %}
    - template: jinja
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: nginx_service

    {%- if params.enabled is defined and params.enabled %}
nginx_enable_site_{{site}}:
  file.symlink:
    - name: {{ nginx.conf_dir }}/sites-enabled/{{site}}.conf
    - target: {{ nginx.conf_dir }}/sites-available/{{site}}.conf
    - makedirs: True
    - require:
      - file: nginx_site_{{site}}
    - watch_in:
      - service: nginx_service
    {%- endif %}
  {%- endfor %}
{%- endif %}

