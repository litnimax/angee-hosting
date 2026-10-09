{%- from "angee/map.jinja" import angee with context %}
{%- set cli = angee.cli %}
{%- set archive = "angee-linux-" ~ grains["osarch"] ~ ".tar.gz" %}
{%- set release = cli.release_url ~ "/" ~ cli.version %}
{%- set target = cli.install_dir ~ "/" ~ cli.version %}

# Each version unpacks into its own directory; the bin symlinks select one.
angee-cli-archive:
  archive.extracted:
    - name: {{ target }}
    - source: {{ release }}/{{ archive }}
    - source_hash: {{ release }}/SHA256SUMS
    - source_hash_name: {{ archive }}
    - enforce_toplevel: False
    - if_missing: {{ target }}/angee

{%- for binary in ("angee", "angee-operator") %}

angee-cli-{{ binary }}:
  file.symlink:
    - name: {{ cli.bin_dir }}/{{ binary }}
    - target: {{ target }}/{{ binary }}
    - force: True
    - require:
      - archive: angee-cli-archive
{%- endfor %}
