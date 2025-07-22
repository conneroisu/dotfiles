// Core React and routing imports
import { createFileRoute, useRouter } from "@tanstack/react-router";
import { useEffect, useState } from "react";

// Authentication and UI components
import { Button } from "@/components/ui/button";
import { useAppForm } from "@/hooks/form-hook";
import { authClient } from "@/lib/auth-client";
import logger from "@/lib/logger";

/**
 * Reset Password Component
 *
 * Handles the second step of the password reset flow after user clicks magic link.
 * Validates the reset token and allows user to set a new password.
 *
 * Features:
 * - Token validation from URL parameters
 * - Password strength validation with confirmation
 * - Secure password reset via Better Auth API
 * - Success state with automatic redirect
 * - Comprehensive error handling for expired/invalid tokens
 * - Loading states and user feedback
 */
function ResetPassword() {
  // Component state management
  const [error, setError] = useState<string | null>(null); // Error message display
  const [isLoading, setIsLoading] = useState(false); // Loading state during API calls
  const [passwordReset, setPasswordReset] = useState(false); // Success state after password reset
  const router = useRouter(); // Navigation handler
  const { token } = Route.useSearch(); // Extract token from URL query params

  /**
   * Token validation effect
   * Redirects user to forgot password page if no token is present in URL
   * This prevents users from accessing the reset form without a valid magic link
   */
  useEffect(() => {
    if (!token) {
      // No token found in URL - redirect to request a new one
      router.navigate({ to: "/forgot-password" });
    }
  }, [token, router]);

  /**
   * Form configuration using TanStack Form
   * Handles password and confirmation input with comprehensive validation
   */
  const form = useAppForm({
    // Initial form values
    defaultValues: {
      password: "",
      confirmPassword: "",
    },

    // Real-time validation as user types
    validators: {
      onChange: ({ value }) => {
        const errors: Record<string, string> = {};

        // Password validation
        if (!value.password) {
          errors.password = "Password is required";
        } else if (value.password.length < 8) {
          // Enforce minimum password length for security
          errors.password = "Password must be at least 8 characters long";
        }

        // Password confirmation validation
        if (!value.confirmPassword) {
          errors.confirmPassword = "Please confirm your password";
        } else if (value.password !== value.confirmPassword) {
          // Ensure both password fields match to prevent typos
          errors.confirmPassword = "Passwords do not match";
        }

        return errors;
      },
    },

    // Form submission handler (handled by button click instead)
    onSubmit: async () => {
      // This will be handled by the submit handler
    },
  });

  /**
   * Handles the password reset completion
   *
   * Process:
   * 1. Validates new password meets security requirements
   * 2. Calls Better Auth API with token and new password
   * 3. Handles token validation (expired, invalid, or already used)
   * 4. Shows success message and redirects to sign-in
   * 5. Logs all actions for monitoring and debugging
   *
   * Security considerations:
   * - Token is validated server-side
   * - Passwords are hashed before storage
   * - Tokens are single-use and time-limited
   */
  const handleResetPassword = async () => {
    // Log password reset attempt for monitoring
    logger.info("Password reset attempt started");

    // Clear any previous error states
    setError(null);

    // Set loading state to show spinner and disable form
    setIsLoading(true);

    try {
      // Call Better Auth API to complete password reset
      // Token validation and password hashing happen server-side
      const result = await authClient.resetPassword({
        newPassword: form.state.values.password,
        token, // Magic link token from URL
      });

      // Log the result for debugging and monitoring
      logger.info("Password reset result", {
        success: !result.error,
      });

      // Handle API errors (invalid token, expired token, etc.)
      if (result.error) {
        logger.warn("Failed to reset password", {
          error: result.error.message,
        });

        // Handle specific error cases with user-friendly messages
        if (
          result.error.message?.includes("expired") ||
          result.error.message?.includes("invalid")
        ) {
          // Token is expired or invalid - provide clear next steps
          setError(
            "Reset link has expired or is invalid. Please request a new one.",
          );
        } else {
          // Other API errors (network, validation, etc.)
          setError(result.error.message ?? "Failed to reset password");
        }
        return;
      }

      // Success: password has been reset
      logger.info("Password reset successful");
      setPasswordReset(true);

      // Auto-redirect to sign-in page after showing success message
      // Delay allows user to read the success message
      setTimeout(() => {
        router.navigate({ to: "/sign-in" });
      }, 3000); // 3 second delay
    } catch (err) {
      // Handle unexpected errors (network failures, etc.)
      logger.error("Password reset error occurred", { error: err });
      setError("An unexpected error occurred");
    } finally {
      // Always reset loading state, regardless of success or failure
      setIsLoading(false);
    }
  };

  // Success state: show confirmation and auto-redirect
  if (passwordReset) {
    return (
      // Full-height success page layout
      <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
        <div className="sm:mx-auto sm:w-full sm:max-w-md">
          {/* Success card with confirmation message */}
          <div className="bg-white py-8 px-4 shadow-lg sm:rounded-lg sm:px-10 border">
            <div className="rounded-md bg-green-50 p-4">
              <div className="flex">
                {/* Success checkmark icon */}
                <div className="flex-shrink-0">
                  <svg
                    className="h-5 w-5 text-green-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
                {/* Success message with redirect notice */}
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-green-800">
                    Password reset successful!
                  </h3>
                  <div className="mt-2 text-sm text-green-700">
                    <p>
                      Your password has been reset. Redirecting to sign in...
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Main form UI for password reset
  return (
    // Full-height page layout with centered content
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      {/* Page header with title and instructions */}
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="text-center">
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Reset your password
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Enter your new password below
          </p>
        </div>
      </div>

      {/* Main form container with card styling */}
      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow-lg sm:rounded-lg sm:px-10 border">
          {/* Error message display - shown when token validation or password reset fails */}
          {error && (
            <div className="rounded-md bg-red-50 p-4 mb-6">
              <div className="flex">
                {/* Error icon for visual feedback */}
                <div className="flex-shrink-0">
                  <svg
                    className="h-5 w-5 text-red-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
                {/* Error message text */}
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-red-800">{error}</h3>
                </div>
              </div>
            </div>
          )}

          {/* Password reset form - prevents default submission to handle via button click */}
          <form
            className="space-y-6"
            onSubmit={(e) => {
              e.preventDefault(); // Prevent browser form submission
            }}
            noValidate={false} // Allow browser validation as fallback
          >
            {/* New password input field with strength validation */}
            <form.AppField
              name="password"
              validators={{
                // Real-time validation as user types
                onChange: ({ value }) => {
                  if (!value) {
                    return "Password is required";
                  }
                  // Enforce minimum password length for security
                  if (value.length < 8) {
                    return "Password must be at least 8 characters long";
                  }
                  return undefined; // No error
                },
                // Validation when user leaves the field
                onBlur: ({ value }) => {
                  if (!value) {
                    return "Password is required";
                  }
                  if (value.length < 8) {
                    return "Password must be at least 8 characters long";
                  }
                  return undefined; // No error
                },
              }}
              children={(field) => <field.PasswordField label="New password" />} // Uses PasswordField with visibility toggle
            />

            {/* Password confirmation field to prevent typos */}
            <form.AppField
              name="confirmPassword"
              validators={{
                // Real-time validation as user types
                onChange: ({ value }) => {
                  if (!value) {
                    return "Please confirm your password";
                  }
                  // Ensure confirmation matches the password field
                  if (value !== form.state.values.password) {
                    return "Passwords do not match";
                  }
                  return undefined; // No error
                },
                // Validation when user leaves the field
                onBlur: ({ value }) => {
                  if (!value) {
                    return "Please confirm your password";
                  }
                  if (value !== form.state.values.password) {
                    return "Passwords do not match";
                  }
                  return undefined; // No error
                },
              }}
              children={(field) => (
                <field.PasswordField label="Confirm new password" />
              )} // Uses PasswordField with visibility toggle
            />

            {/* Form action buttons section */}
            <div>
              {/* Subscribe to form state to control button availability */}
              <form.Subscribe
                selector={(state) => [state.canSubmit, state.isSubmitting]}
                children={([canSubmit, formIsSubmitting]) => (
                  // Primary submit button with loading states
                  <Button
                    type="button" // Handled via onClick instead of form submission
                    className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    // Disable button when form is invalid, loading, or submitting
                    disabled={!canSubmit || isLoading || formIsSubmitting}
                    onClick={async () => {
                      // Double-check conditions before submission
                      if (canSubmit && !isLoading) {
                        await handleResetPassword();
                      }
                    }}
                  >
                    {/* Dynamic button text based on loading state */}
                    {isLoading ? "Resetting..." : "Reset password"}
                  </Button>
                )}
              />

              {/* Visual separator between primary and secondary actions */}
              <div className="mt-6">
                <div className="relative">
                  {/* Horizontal line */}
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-gray-300" />
                  </div>
                  {/* "Or" text in the center */}
                  <div className="relative flex justify-center text-sm">
                    <span className="px-2 bg-white text-gray-500">Or</span>
                  </div>
                </div>
              </div>

              {/* Secondary action - navigate back to sign-in */}
              <Button
                type="button"
                className="mt-3 w-full flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                onClick={() => {
                  // Navigate back to sign-in page using TanStack Router
                  router.navigate({ to: "/sign-in" });
                }}
              >
                Back to sign in
              </Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

/**
 * TanStack Router route configuration
 *
 * Defines the /reset-password route with token validation from URL search params.
 * The token is extracted from the magic link URL and passed to the component.
 *
 * Expected URL format: /reset-password?token=abc123
 */
export const Route = createFileRoute("/reset-password")({
  component: ResetPassword,

  // Extract and validate the reset token from URL search parameters
  validateSearch: (search: Record<string, unknown>) => {
    return {
      token: (search.token as string) || "", // Extract token or default to empty string
    };
  },
});
