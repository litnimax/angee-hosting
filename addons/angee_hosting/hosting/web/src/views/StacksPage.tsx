import * as React from "react";
import { Column, List, ResourceList } from "@angee/ui";

import { stackForm } from "./StackForm";

const STACK_MODEL = "hosting.Stack";

/** Every Angee stack, grouped by the server it runs on. */
export function StacksPage(): React.ReactElement {
  return (
    <ResourceList resource={STACK_MODEL} form={stackForm} placement="inline" routed>
      <List resource={STACK_MODEL} defaultGroup={{ field: "server" }}>
        <Column field="name" />
        <Column field="server" />
        <Column field="domain" />
        <Column field="status" />
        <Column field="updated_at" />
      </List>
    </ResourceList>
  );
}
