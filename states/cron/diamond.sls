{#
 Diamond statistics for Cron
#}
include:
  - diamond

cron_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[cron]]
        exe = ^\/usr\/sbin\/cron$
