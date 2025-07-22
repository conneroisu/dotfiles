import { createFileRoute, useRouter } from "@tanstack/react-router";
import { useEffect, useState } from "react";

import { Button } from "../components/ui/button";
import { FallingNixFlakes } from "../components/FallingNixFlakes";
import { useAppForm } from "../hooks/form-hook";
import { useReducedMotion } from "../hooks/use-reduced-motion";
import { authClient } from "../lib/auth-client";
import { signUpSchema } from "../lib/auth-schemas";
import logger from "../lib/logger";
import type { SignUpFormData } from "../lib/auth-schemas";

function SignUp() {
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isClientSide, setIsClientSide] = useState(false);
  const router = useRouter();
  const reduceMotion = useReducedMotion();

  // Ensure client-side rendering for components that use browser APIs
  useEffect(() => {
    setIsClientSide(true);
  }, []);

  const form = useAppForm({
    defaultValues: {
      email: "",
      password: "",
      confirmPassword: "",
    } as SignUpFormData,
    validators: {
      onChange: signUpSchema,
    },
    onSubmit: async () => {
      // This will be handled by the submit handler
    },
  });

  const handleSignUp = async (formData: SignUpFormData) => {
    if (!isClientSide) {
      console.warn("Sign-up attempted before client-side hydration");
      return;
    }

    try {
      logger.info("Sign up attempt started", { email: formData.email });
    } catch (logErr) {
      console.log("Sign up attempt started", { email: formData.email });
    }
    
    setError(null);
    setIsLoading(true);

    try {
      const result = await authClient.signUp.email({
        email: formData.email,
        password: formData.password,
        name: formData.email.split("@")[0], // Use email prefix as name
      });

      logger.info("Sign up result received", {
        success: !result.error,
        email: formData.email,
      });

      if (result.error) {
        logger.warn("Sign up failed", {
          email: formData.email,
          error: result.error.message,
        });
        setError(result.error.message ?? "Sign up failed");
        return;
      }

      logger.info("Sign up successful, redirecting to home", {
        email: formData.email,
      });
      form.reset();
      router.navigate({ to: "/" });
    } catch (err) {
      logger.error("Sign up error occurred", {
        email: formData.email,
        error: err,
      });
      setError("An unexpected error occurred");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex flex-col justify-center py-12 sm:px-6 lg:px-8 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-[url('data:image/svg+xml,%3Csvg%20width%3D%2260%22%20height%3D%2260%22%20viewBox%3D%220%200%2060%2060%22%20xmlns%3D%22http%3A//www.w3.org/2000/svg%22%3E%3Cg%20fill%3D%22none%22%20fill-rule%3D%22evenodd%22%3E%3Cg%20fill%3D%22%23ffffff%22%20fill-opacity%3D%220.05%22%3E%3Cpath%20d%3D%22M36%2034v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6%2034v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6%204V0H4v4H0v2h4v4h2V6h4V4H6z%22/%3E%3C/g%3E%3C/g%3E%3C/svg%3E')] opacity-20"></div>

      {/* Falling Nix Flakes Animation - Only render on client side */}
      {isClientSide && (
        <FallingNixFlakes
          count={15}
          reduceMotion={reduceMotion}
        />
      )}

      <header className="sm:mx-auto sm:w-full sm:max-w-md relative z-10">
        <div className="text-center">
          {/* Logo placeholder */}
          <div className="mx-auto h-12 w-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center mb-6">
            <svg
              className="h-6 w-6 text-white"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
              />
            </svg>
          </div>

          <h1 className="text-4xl font-bold text-white mb-2">Join us today</h1>
          <p className="text-slate-300 text-lg">
            Create your account to get started
          </p>
        </div>
      </header>

      <section className="mt-8 sm:mx-auto sm:w-full sm:max-w-md relative z-10">
        <div className="bg-white/10 backdrop-blur-xl py-8 px-4 shadow-2xl sm:rounded-2xl sm:px-10 border border-white/20 relative overflow-hidden">
          {/* Glass morphism effect */}
          <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent pointer-events-none"></div>
          <div className="relative z-10">
            {/* Status announcements for screen readers */}
            <div
              role="status"
              aria-live="polite"
              aria-atomic="true"
              className="sr-only"
            >
              {isLoading && "Creating account, please wait..."}
            </div>

            {/* Error alert region */}
            <div
              role="alert"
              aria-live="assertive"
              aria-atomic="true"
            >
              {error && (
                <div
                  className="rounded-xl bg-red-500/10 border border-red-500/20 p-4 mb-6 backdrop-blur-sm"
                  id="signup-error"
                >
                  <div className="flex">
                    <div className="flex-shrink-0">
                      <svg
                        className="h-5 w-5 text-red-400"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                        aria-hidden="true"
                        role="img"
                      >
                        <title>Error icon</title>
                        <path
                          fillRule="evenodd"
                          d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                          clipRule="evenodd"
                        />
                      </svg>
                    </div>
                    <div className="ml-3">
                      <h2 className="text-sm font-medium text-red-300">
                        Sign up failed
                      </h2>
                      <p className="text-sm text-red-200 mt-1">{error}</p>
                    </div>
                  </div>
                </div>
              )}
            </div>

            <form
              className="space-y-6"
              onSubmit={(e) => {
                e.preventDefault();
                if (form.state.canSubmit && !isLoading) {
                  handleSignUp(form.state.values);
                }
              }}
              noValidate={false}
              aria-describedby={error ? "signup-error" : undefined}
              role="form"
            >
              <fieldset className="space-y-6">
                <legend className="sr-only">Account registration form</legend>
                <form.AppField
                  name="email"
                  validators={{
                    onChange: ({ value }) => {
                      if (!value) {
                        return "Email is required";
                      }
                      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
                        return "Please enter a valid email address";
                      }
                      return undefined;
                    },
                    onBlur: ({ value }) => {
                      if (!value) {
                        return "Email is required";
                      }
                      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
                        return "Please enter a valid email address";
                      }
                      return undefined;
                    },
                  }}
                  children={(field) => <field.EmailField />}
                />

                <form.AppField
                  name="password"
                  validators={{
                    onChange: ({ value, fieldApi }) => {
                      if (!value) {
                        return "Password is required";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters long";
                      }
                      // Trigger validation on confirm password field when password changes
                      setTimeout(() => {
                        fieldApi.form.validateField(
                          "confirmPassword",
                          "change",
                        );
                      }, 0);
                      return undefined;
                    },
                    onBlur: ({ value, fieldApi }) => {
                      if (!value) {
                        return "Password is required";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters long";
                      }
                      // Trigger validation on confirm password field when password changes
                      setTimeout(() => {
                        fieldApi.form.validateField(
                          "confirmPassword",
                          "change",
                        );
                      }, 0);
                      return undefined;
                    },
                  }}
                  children={(field) => <field.PasswordField label="Password" />}
                />

                <form.AppField
                  name="confirmPassword"
                  validators={{
                    onChange: ({ value, fieldApi }) => {
                      if (!value) {
                        return "Please confirm your password";
                      }
                      const formState = fieldApi.form.state;
                      if (value !== formState.values.password) {
                        return "Passwords don't match";
                      }
                      return undefined;
                    },
                    onBlur: ({ value, fieldApi }) => {
                      if (!value) {
                        return "Please confirm your password";
                      }
                      const formState = fieldApi.form.state;
                      if (value !== formState.values.password) {
                        return "Passwords don't match";
                      }
                      return undefined;
                    },
                  }}
                  children={(field) => (
                    <field.PasswordField
                      label="Confirm Password"
                      placeholder="Confirm your password"
                    />
                  )}
                />
              </fieldset>

              <div>
                <form.Subscribe
                  selector={(state) => [state.canSubmit, state.isSubmitting]}
                  children={([canSubmit, formIsSubmitting]) => (
                    <Button
                      type="submit"
                      size="lg"
                      className="w-full bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white font-semibold py-3 px-6 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 transform hover:scale-[1.02] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                      disabled={!canSubmit || isLoading || formIsSubmitting}
                      aria-describedby="signup-button-help"
                      aria-label={
                        isLoading
                          ? "Creating account, please wait"
                          : "Create your account"
                      }
                    >
                      {isLoading ? (
                        <>
                          <svg
                            className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                          >
                            <circle
                              className="opacity-25"
                              cx="12"
                              cy="12"
                              r="10"
                              stroke="currentColor"
                              strokeWidth="4"
                            ></circle>
                            <path
                              className="opacity-75"
                              fill="currentColor"
                              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                            ></path>
                          </svg>
                          Creating account...
                        </>
                      ) : (
                        "Create account"
                      )}
                    </Button>
                  )}
                />
                <p
                  id="signup-button-help"
                  className="sr-only"
                >
                  Submit the form to create your new account
                </p>

                <div
                  className="mt-6"
                  role="separator"
                  aria-label="Alternative options"
                >
                  <div className="relative">
                    <div
                      className="absolute inset-0 flex items-center"
                      aria-hidden="true"
                    >
                      <div className="w-full border-t border-white/20" />
                    </div>
                    <div className="relative flex justify-center text-sm">
                      <span className="px-4 bg-white/10 backdrop-blur-sm text-slate-300 rounded-full">
                        Or
                      </span>
                    </div>
                  </div>
                </div>

                <Button
                  type="button"
                  variant="ghost"
                  size="lg"
                  className="mt-3 w-full text-slate-300 hover:text-white hover:bg-white/10 backdrop-blur-sm font-semibold py-3 px-6 rounded-xl transition-all duration-200 transform hover:scale-[1.02] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                  disabled={isLoading}
                  aria-label="Navigate to sign in page"
                  onClick={() => {
                    router.navigate({ to: "/sign-in" });
                  }}
                >
                  Already have an account? Sign in
                </Button>
              </div>
            </form>
          </div>
        </div>
      </section>
    </main>
  );
}

export const Route = createFileRoute("/sign-up")({
  head: () => ({
    meta: [
      {
        title: "Sign Up - Connix",
      },
    ],
  }),
  component: SignUp,
});
