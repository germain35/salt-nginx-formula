{%- from "nginx/map.jinja" import nginx with context %}

include:
  - nginx.repo
  - nginx.install
  - nginx.config
  - nginx.ssl
  - nginx.service

nginx_servers_available_dir:
  file.directory:
    - name: {{ nginx.conf_dir }}/sites-available
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - require:
      - file: nginx_conf_dir

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
  {%- for server, params in nginx.servers.items() %}
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
    - require:
      - file: nginx_servers_available_dir
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

    {%- if params.get('files', False) %}
      {%- for dir in params.files.get('directory', []) %}
nginx_server_{{server}}_file_directory_{{loop.index}}:
  file.directory:
        {%- for k, v in dir.items() %}
    - {{k}}: {{v}}
        {%- endfor %}
    - watch_in:
      - service: nginx_service
      {%- endfor %}
      {%- for recurse in params.files.get('recurse', []) %}
nginx_server_{{server}}_file_recurse_{{loop.index}}:
  file.recurse:
        {%- for k, v in recurse.items() %}
    - {{k}}: {{v}}
        {%- endfor %}
    - watch_in:
      - service: nginx_service
      {%- endfor %}
      {%- for managed in params.files.get('recurse', []) %}
nginx_server_{{server}}_file_managed_{{loop.index}}:
  file.managed:
        {%- for k, v in managed.items() %}
          {%- if k == 'contents' and v is not list %}
    - {{k}}: |
        {{v|indent(8)}}
          {%- else %}
    - {{k}}: {{v}}
          {%- endif %}
        {%- endfor %}
    - watch_in:
      - service: nginx_service
      {%- endfor %}
    {%- endif %}

  {%- endfor %}
{%- endif %}
