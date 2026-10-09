import { defineBaseAddon, resourcePageRoutes, type BaseAddonRoute } from "@angee/app";
import type { BaseMenuItem } from "@angee/ui";
import { lazyRouteComponent } from "@tanstack/react-router";
import { Layers, Server, ServerCog } from "lucide-react";

import { enHostingMessages } from "./i18n";
import { serverForm } from "./views/ServerForm";
import { stackForm } from "./views/StackForm";

const HOSTING_ID = "hosting";

const hostingRoutes: readonly BaseAddonRoute[] = [
  ...resourcePageRoutes(
    "hosting.servers",
    "/hosting/servers",
    lazyRouteComponent(() => import("./views/ServersPage"), "ServersPage"),
    "hosting.Server",
    { detailName: "hosting.server", menu: "hosting.servers" },
  ),
  ...resourcePageRoutes(
    "hosting.stacks",
    "/hosting/stacks",
    lazyRouteComponent(() => import("./views/StacksPage"), "StacksPage"),
    "hosting.Stack",
    { detailName: "hosting.stack", menu: "hosting.stacks" },
  ),
];

const hostingMenu: readonly BaseMenuItem[] = [
  {
    id: HOSTING_ID,
    label: "Hosting",
    icon: "hosting-group",
    children: [
      { id: "hosting.servers", label: "Servers", icon: "hosting-server", route: "hosting.servers" },
      { id: "hosting.stacks", label: "Stacks", icon: "hosting-stack", route: "hosting.stacks" },
    ],
  },
];

/** The hosting control panel: the servers Salt manages and the stacks on them. */
const hosting = defineBaseAddon({
  id: HOSTING_ID,
  routes: hostingRoutes,
  menus: hostingMenu,
  i18n: { hosting: enHostingMessages },
  icons: {
    "hosting-group": ServerCog,
    "hosting-server": Server,
    "hosting-stack": Layers,
  },
  forms: { "hosting.Server": serverForm, "hosting.Stack": stackForm },
});

export default hosting;
