{#-
Copyright (c) 2014, Quan Tong Anh
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Author: Quan Tong Anh <quanta@robotinfra.com>
Maintainer: Quan Tong Anh <quanta@robotinfra.com>
-#}
{%- macro add_key() -%}
{%- set root_home = salt['user.info']('root')['home'] %}
ssh_backup_key:
  file:
    - copy
    - name: {{ root_home }}/.ssh/authorized_keys.bak
    - source: {{ root_home }}/.ssh/authorized_keys
    - require:
      - sls: ssh.client

ssh_add_key:
  cmd:
    - run
    - name: cat {{ root_home }}/.ssh/id_{{ pillar['deployment_key']['type'] }}.pub >> {{ root_home }}/.ssh/authorized_keys
    - unless: grep "$(cat {{ root_home }}/.ssh/id_{{ pillar['deployment_key']['type'] }}.pub)" {{ root_home }}/.ssh/authorized_keys
    - require:
      - file: ssh_backup_key
{%- endmacro %}

{%- macro remove_key() -%}
{%- set root_home = salt['user.info']('root')['home'] %}
ssh_remove_key:
  cmd:
    - run
    - name: mv {{ root_home }}/.ssh/authorized_keys.bak {{ root_home }}/.ssh/authorized_keys
    {%- if caller is defined -%}
        {%- for line in caller().split("\n") -%}
            {%- if loop.first %}
    - require:
            {%- endif %}
{{ line|trim|indent(6, indentfirst=True) }}
        {%- endfor -%}
    {%- endif -%}
{%- endmacro %}
