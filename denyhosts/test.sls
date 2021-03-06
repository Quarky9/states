{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "os.jinja2" import os with context %}
{%- if os.is_precise %}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - bash
  - denyhosts
  - denyhosts.diamond
  - denyhosts.nrpe
  - doc

{%- set fake_ip = '127.8.9.10' %}

fake_ssh_login:
  cmd:
    - run
    - name: |
{%- set deny_threshold_root = salt['pillar.get']('denyhosts:deny_threshold_root', 1) %}
        logger -p auth.info 'The {{ deny_threshold_root + 1 }} sshd below lines are generated by logger to test DenyHosts'
        for i in $(seq {{ deny_threshold_root + 1 }}); do logger -p auth.warning -t 'sshd[1234]:' 'Failed password for root from {{ fake_ip }} port 5678 ssh2'; done
    - require:
      - sls: bash

test:
  module:
    - run
    - name: service.restart
    - m_name: denyhosts
    - require:
      - cmd: fake_ssh_login
  cmd:
    - run
    - name: /usr/local/bin/denyhosts-unblock {{ fake_ip }}
    - require:
      - sls: denyhosts
      - module: test
  diamond:
    - test
    - map:
        ProcessResources:
          {{ diamond_process_test('denyhosts') }}
        UserScripts:
          denyhosts.blocked: True
    - require:
      - file: /usr/local/diamond/share/diamond/user_scripts/count_denyhosts.sh
  monitoring:
    - run_all_checks
    - order: last
  qa:
    - test
    - name: denyhosts
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
{%- endif %} {# os.is_precise #}
