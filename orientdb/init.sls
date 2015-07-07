{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}

include:
  - java.7
  - local
  - locale
  - rsyslog

{%- set version = '2.0.6' -%}
{%- set tar_gz_checksum = 'bff731187790ff3449841d88418d1c99' -%}
{%- set tar_xz_checksum = 'fa12e53e2e48d691026e8f7cefac1498' -%}
{%- set debug = salt['pillar.get']('orientdb:debug', False) -%}
{%- set storages = salt['pillar.get']('orientdb:storages') -%}
{%- set cluster = salt['pillar.get']('orientdb:cluster', {}) %}

/etc/orientdb:
  file:
    - directory
    - user: root
    - group: orientdb
    - mode: 550
    - require:
      - group: orientdb

/etc/orientdb/config.xml:
  file:
    - managed
    - source: salt://orientdb/config.jinja2
    - user: root
    - group: orientdb
    - mode: 440
    - template: jinja
    - require:
      - group: orientdb
      - file: /etc/orientdb
    - context:
        debug: {{ debug }}
        backup: False

/etc/orientdb/logging.properties:
  file:
    - managed
    - source: salt://orientdb/log.jinja2
    - user: root
    - group: orientdb
    - mode: 440
    - template: jinja
    - require:
      - group: orientdb
      - file: /etc/orientdb
    - context:
        debug: {{ debug }}

/var/lib/orientdb:
  file:
    - directory
    - user: orientdb
    - group: orientdb
    - mode: 770
    - require:
      - user: orientdb

/var/lib/orientdb/databases:
  file:
    - directory
    - user: orientdb
    - group: orientdb
    - mode: 770
    - require:
      - file: /var/lib/orientdb

agafua-syslog:
  file:
    - managed
    - name: /usr/local/orientdb-community-{{ version }}/lib/agafua-syslog-0.2.jar
    - source: salt://orientdb/agafua-syslog-0.2.jar
    - user: root
    - group: orientdb
    - mode: 440
    - require:
      - archive: orientdb

orientdb:
  group:
    - present
  user:
    - present
    - shell: /bin/false
    - home: /var/lib/orientdb
    - groups:
      - orientdb
    - require:
      - group: orientdb
  archive:
    - extracted
    - name: /usr/local/
    - archive_format: tar
{#-
    - source: "http://www.orientechnologies.com/download.php?file=orientdb-community-{{ version }}.tar.gz"
    - source_hash: md5={{ cksum }}
    - tar_options: z
#}
    - source: https://archive.robotinfra.com/mirror/orientdb/{{ version }}.tar.xz
    - source_hash: md5={{ tar_xz_checksum }}
    - tar_options: " --xz -"
    - if_missing: /usr/local/orientdb-community-{{ version }}
    - require:
      - file: /usr/local
  file:
    - managed
    - name: /etc/init/orientdb.conf
    - source: salt://orientdb/upstart.jinja2
    - user: root
    - group: root
    - template: jinja
    - mode: 440
    - context:
        version: {{ version }}
        root_dir: /usr/local/orientdb-community-{{ version }}
        cluster: {{ cluster }}
    - require:
      - pkg: jre-7
      - file: jre-7
      - archive: orientdb
      - user: orientdb
      - group: orientdb
  service:
    - running
    - enable: True
    - watch:
      - pkg: jre-7
      - file: jre-7
      - archive: orientdb
      - user: orientdb
      - group: orientdb
      - file: orientdb
      - file: /etc/orientdb/config.xml
      - file: /etc/orientdb/logging.properties
      - file: agafua-syslog
      - file: orientdb-plugins
      - file: /etc/orientdb/hazelcast.xml
      - file: /etc/orientdb/hazelcast.json
      - file: /var/lib/orientdb/databases
    - require:
      - cmd: system_locale
      - file: /var/lib/orientdb

orientdb-plugins:
  file:
    - symlink
    - name: /var/lib/orientdb/plugins
    - target: /usr/local/orientdb-community-{{ version }}/plugins
    - force: True
    - require:
      - archive: orientdb

orientdb-console:
  file:
    - managed
    - name: /usr/local/bin/orientdb
    - user: root
    - group: root
    - mode: 550
    - template: jinja
    - source: salt://orientdb/console.jinja2
    - require:
      - pkg: jre-7
      - file: /usr/local
      - user: orientdb
      - group: orientdb
    - context:
        version: {{ version }}
        directory: /var/lib/orientdb

{#-
  create initial database only if first node in the list + cluster on
 #}
{%- if cluster and grains['id'] == cluster.get('nodes', {'': ''}).keys()[0] -%}
    {%- for name in storages -%}
        {%- if storages[name]['type'] == 'plocal' -%}
            {%- set dirname = '/var/lib/orientdb/databases/' + name -%}
            {%- if not salt['file.directory_exists'](dirname) %}
orientdb-create-initial-{{ name }}:
  cmd:
    - run
    - name: /usr/local/bin/orientdb create database plocal:{{ dirname }} {{ storages[name]['username'] }} {{storages[name]['password'] }}
    - require:
      - file: orientdb-console
      - file: /var/lib/orientdb/databases
    - require_in:
      - service: orientdb
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
{%- endif %}

/etc/orientdb/hazelcast.xml:
  file:
{%- if not cluster %}
    - absent
{%- else %}
    - managed
    - user: root
    - group: orientdb
    - template: jinja
    - mode: 440
    - source: salt://orientdb/cluster.jinja2
    - require:
      - group: orientdb
      - file: /etc/orientdb
{%- endif %}

/etc/orientdb/hazelcast.json:
  file:
{%- if not cluster %}
    - absent
{%- else %}
    - serialize
    - formatter: json
    - user: root
    - group: orientdb
    - mode: 440
    - require:
      - group: orientdb
      - file: /etc/orientdb
    - dataset:
        version: 0
        autoDeploy: True
        hotAlignment: False
        executionMode: undefined
        readQuorum: 1
        writeQuorum: 2
        failureAvailableNodesLessQuorum: False
        readYourWrites: True
        clusters:
          internal: {}
          index: {}
          "*":
            servers:
    {%- for name in cluster.get('nodes', {}) %}
              - "{{ name }}"
    {%- endfor -%}
{%- endif %}

{{ manage_upstart_log('orientdb') }}
