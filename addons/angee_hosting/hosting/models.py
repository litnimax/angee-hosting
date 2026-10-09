"""Hosting: the servers Salt manages and the Angee stacks deployed on them.

A :class:`Server` is one host provisioned by the repository's masterless Salt
formula (``salt/states/angee``); a :class:`Stack` is one Angee stack root
(``angee.yaml``) on a server. The server owns the projection of its stacks into
the formula's pillar contract (:meth:`Server.salt_pillar`), so the panel's
records are the source of truth for what Salt brings up on each host.
"""

from __future__ import annotations

from typing import Any

from django.db import models

from angee.base.fields import StateField
from angee.base.mixins import AuditMixin
from angee.base.models import AngeeDataModel, role_anchor

DEFAULT_ANGEE_VERSION = "v0.18.0"
"""The angee CLI release the Salt formula installs unless a server pins another."""


class Server(AuditMixin, AngeeDataModel):
    """A host reachable over SSH and configured by the masterless Salt formula."""

    runtime = True
    sqid_prefix = "srv_"

    class ServerStatus(models.TextChoices):
        """Where a server is in its lifecycle."""

        NEW = "new", "New"
        READY = "ready", "Ready"
        UNREACHABLE = "unreachable", "Unreachable"
        RETIRED = "retired", "Retired"

    class ServerArch(models.TextChoices):
        """CPU architecture, in Debian's naming (the formula picks binaries by it)."""

        AMD64 = "amd64", "amd64"
        ARM64 = "arm64", "arm64"

    name = models.CharField(max_length=128)
    address = models.CharField(max_length=255, help_text="Hostname or IP address the panel reaches over SSH.")
    ssh_user = models.CharField(max_length=64, default="root")
    ssh_port = models.PositiveIntegerField(default=22)
    arch = StateField(choices_enum=ServerArch, default=ServerArch.AMD64)
    angee_version = models.CharField(max_length=32, default=DEFAULT_ANGEE_VERSION)
    status = StateField(choices_enum=ServerStatus, default=ServerStatus.NEW)
    notes = models.TextField(blank=True, default="")

    class Meta:
        """Django model options for a server."""

        abstract = True
        ordering = ("name", "sqid")
        rebac_resource_type = "hosting/server"

    def __str__(self) -> str:
        """Return the server name for Django displays."""

        return self.name

    def salt_pillar(self) -> dict[str, Any]:
        """Return this server's pillar for the ``angee`` Salt formula.

        Every stack that is not retired is brought up at its root; the angee CLI
        version is the server's pin.
        """

        stacks = self.stacks.exclude(status=Stack.StackStatus.RETIRED).order_by("name")
        return {
            "angee": {
                "cli": {"version": self.angee_version},
                "stacks": {stack.name: {"root": stack.root} for stack in stacks},
            },
        }


class Stack(AuditMixin, AngeeDataModel):
    """An Angee stack root (``angee.yaml``) deployed on one server."""

    runtime = True
    sqid_prefix = "stk_"

    class StackStatus(models.TextChoices):
        """Where a stack is in its lifecycle."""

        DRAFT = "draft", "Draft"
        ACTIVE = "active", "Active"
        FAILED = "failed", "Failed"
        RETIRED = "retired", "Retired"

    name = models.SlugField(max_length=64, help_text="Stack name, unique on its server.")
    server = models.ForeignKey("hosting.Server", on_delete=models.PROTECT, related_name="stacks")
    root = models.CharField(max_length=255, help_text="ANGEE_ROOT on the server: the directory holding angee.yaml.")
    domain = models.CharField(max_length=255, blank=True, default="", help_text="Public domain the stack serves.")
    status = StateField(choices_enum=StackStatus, default=StackStatus.DRAFT)
    notes = models.TextField(blank=True, default="")

    class Meta:
        """Django model options for a stack."""

        abstract = True
        ordering = ("server", "name", "sqid")
        rebac_resource_type = "hosting/stack"
        constraints = (
            models.UniqueConstraint(fields=("server", "name"), name="%(app_label)s_stack_server_name"),
        )

    def __str__(self) -> str:
        """Return the stack name for Django displays."""

        return self.name


HostingRole = role_anchor("hosting/role")
"""The ``hosting/role`` anchor: its const ``admin`` arm resolves a platform admin
as an effective hosting manager. See :func:`angee.base.models.role_anchor`.
"""
