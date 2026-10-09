import * as React from "react";
import { Field, Form, Group, registerForm, type RegisteredFormProps } from "@angee/ui";

import { useHostingT } from "../i18n";

const SERVER_MODEL = "hosting.Server";

/**
 * A managed server: its name, host facts, and how Salt provisions it. The
 * provisioning fields are not insertable: a new server takes the model defaults
 * (root over port 22, the pinned angee release) and edits them once saved.
 */
function ServerForm({ resource: _resource, ...props }: RegisteredFormProps): React.ReactElement {
  const t = useHostingT();
  return (
    <Form {...props} resource={SERVER_MODEL}>
      <Field name="name" title />
      <Group label={t("form.host")} columns={2}>
        <Field name="address" />
        <Field name="arch" />
        <Field name="status" />
      </Group>
      <Group label={t("form.provisioning")} columns={2} savedOnly>
        <Field name="ssh_user" />
        <Field name="ssh_port" />
        <Field name="angee_version" />
      </Group>
      <Group columns={1}>
        <Field name="notes" widget="textarea" body={false} />
      </Group>
    </Form>
  );
}

export const serverForm = registerForm(SERVER_MODEL, ServerForm);
