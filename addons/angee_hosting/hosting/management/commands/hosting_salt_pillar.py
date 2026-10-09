"""Print a server's pillar for the repository's ``angee`` Salt formula.

The output is the ``angee:`` pillar a masterless host applies, e.g.::

    python manage.py hosting_salt_pillar angee-host-1 > salt/pillar/angee.sls
"""

from __future__ import annotations

import yaml
from django.apps import apps
from django.core.management.base import BaseCommand, CommandError, CommandParser
from rebac import system_context


class Command(BaseCommand):
    """Render one server's ``angee`` pillar as YAML."""

    help = "Print the angee Salt pillar for one server, by name."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("server", help="name of the server")

    def handle(self, *args: object, **options: str) -> None:
        server_model = apps.get_model("hosting", "Server")
        with system_context(reason="hosting.salt_pillar"):
            server = server_model.objects.filter(name=options["server"]).first()
            if server is None:
                raise CommandError(f"server {options['server']!r} not found")
            pillar = server.salt_pillar()
        self.stdout.write(yaml.safe_dump(pillar, sort_keys=False), ending="")
