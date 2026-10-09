"""GraphQL schema contributions for hosting.

Servers and stacks are console resources with ordinary CRUD; both are
admin-gated by ``permissions.zed``. A stack's ``server`` foreign key projects a
nested display node and accepts the server's public id on write.
"""

from __future__ import annotations

import strawberry_django
from django.apps import apps
from strawberry import auto

from angee.graphql.data import AngeeHasuraWriteBackend, hasura_model_resource, public_pk_decoder
from angee.graphql.node import AngeeNode
from angee.graphql.relations import actor_scoped_to_one

Server = apps.get_model("hosting", "Server")
Stack = apps.get_model("hosting", "Stack")


@strawberry_django.type(Server)
class ServerType(AngeeNode):
    """Console projection of one managed server."""

    name: auto
    address: auto
    ssh_user: auto
    ssh_port: auto
    arch: auto
    angee_version: auto
    status: auto
    notes: auto
    created_at: auto
    updated_at: auto


@strawberry_django.type(Stack)
class StackType(AngeeNode):
    """Console projection of one Angee stack, with its server as a display node."""

    name: auto
    server: ServerType | None = actor_scoped_to_one("server")
    root: auto
    domain: auto
    status: auto
    notes: auto
    created_at: auto
    updated_at: auto


_SERVER_RESOURCE = hasura_model_resource(
    ServerType,
    model=Server,
    name="hosting_servers",
    filterable=["id", "name", "address", "arch", "status"],
    sortable=["name", "address", "status", "created_at", "updated_at"],
    aggregatable=["id"],
    groupable=["arch", "status"],
    # A new server takes its provisioning defaults (SSH user/port, angee
    # release) from the model; they are edited once the server exists.
    insertable=["name", "address", "arch", "status", "notes"],
    updatable=["name", "address", "ssh_user", "ssh_port", "arch", "angee_version", "status", "notes"],
    id_column="sqid",
)

_STACK_RESOURCE = hasura_model_resource(
    StackType,
    model=Stack,
    name="hosting_stacks",
    filterable=["id", "name", "server", "domain", "status"],
    sortable=["name", "server", "status", "created_at", "updated_at"],
    aggregatable=["id"],
    groupable=["server", "status"],
    writable=["name", "server", "root", "domain", "status", "notes"],
    field_id_decode={"server": public_pk_decoder(Server)},
    write_backend=AngeeHasuraWriteBackend(Stack, public_id_fields=("server",)),
    id_column="sqid",
)


schemas = {
    "console": {
        "query": [_SERVER_RESOURCE.query, _STACK_RESOURCE.query],
        "mutation": [_SERVER_RESOURCE.mutation, _STACK_RESOURCE.mutation],
        "types": [ServerType, StackType, *_SERVER_RESOURCE.types, *_STACK_RESOURCE.types],
    },
}
