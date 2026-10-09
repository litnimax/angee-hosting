{%- from "angee/map.jinja" import angee with context %}

angee-packages:
  pkg.installed:
    - pkgs: {{ angee.packages | json }}

angee-docker-service:
  service.running:
    - name: docker
    - enable: True
    - require:
      - pkg: angee-packages
