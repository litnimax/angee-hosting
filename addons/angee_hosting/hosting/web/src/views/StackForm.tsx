import * as React from "react";
import { Field, Form, Group, registerForm, type RegisteredFormProps } from "@angee/ui";

import { useHostingT } from "../i18n";

const STACK_MODEL = "hosting.Stack";

/** An Angee stack: the server it runs on, its root there, and its state. */
function StackForm({ resource: _resource, ...props }: RegisteredFormProps): React.ReactElement {
  const t = useHostingT();
  return (
    <Form {...props} resource={STACK_MODEL}>
      <Field name="name" title />
      <Group label={t("form.deployment")} columns={2}>
        <Field name="server" />
        <Field name="status" />
        <Field name="root" />
        <Field name="domain" />
      </Group>
      <Group columns={1}>
        <Field name="notes" widget="textarea" body={false} />
      </Group>
    </Form>
  );
}

export const stackForm = registerForm(STACK_MODEL, StackForm);
