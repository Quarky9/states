{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}
{%- set version = '1.9.17.1' -%}
{%- set extracted_dir = '/usr/local/uwsgi-{0}'.format(version) %}

{{ upstart_absent('uwsgi') }}

{%- for file in ('/etc/uwsgi', '/etc/uwsgi.yml', '/var/lib/uwsgi', extracted_dir) %}
{{ file }}:
  file:
    - absent
    - require:
      - service: uwsgi
{%- endfor %}

apt-key del 67E15F46:
  cmd:
    - run
    - onlyif: apt-key list | grep -q 67E15F46
