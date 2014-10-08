{%- if 'zookeeper' in salt['grains.get']('roles', []) %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from "zookeeper/map.jinja" import zookeeper_map with context %}

include:
  - zookeeper

/etc/zookeeper:
  file.directory:
    - user: root
    - group: root

{{ zk.data_dir }}:
  file.directory:
    - user: zookeeper
    - group: zookeeper
    - makedirs: True

move-zookeeper-dist-conf:
  cmd.run:
    - name: mv {{ zk.real_home }}/conf {{ zk.real_config }}
    - unless: test -L {{ zk.real_home }}/conf
    - require:
      - file: {{ zk.real_home }}
      - file: /etc/zookeeper

zookeeper-config-link:
  alternatives.install:
    - link: {{ zk.alt_config }}
    - path: {{ zk.real_config }}
    - priority: 30

{{ zk.real_home }}/conf:
  file.symlink:
    - target: {{ zk.real_config }}
    - require:
      - cmd: move-zookeeper-dist-conf

zoo-cfg:
  file.managed:
    - name: {{ zk.real_config }}/zoo.cfg
    - source: salt://zookeeper/conf/zoo.cfg
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      port: {{ zk.port }}
      bind_address: {{ zk.bind_address }}
      data_dir: {{ zk.data_dir }}
      snap_count: {{ zk.snap_count }}
      snap_retain_count: {{ zk.snap_retain_count }}
      purge_interval: {{ zk.purge_interval }}
      max_client_cnxns: {{ zk.max_client_cnxns }}
      zookeepers: {{ zk.zookeepers_with_ids }}


{{ zk.myid_path }}:
  file.managed:
    - user: zookeeper
    - group: zookeeper
    - contents: |
        {{ zk.myid }}

{{ zk.real_config }}/zookeeper-env.sh:
  file.managed:
    - source: salt://zookeeper/conf/zookeeper-env.sh
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - context:
      java_home: {{ zk.java_home }}
      jmx_port: {{ zk.jmx_port }}
      heap_size: {{ zk.heap_size }}
      perm_size: {{ zk.perm_size }}
      jvm_opts: {{ zk.jvm_opts }}

{%- if zookeeper_map.service_script %}
{{ zookeeper_map.service_script }}:
  file.managed:
    - source: salt://zookeeper/conf/{{ zookeeper_map.service_script_source }}
    - user: root
    - group: root
    - mode: {{ zookeeper_map.service_script_mode }}
    - template: jinja
    - context:
      alt_home: {{ zk.alt_home }}

zookeeper-service:
  service.running:
    - name: zookeeper
    - enable: true
    - require:
      - file: {{ zk.data_dir }}
    - watch:
      - file: zoo-cfg
{%- endif %}
{%- endif %}