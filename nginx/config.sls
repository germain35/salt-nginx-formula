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

{%- if nginx.manage_conf %}
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
{%- endif %}

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
    - name: {{ nginx.ssl_dir }}/{{certificate}}.key
    {%- if params.key.source is defined %}
    - source: {{ params.key.source }}
      {%- if params.key.source_hash is defined %}
    - source_hash: {{ params.key.source_hash }}
      {%- endif %}
    {% else %}
    - contents_pillar: nginx:certificates:{{certificate}}:key:contents
    {%- endif %}
    - user: root
    - group: root
    - mode: 644
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


{%- if nginx.files is defined %}
  {%- for file, params in nginx.files.iteritems() %}
    {%- if params.get('type', 'file') == 'directory' %}

nginx_files_{{file}}:
  file.recurse:
    - name: {{ nginx.conf_dir | path_join(file) }}
    - source: {{ params.source }}
    - template: jinja
    - defaults: {{ params.get('settings', {}) }}
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - clean: {{ params.get('clean', False) }}
    - require:
      - file: nginx_conf_dir
    - watch_in:
      - service: nginx_service

    {%- else %}

nginx_files_{{file}}:
  file.managed:
    - name: {{ nginx.conf_dir | path_join(file) }}
    - source: {{ params.source }}
    {%- if params.source_hash is defined %}
    - source_hash: {{ params.source_hash }}
    {%- endif %}
    - template: jinja
    - defaults: {{ params.get('settings', {}) }}
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: nginx_conf_dir
    - watch_in:
      - service: nginx_service

    {%- endif %}
  {%- endfor %}
{%- endif %}

nginx_servers_enabled_dir:
  file.directory:
    - name: {{ nginx.conf_dir }}/sites-enabled
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - clean: {{ nginx.purge_servers }}
    - require:
      - file: nginx_conf_dir

{%- if nginx.servers is defined %}
  {%- for server, params in nginx.servers.iteritems() %}
nginx_server_{{server}}:
  file.managed:
    - name: {{ nginx.conf_dir }}/sites-available/{{server}}.conf
    - source: {{ params.source }}
    {%- if params.source_hash is defined %}
    - source_hash: {{ params.source_hash }}
    {%- endif %}
    - template: jinja
    - defaults: {{ params.get('settings', {}) }}
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: nginx_service

    {%- if params.enabled is defined and params.enabled %}
nginx_enable_server_{{server}}:
  file.symlink:
    - name: {{ nginx.conf_dir }}/sites-enabled/{{params.get('prefix', '')}}{{server}}.conf
    - target: {{ nginx.conf_dir }}/sites-available/{{server}}.conf
    - makedirs: True
    - require:
      - file: nginx_server_{{server}}
      - file: nginx_servers_enabled_dir
    - watch_in:
      - service: nginx_service
    {%- endif %}
  {%- endfor %}
{%- endif %}
