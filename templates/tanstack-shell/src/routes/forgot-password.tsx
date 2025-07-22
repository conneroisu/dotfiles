// Core React and routing imports
import { createFileRoute, useRouter } from "@tanstack/react-router";
import { useState } from "react";

// Authentication and UI components
import { Button } from "@/components/ui/button";
import { useAppForm } from "@/hooks/form-hook";
import { authClient } from "@/lib/auth-client";
import logger from "@/lib/logger";

/**
 * Forgot Password Component
 *
 * Provides a form for users to request a password reset link via email.
 * Uses Better Auth's magic link functionality for secure password reset.
 *
 * Features:
 * - Email validation with real-time feedback
 * - Loading states during submission
 * - Success messaging with anti-enumeration protection
 * - Error handling for network and validation failures
 * - Navigation back to sign-in page
 */
function ForgotPassword() {
  // Component state management
  const [error, setError] = useState<string | null>(null); // Error message display
  const [isLoading, setIsLoading] = useState(false); // Loading state during API calls
  const [emailSent, setEmailSent] = useState(false); // Success state after email sent
  const router = useRouter(); // Navigation handler

  /**
   * Form configuration using TanStack Form
   * Handles email input validation and form state management
   */
  const form = useAppForm({
    // Initial form values
    defaultValues: {
      email: "",
    },

    // Real-time validation as user types
    validators: {
      onChange: ({ value }) => {
        // Required field validation
        if (!value.email) {
          return { email: "Email is required" };
        }

        // Email format validation using regex
        // Checks for basic email structure: text@domain.extension
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.email)) {
          return { email: "Please enter a valid email address" };
        }

        // Return empty object if validation passes
        return {};
      },
    },

    // Form submission handler (handled by button click instead)
    onSubmit: async () => {
      // This will be handled by the submit handler
    },
  });

  /**
   * Handles the password reset request submission
   *
   * Process:
   * 1. Validates email format (handled by form validation)
   * 2. Calls Better Auth API to send reset email
   * 3. Shows success message regardless of email existence (anti-enumeration)
   * 4. Handles errors with user-friendly messages
   * 5. Logs all actions for debugging and monitoring
   */
  const handleSendResetLink = async () => {
    // Log the start of password reset request for monitoring
    logger.info("Password reset request started", {
      email: form.state.values.email,
    });

    // Reset any previous error states
    setError(null);

    // Set loading state to show spinner and disable form
    setIsLoading(true);

    try {
      // Call Better Auth API to initiate password reset
      // The magic link will redirect to /reset-password with token
      const result = await authClient.requestPasswordReset({
        email: form.state.values.email,
        redirectTo: "/reset-password", // Where the magic link will redirect
      });

      // Log the result for debugging and monitoring
      logger.info("Password reset request result", {
        success: !result.error,
        email: form.state.values.email,
      });

      // Handle API errors (network issues, invalid email format, etc.)
      if (result.error) {
        logger.warn("Failed to send reset link", {
          email: form.state.values.email,
          error: result.error.message,
        });
        setError(result.error.message ?? "Failed to send reset link");
        return;
      }

      // Success: email sent (or would be sent for valid emails)
      // NOTE: For security, we show success even for non-existent emails
      // to prevent email enumeration attacks
      logger.info("Reset link sent successfully", {
        email: form.state.values.email,
      });
      setEmailSent(true);
    } catch (err) {
      // Handle unexpected errors (network failures, etc.)
      logger.error("Password reset error occurred", {
        email: form.state.values.email,
        error: err,
      });
      setError("An unexpected error occurred");
    } finally {
      // Always reset loading state, regardless of success or failure
      setIsLoading(false);
    }
  };

  return (
    // Full-height page layout with centered content
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      {/* Page header with title and description */}
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="text-center">
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Forgot your password?
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Enter your email address and we'll send you a reset link
          </p>
        </div>
      </div>

      {/* Main form container with card styling */}
      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow-lg sm:rounded-lg sm:px-10 border">
          {/* Error message display - shown when API calls fail */}
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

          {/* Success message display - shown after successful email submission */}
          {/* NOTE: This appears for both valid and invalid emails to prevent enumeration */}
          {emailSent && (
            <div className="rounded-md bg-green-50 p-4 mb-6">
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
                {/* Success message text */}
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-green-800">
                    Reset link sent! Check your email.
                  </h3>
                </div>
              </div>
            </div>
          )}

          {/* Main form - prevents default submission to handle via button click */}
          <form
            className="space-y-6"
            onSubmit={(e) => {
              e.preventDefault(); // Prevent browser form submission
            }}
            noValidate={false} // Allow browser validation as fallback
          >
            {/* Email input field with comprehensive validation */}
            <form.AppField
              name="email"
              validators={{
                // Real-time validation as user types
                onChange: ({ value }) => {
                  if (!value) {
                    return "Email is required";
                  }
                  // Email format validation using same regex as form-level validation
                  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
                    return "Please enter a valid email address";
                  }
                  return undefined; // No error
                },
                // Validation when user leaves the field
                onBlur: ({ value }) => {
                  if (!value) {
                    return "Email is required";
                  }
                  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
                    return "Please enter a valid email address";
                  }
                  return undefined; // No error
                },
              }}
              children={(field) => <field.EmailField />} // Uses custom EmailField component
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
                        await handleSendResetLink();
                      }
                    }}
                  >
                    {/* Dynamic button text based on loading state */}
                    {isLoading ? "Sending..." : "Send reset link"}
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
 * Defines the /forgot-password route with the ForgotPassword component.
 * This route is accessible to all users (no authentication required).
 */
export const Route = createFileRoute("/forgot-password")({
  component: ForgotPassword,
});
