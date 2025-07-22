import { createFormHook } from "@tanstack/react-form";

import {
  EmailField,
  PasswordField,
  Select,
  SubscribeButton,
  TextArea,
  TextField,
} from "../components/form-fields";

import { fieldContext, formContext } from "./form-context";

export const { useAppForm } = createFormHook({
  fieldComponents: {
    TextField,
    EmailField,
    PasswordField,
    Select,
    TextArea,
  },
  formComponents: {
    SubscribeButton,
  },
  fieldContext,
  formContext,
});
