{%- from "nginx/map.jinja" import nginx with context %}

include:
  - nginx.repo
  - nginx.install
  - nginx.ssl
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

{%- if nginx.files is defined %}
  {%- for file, params in nginx.files.items() %}
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
