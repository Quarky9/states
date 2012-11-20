include:
  - diamond
  - nrpe

/etc/nginx/conf.d/default.conf:
  file.absent

/etc/nginx/conf.d/example_ssl.conf:
  file.absent

/etc/nagios/nrpe.d/nginx.cfg:
  file.managed:
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 600
    - source: salt://nginx/nrpe.jinja2

nginx:
  apt_repository:
    - present
    - address: http://nginx.org/packages/ubuntu/
    - components:
      - nginx
    - key_server: subkeys.pgp.net
    - key_id: 7BD9BF62
  pkg:
    - installed
    - name: nginx
    - refresh: True
    - require:
      - apt_repository: nginx
  service:
    - running
    - watch:
      - file: nginx_status
      - file: /etc/nginx/conf.d/default.conf
      - file: /etc/nginx/conf.d/example_ssl.conf
      - pkg: nginx

nginx_status:
  file:
    - managed
    - name: /etc/nginx/conf.d/status.conf
    - template: jinja
    - user: nginx
    - group: nginx
    - mode: 600
    - source: salt://nginx/status.jinja2
    - require:
      - pkg: nginx

nginx_diamond_collector:
  file:
    - managed
    - name: /etc/diamond/collectors/NginxCollector.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - source: salt://nginx/diamond.jinja2
    - require:
      - file: nginx_status

extend:
  diamond:
    service:
      - watch:
        - file: nginx_diamond_collector
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/nginx.cfg
