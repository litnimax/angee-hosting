import * as React from "react";
import { Column, List, ResourceList } from "@angee/ui";

import { serverForm } from "./ServerForm";

const SERVER_MODEL = "hosting.Server";

/** Every managed server, grouped by lifecycle status. */
export function ServersPage(): React.ReactElement {
  return (
    <ResourceList resource={SERVER_MODEL} form={serverForm} placement="inline" routed>
      <List resource={SERVER_MODEL} defaultGroup={{ field: "status" }}>
        <Column field="name" />
        <Column field="address" />
        <Column field="arch" />
        <Column field="status" />
        <Column field="updated_at" />
      </List>
    </ResourceList>
  );
}
