import { createNamespaceT } from "@angee/ui";

// Only the copy the pages and forms resolve; metadata-labelled columns and
// fields need none.
export const enHostingMessages: Record<string, string> = {
  "form.host": "Host",
  "form.provisioning": "Provisioning",
  "form.deployment": "Deployment",
};

export const useHostingT = createNamespaceT("hosting", enHostingMessages);
