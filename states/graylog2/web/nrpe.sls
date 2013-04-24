{#
 Install a graylog2 web interface server
#}
include:
  - nrpe

/etc/nagios/nrpe.d/graylog2-web.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://uwsgi/nrpe/instance.jinja2
    - require:
      - pkg: nagios-nrpe-server
    - context:
      deployment: graylog2
      workers: {{ pillar['graylog2']['workers'] }}
{% if 'cheaper' in pillar['graylog2'] %}
      cheaper: {{ pillar['graylog2']['cheaper'] }}
{% endif %}

/etc/nagios/nrpe.d/graylog2-nginx.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://nginx/nrpe/instance.jinja2
    - require:
      - pkg: nagios-nrpe-server
    - context:
      deployment: graylog2
      domain_name: {{ pillar['graylog2']['hostnames'][0] }}
      http_uri: /login
      https: {{ pillar['graylog2']['ssl']|default(False) }}

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/graylog2-web.cfg
        - file: /etc/nagios/nrpe.d/graylog2-nginx.cfg
