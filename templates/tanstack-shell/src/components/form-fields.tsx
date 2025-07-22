import { useStore } from "@tanstack/react-form";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import * as ShadcnSelect from "@/components/ui/select";
import { Slider as ShadcnSlider } from "@/components/ui/slider";
import { Switch as ShadcnSwitch } from "@/components/ui/switch";
import { Textarea as ShadcnTextarea } from "@/components/ui/textarea";

import { useFieldContext, useFormContext } from "../hooks/form-context";

export function SubscribeButton({ label }: { label: string }) {
  const form = useFormContext();
  return (
    <form.Subscribe selector={(state) => state.isSubmitting}>
      {(isSubmitting) => (
        <Button
          type="submit"
          disabled={isSubmitting}
        >
          {label}
        </Button>
      )}
    </form.Subscribe>
  );
}

function ErrorMessages({
  errors,
  fieldName,
}: {
  errors: Array<string | { message: string }>;
  fieldName?: string;
}) {
  // Deduplicate errors to prevent React key warnings
  const uniqueErrors = Array.from(
    new Set(
      errors.map((error) =>
        typeof error === "string" ? error : error.message,
      ),
    ),
  );

  if (uniqueErrors.length === 0) {
    return null;
  }

  return (
    <div
      className="mt-1"
      role="alert"
      aria-live="polite"
    >
      {uniqueErrors.map((errorMessage, index) => (
        <p
          key={`error-${index}-${errorMessage}`}
          className="text-sm text-red-300"
          id={fieldName ? `${fieldName}-error-${index}` : undefined}
        >
          {errorMessage}
        </p>
      ))}
    </div>
  );
}

export function TextField({
  label,
  placeholder,
}: {
  label: string;
  placeholder?: string;
}) {
  const field = useFieldContext<string>();
  const errors = useStore(field.store, (state) => state.meta.errors);

  return (
    <div>
      <Label
        htmlFor={label}
        className="mb-2 text-xl font-bold"
      >
        {label}
      </Label>
      <Input
        value={field.state.value}
        placeholder={placeholder}
        onBlur={field.handleBlur}
        onChange={(e) => field.handleChange(e.target.value)}
      />
      {field.state.meta.isTouched && <ErrorMessages errors={errors} />}
    </div>
  );
}

export function TextArea({
  label,
  rows = 3,
}: {
  label: string;
  rows?: number;
}) {
  const field = useFieldContext<string>();
  const errors = useStore(field.store, (state) => state.meta.errors);

  return (
    <div>
      <Label
        htmlFor={label}
        className="mb-2 text-xl font-bold"
      >
        {label}
      </Label>
      <ShadcnTextarea
        id={label}
        value={field.state.value}
        onBlur={field.handleBlur}
        rows={rows}
        onChange={(e) => field.handleChange(e.target.value)}
      />
      {field.state.meta.isTouched && <ErrorMessages errors={errors} />}
    </div>
  );
}

export function Select({
  label,
  values,
  placeholder,
}: {
  label: string;
  values: Array<{ label: string; value: string }>;
  placeholder?: string;
}) {
  const field = useFieldContext<string>();
  const errors = useStore(field.store, (state) => state.meta.errors);

  return (
    <div>
      <ShadcnSelect.Select
        name={field.name}
        value={field.state.value}
        onValueChange={(value) => field.handleChange(value)}
      >
        <ShadcnSelect.SelectTrigger className="w-full">
          <ShadcnSelect.SelectValue placeholder={placeholder} />
        </ShadcnSelect.SelectTrigger>
        <ShadcnSelect.SelectContent>
          <ShadcnSelect.SelectGroup>
            <ShadcnSelect.SelectLabel>{label}</ShadcnSelect.SelectLabel>
            {values.map((value) => (
              <ShadcnSelect.SelectItem
                key={value.value}
                value={value.value}
              >
                {value.label}
              </ShadcnSelect.SelectItem>
            ))}
          </ShadcnSelect.SelectGroup>
        </ShadcnSelect.SelectContent>
      </ShadcnSelect.Select>
      {field.state.meta.isTouched && <ErrorMessages errors={errors} />}
    </div>
  );
}

export function Slider({ label }: { label: string }) {
  const field = useFieldContext<number>();
  const errors = useStore(field.store, (state) => state.meta.errors);

  return (
    <div>
      <Label
        htmlFor={label}
        className="mb-2 text-xl font-bold"
      >
        {label}
      </Label>
      <ShadcnSlider
        id={label}
        onBlur={field.handleBlur}
        value={[field.state.value]}
        onValueChange={(value) => field.handleChange(value[0])}
      />
      {field.state.meta.isTouched && <ErrorMessages errors={errors} />}
    </div>
  );
}

export function Switch({ label }: { label: string }) {
  const field = useFieldContext<boolean>();
  const errors = useStore(field.store, (state) => state.meta.errors);

  return (
    <div>
      <div className="flex items-center gap-2">
        <ShadcnSwitch
          id={label}
          onBlur={field.handleBlur}
          checked={field.state.value}
          onCheckedChange={(checked) => field.handleChange(checked)}
        />
        <Label htmlFor={label}>{label}</Label>
      </div>
      {field.state.meta.isTouched && <ErrorMessages errors={errors} />}
    </div>
  );
}

export function EmailField({
  label = "Email",
  placeholder = "Enter your email",
}: {
  label?: string;
  placeholder?: string;
}) {
  const field = useFieldContext<string>();
  const errors = useStore(field.store, (state) => state.meta.errors);
  const hasError = !field.state.meta.isValid && field.state.meta.isTouched;
  const errorId = `${field.name}-error`;
  const helpId = `${field.name}-help`;

  return (
    <div>
      <Label
        htmlFor={field.name}
        className="block text-sm font-medium text-slate-200 mb-2"
      >
        {label}{" "}
        <span
          className="text-red-400"
          aria-label="required"
        >
          *
        </span>
      </Label>
      <div className="relative rounded-xl shadow-sm">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <svg
            className="h-5 w-5 text-slate-400"
            fill="currentColor"
            viewBox="0 0 20 20"
            aria-hidden="true"
            role="img"
          >
            <title>Email icon</title>
            <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" />
            <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
          </svg>
        </div>
        <Input
          id={field.name}
          name={field.name}
          type="email"
          value={field.state.value}
          placeholder={placeholder}
          required
          autoComplete="email"
          aria-describedby={`${helpId} ${hasError ? errorId : ""}`.trim()}
          aria-invalid={hasError}
          aria-required="true"
          onBlur={field.handleBlur}
          onChange={(e) => field.handleChange(e.target.value)}
          className={`
            block w-full pl-10 pr-3 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-all duration-200
            ${hasError ? "border-red-400 text-red-100 placeholder-red-300 focus:ring-red-500 focus:border-red-500" : "hover:border-white/30"}
          `}
        />
      </div>
      <p
        id={helpId}
        className="mt-1 text-xs text-slate-400"
      >
        We'll use this email to send you important account information
      </p>
      {field.state.meta.isTouched && hasError && (
        <ErrorMessages
          errors={errors}
          fieldName={field.name}
        />
      )}
    </div>
  );
}

export function PasswordField({
  label = "Password",
  placeholder = "Enter your password",
  autoComplete,
}: {
  label?: string;
  placeholder?: string;
  autoComplete?: string;
}) {
  const field = useFieldContext<string>();
  const errors = useStore(field.store, (state) => state.meta.errors);
  const hasError = !field.state.meta.isValid && field.state.meta.isTouched;
  const errorId = `${field.name}-error`;
  const helpId = `${field.name}-help`;
  const isConfirmPassword = field.name === "confirmPassword";

  // Set appropriate autocomplete based on field name or explicit prop
  const getAutoComplete = () => {
    if (autoComplete) {
      return autoComplete;
    }
    if (field.name === "confirmPassword") {
      return "new-password";
    }
    if (field.name === "password") {
      return "new-password";
    }
    return "current-password";
  };

  return (
    <div>
      <Label
        htmlFor={field.name}
        className="block text-sm font-medium text-slate-200 mb-2"
      >
        {label}{" "}
        <span
          className="text-red-400"
          aria-label="required"
        >
          *
        </span>
      </Label>
      <div className="relative rounded-xl shadow-sm">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <svg
            className="h-5 w-5 text-slate-400"
            fill="currentColor"
            viewBox="0 0 20 20"
            aria-hidden="true"
            role="img"
          >
            <title>Password icon</title>
            <path
              fillRule="evenodd"
              d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z"
              clipRule="evenodd"
            />
          </svg>
        </div>
        <Input
          id={field.name}
          name={field.name}
          type="password"
          value={field.state.value}
          placeholder={placeholder}
          required
          minLength={6}
          maxLength={100}
          autoComplete={getAutoComplete()}
          aria-describedby={`${helpId} ${hasError ? errorId : ""}`.trim()}
          aria-invalid={hasError}
          aria-required="true"
          onBlur={field.handleBlur}
          onChange={(e) => field.handleChange(e.target.value)}
          className={`
            block w-full pl-10 pr-3 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-all duration-200
            ${hasError ? "border-red-400 text-red-100 placeholder-red-300 focus:ring-red-500 focus:border-red-500" : "hover:border-white/30"}
          `}
        />
      </div>
      <p
        id={helpId}
        className="mt-1 text-xs text-slate-400"
      >
        {isConfirmPassword
          ? "Please re-enter your password to confirm"
          : "Must be at least 6 characters long"}
      </p>
      {field.state.meta.isTouched && hasError && (
        <ErrorMessages
          errors={errors}
          fieldName={field.name}
        />
      )}
    </div>
  );
}
