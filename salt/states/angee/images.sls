{%- from "angee/map.jinja" import angee with context %}
{%- if grains["osarch"] != "amd64" %}
{%- set binfmt = "/proc/sys/fs/binfmt_misc/" %}
{%- set emulated = salt["file.file_exists"](binfmt ~ "qemu-x86_64") or salt["file.file_exists"](binfmt ~ "rosetta") %}

include:
  - angee.docker

{%- if not emulated %}

# Run linux/amd64 containers on a non-amd64 host.
angee-amd64-emulation:
  pkg.installed:
    - name: qemu-user-binfmt
    - require_in:
      - service: angee-docker-service
{%- endif %}

{%- for image in angee.amd64_only_images %}

angee-image-{{ image }}:
  cmd.run:
    - name: docker pull --platform linux/amd64 {{ image }}
    - unless: docker image inspect {{ image }}
    - require:
      - service: angee-docker-service
{%- endfor %}
{%- endif %}
