include:
  - pysc
  - sudo

salt-fire-event:
  group:
    - present

/etc/sudoers.d/salt_fire_event:
  file:
    - managed
    - template: jinja
    - source: salt://salt/minion/event/sudo.jinja2
    - mode: 440
    - user: root
    - group: root
    - require:
      - pkg: sudo
      - group: salt-fire-event

/usr/local/bin/salt_fire_event.py:
  file:
    - managed
    - template: jinja
    - source: salt://salt/minion/salt_fire_event.py
    - mode: 551
    - user: root
    - group: root
    - require:
      - module: pysc
