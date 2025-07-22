import { createFileRoute, useRouter } from "@tanstack/react-router";
import { useEffect, useState } from "react";

import { Button } from "../components/ui/button";
import { FallingNixFlakes } from "../components/FallingNixFlakes";
import { useAppForm } from "../hooks/form-hook";
import { useReducedMotion } from "../hooks/use-reduced-motion";
import { authClient } from "../lib/auth-client";
import { authSchema } from "../lib/auth-schemas";
import logger from "../lib/logger";
import type { AuthFormData } from "../lib/auth-schemas";
import "../styles/animations.css";

function SignIn() {
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
    } as AuthFormData,
    validators: {
      onChange: authSchema,
    },
    onSubmit: async () => {
      // This will be handled by the individual submit handlers
    },
  });

  /**
   * Handles GitHub OAuth sign-in with OAuth Proxy support
   *
   * OAUTH PROXY FLOW:
   * 1. User clicks "Continue with GitHub" button
   * 2. authClient.signIn.social() initiates OAuth flow
   * 3. User is redirected to GitHub for authorization
   * 4. GitHub redirects to production URL (configured in GitHub OAuth app)
   * 5. Production app (with OAuth Proxy) proxies the callback to current development URL
   * 6. Development app receives and processes the OAuth response
   * 7. User is signed in and redirected to the callback URL
   *
   * TROUBLESHOOTING COMMON ISSUES:
   *
   * 1. "OAuth provider not configured" error:
   *    - Check GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET in .env
   *    - Ensure GitHub OAuth app is created with correct redirect URI
   *    - Verify environment variables are not empty placeholders
   *
   * 2. "Redirect URI mismatch" error:
   *    - GitHub OAuth app redirect URI should match production URL
   *    - Example: https://your-production-app.com/api/auth/callback/github
   *    - NOT the development URL (localhost:3000)
   *
   * 3. "OAuth callback 404" error:
   *    - Check that /api/auth/$.ts route exists and handles OAuth callbacks
   *    - Verify auth.handler() is properly configured in the API route
   *    - Ensure OAuth Proxy productionURL matches GitHub app redirect URI
   *
   * 4. "Session not created" after successful OAuth:
   *    - Check database connection and Better Auth secret configuration
   *    - Verify reactStartCookies() plugin is last in server plugins array
   *    - Check browser cookies and local storage for session data
   *
   * 5. Development-specific issues:
   *    - OAuth Proxy requires production app to be deployed and accessible
   *    - OAUTH_PROXY_PRODUCTION_URL must point to live production instance
   *    - Network issues between production proxy and development environment
   *
   * @see /better-auth/oauth-proxy for OAuth Proxy setup guide
   * @see https://docs.github.com/en/apps/oauth-apps/building-oauth-apps for GitHub OAuth setup
   */
  const handleGitHubSignIn = async () => {
    if (!isClientSide) {
      console.warn("GitHub sign-in attempted before client-side hydration");
      return;
    }

    try {
      logger.info("GitHub OAuth sign in attempt started");
    } catch (logErr) {
      console.warn("Logger not available, using console:", logErr);
    }
    
    setError(null);
    setIsLoading(true);

    try {
      const result = await authClient.signIn.social({
        provider: "github",
        callbackURL: "/",
      });

      try {
        logger.info("GitHub OAuth sign in initiated", {
          success: !result.error,
        });
      } catch (logErr) {
        console.log("GitHub OAuth sign in initiated", { success: !result.error });
      }

      if (result.error) {
        try {
          logger.warn("GitHub OAuth sign in failed", {
            error: result.error.message,
          });
        } catch (logErr) {
          console.warn("GitHub OAuth sign in failed", { error: result.error.message });
        }
        setError(result.error.message ?? "GitHub sign in failed");
        setIsLoading(false);
        return;
      }

      // The OAuth flow will redirect to GitHub, so we don't need to do anything else here
      // In development with OAuth Proxy, the flow goes: GitHub → Production → Dev Environment
      try {
        logger.info("GitHub OAuth redirect initiated");
      } catch (logErr) {
        console.log("GitHub OAuth redirect initiated");
      }
    } catch (err) {
      try {
        logger.error("GitHub OAuth sign in error occurred", {
          error: err,
        });
      } catch (logErr) {
        console.error("GitHub OAuth sign in error occurred", { error: err });
      }
      setError("An unexpected error occurred with GitHub sign in");
      setIsLoading(false);
    }
  };

  const handleSignIn = async (formData: AuthFormData) => {
    if (!isClientSide) {
      console.warn("Sign-in attempted before client-side hydration");
      return;
    }

    try {
      logger.info("Sign in attempt started", { email: formData.email });
    } catch (logErr) {
      console.log("Sign in attempt started", { email: formData.email });
    }
    
    setError(null);
    setIsLoading(true);

    try {
      const result = await authClient.signIn.email({
        email: formData.email,
        password: formData.password,
      });

      try {
        logger.info("Sign in result received", {
          success: !result.error,
          email: formData.email,
        });
      } catch (logErr) {
        console.log("Sign in result received", { success: !result.error, email: formData.email });
      }

      if (result.error) {
        try {
          logger.warn("Sign in failed", {
            email: formData.email,
            error: result.error.message,
          });
        } catch (logErr) {
          console.warn("Sign in failed", { email: formData.email, error: result.error.message });
        }
        setError(result.error.message ?? "Sign in failed");
        return;
      }

      try {
        logger.info("Sign in successful, redirecting to home", {
          email: formData.email,
        });
      } catch (logErr) {
        console.log("Sign in successful, redirecting to home", { email: formData.email });
      }
      
      form.reset();
      router.navigate({ to: "/" });
    } catch (err) {
      try {
        logger.error("Sign in error occurred", {
          email: formData.email,
          error: err,
        });
      } catch (logErr) {
        console.error("Sign in error occurred", { email: formData.email, error: err });
      }
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

      <div className="sm:mx-auto sm:w-full sm:max-w-md relative z-10">
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
                d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
              />
            </svg>
          </div>

          <h1 className="text-4xl font-bold text-white mb-2">Welcome back</h1>
          <p className="text-slate-300 text-lg">
            Sign in to your account to continue
          </p>
        </div>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md relative z-10">
        <div className="bg-white/10 backdrop-blur-xl py-8 px-4 shadow-2xl sm:rounded-2xl sm:px-10 border border-white/20 relative overflow-hidden">
          {/* Glass morphism effect */}
          <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent pointer-events-none"></div>
          <div className="relative z-10">
            {error && (
              <div
                className="rounded-xl bg-red-500/10 border border-red-500/20 p-4 mb-6 backdrop-blur-sm"
                role="alert"
                aria-live="polite"
                aria-atomic="true"
              >
                <div className="flex">
                  <div className="flex-shrink-0">
                    <svg
                      className="h-5 w-5 text-red-400"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fillRule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                        clipRule="evenodd"
                      />
                    </svg>
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-red-300">Error</h3>
                    <p className="text-sm text-red-200">{error}</p>
                  </div>
                </div>
              </div>
            )}

            <form
              className="space-y-6"
              onSubmit={(e) => {
                e.preventDefault();
                // HTML validation will show native browser validation messages
              }}
              noValidate={false}
              aria-label="Sign in form"
            >
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
                  onChange: ({ value }) => {
                    if (!value) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters long";
                    }
                    return undefined;
                  },
                  onBlur: ({ value }) => {
                    if (!value) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters long";
                    }
                    return undefined;
                  },
                }}
                children={(field) => <field.PasswordField />}
              />

              <div className="flex items-center justify-end">
                <div className="text-sm">
                  <a
                    href="/forgot-password"
                    className="font-medium text-purple-300 hover:text-purple-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 rounded transition-colors"
                    onClick={(e) => {
                      e.preventDefault();
                      if (isClientSide) {
                        router.navigate({ to: "/forgot-password" });
                      }
                    }}
                  >
                    Forgot your password?
                  </a>
                </div>
              </div>

              <div>
                <form.Subscribe
                  selector={(state) => [state.canSubmit, state.isSubmitting]}
                  children={([canSubmit, formIsSubmitting]) => (
                    <>
                      <Button
                        type="button"
                        size="lg"
                        className="w-full bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white font-semibold py-3 px-6 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 transform hover:scale-[1.02] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                        disabled={!canSubmit || isLoading || formIsSubmitting}
                        aria-describedby={
                          isLoading ? "signin-status" : undefined
                        }
                        onClick={async () => {
                          if (canSubmit && !isLoading) {
                            await handleSignIn(form.state.values);
                          }
                        }}
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
                            <span className="sr-only">
                              Signing in, please wait
                            </span>
                            <span aria-hidden="true">Signing in...</span>
                          </>
                        ) : (
                          "Sign in"
                        )}
                      </Button>
                      {isLoading && (
                        <div
                          id="signin-status"
                          className="sr-only"
                          aria-live="polite"
                        >
                          Sign in in progress
                        </div>
                      )}
                    </>
                  )}
                />

                <div className="mt-6">
                  <div
                    className="relative"
                    role="separator"
                    aria-label="Alternative sign in methods"
                  >
                    <div className="absolute inset-0 flex items-center">
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
                  variant="outline"
                  size="lg"
                  className="mt-3 w-full bg-white/10 backdrop-blur-sm border-white/20 text-white hover:bg-white/20 hover:border-white/30 font-semibold py-3 px-6 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 transform hover:scale-[1.02] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                  disabled={isLoading}
                  onClick={handleGitHubSignIn}
                  aria-label="Sign in with GitHub"
                >
                  <svg
                    className="w-5 h-5 mr-2"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                    aria-hidden="true"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z"
                      clipRule="evenodd"
                    />
                  </svg>
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
                      <span className="sr-only">
                        Connecting to GitHub, please wait
                      </span>
                      <span aria-hidden="true">Connecting...</span>
                    </>
                  ) : (
                    "Continue with GitHub"
                  )}
                </Button>

                <Button
                  type="button"
                  variant="ghost"
                  size="lg"
                  className="mt-3 w-full text-slate-300 hover:text-white hover:bg-white/10 backdrop-blur-sm font-semibold py-3 px-6 rounded-xl transition-all duration-200 transform hover:scale-[1.02]"
                  onClick={() => {
                    if (isClientSide) {
                      router.navigate({ to: "/sign-up" });
                    }
                  }}
                  aria-label="Navigate to create new account page"
                >
                  Create new account
                </Button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </main>
  );
}

export const Route = createFileRoute("/sign-in")({
  head: () => ({
    meta: [
      {
        title: "Sign In - Connix",
      },
    ],
  }),
  component: SignIn,
});
