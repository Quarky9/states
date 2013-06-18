include:
  - nginx
  - apt
  - postgresql.server
  - uwsgi.php
  - web

{% set version = "0.9.0" %}
{% set roundcubedir = "/usr/local/roundcubemail-" + version %}

php5-pgsql:
  pkg:
    - installed
    - require:
      - cmd: apt_sources

roundcube:
  archive:
    - extracted
    - name: /usr/local/
    - source: http://jaist.dl.sourceforge.net/project/roundcubemail/roundcubemail/{{ version }}/roundcubemail-{{ version }}.tar.gz
    - source_hash: md5=843de3439886c2dddb0f09e9bb6a4d04
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/local/roundcubemail-{{ version }}
  postgres_user:
    - present
    - name: roundcube
    - password: {{ pillar['roundcube']['password'] }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: roundcube
    - owner: roundcube
    - runas: postgres
    - require:
      - postgres_user: roundcube

{{ roundcubedir }}:
  file:
    - directory
    - user: root
    - group: root
    - recurse:
      - user
      - group
    - require:
      - archive: roundcube

{{ roundcubedir }}/config/db.inc.php:
  file:
    - managed
    - source: salt://roundcube/database.jinja2
    - template: jinja
    - makedirs: True
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - archive: roundcube
      - user: web

{{ roundcubedir }}/config/main.inc.php:
  file:
    - managed
    - source: salt://roundcube/config.jinja2
    - template: jinja
    - makedirs: True
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - user: web
      - archive: roundcube

{% for dir in ('logs', 'temp') %}
{{ roundcubedir }}/{{ dir }}:
  file:
    - directory
    - user: www-data
    - recurse:
      - user
    - require:
      - file: {{ roundcubedir }}
      - user: web
{% endfor %}

/etc/nginx/conf.d/roundcube.conf:
  file:
    - managed
    - source: salt://roundcube/nginx.jinja2
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - pkg: nginx
      - user: web
    - context:
      dir: {{ roundcubedir }}
    - watch_in:
      - service: nginx

/etc/uwsgi/roundcube.ini:
  file:
    - managed
    - source: salt://roundcube/uwsgi.jinja2
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - file: uwsgi_emperor
      - postgres_database: roundcube
      - cmd:
    - context:
      dir: {{ roundcubedir }}

roundcube_initial:
  cmd:
    - wait
    - name: psql -f {{ roundcubedir }}/SQL/postgres.initial.sql -d roundcube
    - unless: psql roundcube -c 'select * from users'
    - user: postgres
    - group: postgres
    - require:
      - service: postgresql
      - postgres_database: roundcube
    - watch:
      - archive: roundcube
  module:
    - wait
    - name: postgres.owner_to
    - dbname: roundcube
    - ownername: roundcube
    - runas: postgres
    - watch:
      - cmd: roundcube_initial
