{%- from "nginx/map.jinja" import nginx with context %}

include:
  - nginx.repo

{%- if nginx.ssl.enabled %}
nginx_ssl_packages:
  pkg.installed:
    - pkgs: {{ nginx.ssl_pkgs }}
    - require_in:
      - pkg: nginx_package
{%- endif %}

nginx_package:
  pkg.installed:
    - name: {{ nginx.pkg }}
    {%- if nginx.version is defined %}
    - version: {{ nginx.version }}
    {%- endif %}
    {%- if nginx.manage_repo %}
    - require:
      - sls: nginx.repo
    {%- endif %}

{%- if nginx.extras %}
nginx_extras_pkg:
  pkg.installed:
    - name: {{ nginx.extras_pkg }}
    - require:
      - pkg: nginx_package 
{%- endif %}
