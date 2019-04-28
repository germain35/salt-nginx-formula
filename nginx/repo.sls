{%- from "nginx/map.jinja" import nginx with context %}

{%- set osfamily   = salt['grains.get']('os_family') %}
{%- set os         = salt['grains.get']('os') %}
{%- set osrelease  = salt['grains.get']('osrelease') %}
{%- set oscodename = salt['grains.get']('oscodename') %}

{%- if nginx.manage_repo %}
  {%- if osfamily == 'Debian' %}
nginx_repo_pkgs:
  pkg.installed:
    - pkgs:
      - gnupg2
      - ca-certificates
      - lsb-release
      - apt-transport-https
      - python-apt
    - reload_modules: True
    - require_in:
      - pkgrepo: nginx_repo
  {%- endif %}

  {%- if 'repo' in nginx and nginx.repo is mapping %}
nginx_repo:
  pkgrepo.managed:
    {%- for k, v in nginx.repo.items() %}
    - {{k}}: {{v}}
    {%- endfor %}
  {%- endif %}
{%- endif %}
