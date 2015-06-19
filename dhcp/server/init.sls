{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt

dhcp-server:
  pkg:
    - latest
    - name: isc-dhcp-server
    - require:
      - cmd: apt_sources
  file:
    - managed
    - name: /etc/dhcp/dhcpd.conf
    - template: jinja
    - source: salt://dhcp/server/config.jinja2
    - user: root
    - group: dhcpd
    - mode: 440
    - context:
        subnet: {{ salt["pillar.get"]("dhcp_server:subnet") }}
        netmask: {{ salt["pillar.get"]("dhcp_server:netmask") }}
        range: {{ salt["pillar.get"]("dhcp_server:range") }}
        options: {{ salt["pillar.get"]("dhcp_server:options", {}) }}
        reservations: {{ salt["pillar.get"]("dhcp_server:reservations", {}) }}
    - require:
      - pkg: dhcp-server
  service:
    - running
    - name: isc-dhcp-server
    - watch:
      - file: /etc/default/isc-dhcp-server
      - file: dhcp-server
      - pkg: dhcp-server

/etc/default/isc-dhcp-server:
  file:
    - managed
    - template: jinja
    - source: salt://dhcp/server/default.jinja2
    - user: root
    - group: root
    - mode: 440
    - context:
        interface: {{ salt["pillar.get"]("dhcp_server:interface") }}
    - require:
      - pkg: dhcp-server