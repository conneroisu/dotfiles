import { createFileRoute, useRouter } from "@tanstack/react-router";
import { useState } from "react";

import { Button } from "../components/ui/button";
import { authClient } from "../lib/auth-client";
import logger from "../lib/logger";

/**
 * Two-Factor Authentication Verification Page
 *
 * This page handles 2FA verification during the sign-in process.
 * Users are redirected here when they have 2FA enabled and need to
 * verify their identity with a TOTP code, OTP, or backup code.
 *
 * VERIFICATION METHODS:
 * 1. TOTP - Code from authenticator app (Google Authenticator, Authy, etc.)
 * 2. Email OTP - Code sent to user's email address
 * 3. Backup Code - Single-use recovery codes
 *
 * TRUSTED DEVICE OPTION:
 * - Users can mark their device as trusted for 60 days
 * - Reduces 2FA friction for regular devices
 * - Trust period refreshes on each successful sign-in
 */

function Verify2FA() {
  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [verificationMethod, setVerificationMethod] = useState<
    "totp" | "otp" | "backup"
  >("totp");
  const [trustDevice, setTrustDevice] = useState(false);
  const [otpSent, setOtpSent] = useState(false);
  const [otpCooldown, setOtpCooldown] = useState(0);
  const router = useRouter();

  /**
   * Handles TOTP verification from authenticator apps
   * Verifies the 6-digit time-based code and optionally marks device as trusted
   */
  const handleTotpVerification = async () => {
    if (!code || code.length !== 6) {
      setError("Please enter a valid 6-digit code from your authenticator app");
      return;
    }

    logger.info("TOTP verification attempt started", {
      codeLength: code.length,
    });
    setError(null);
    setIsLoading(true);

    try {
      const result = await authClient.twoFactor.verifyTotp({
        code,
        trustDevice,
      });

      logger.info("TOTP verification result received", {
        success: !result.error,
        trustDevice,
      });

      if (result.error) {
        logger.warn("TOTP verification failed", {
          error: result.error.message,
        });
        setError(result.error.message ?? "Invalid verification code");
        setIsLoading(false);
        return;
      }

      logger.info("TOTP verification successful, redirecting", {
        trustDevice,
      });

      // Successful verification redirects automatically via callbackURL
      router.navigate({ to: "/" });
    } catch (err) {
      logger.error("TOTP verification error occurred", {
        error: err,
      });
      setError("An unexpected error occurred during verification");
      setIsLoading(false);
    }
  };

  /**
   * Sends OTP code to user's email address
   * Alternative verification method for users without authenticator apps
   */
  const handleSendOtp = async () => {
    logger.info("Email OTP send attempt started");
    setError(null);
    setIsLoading(true);

    try {
      const result = await authClient.twoFactor.sendOtp();

      logger.info("Email OTP send result received", {
        success: !result.error,
      });

      if (result.error) {
        logger.warn("Email OTP send failed", {
          error: result.error.message,
        });
        setError(result.error.message ?? "Failed to send verification code");
        setIsLoading(false);
        return;
      }

      logger.info("Email OTP sent successfully");
      setOtpSent(true);
      setOtpCooldown(60); // 60-second cooldown before resending

      // Start cooldown timer
      const timer = setInterval(() => {
        setOtpCooldown((prev) => {
          if (prev <= 1) {
            clearInterval(timer);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);

      setIsLoading(false);
    } catch (err) {
      logger.error("Email OTP send error occurred", {
        error: err,
      });
      setError("An unexpected error occurred while sending the code");
      setIsLoading(false);
    }
  };

  /**
   * Handles OTP verification from email
   * Verifies the 6-digit code sent to user's email address
   */
  const handleOtpVerification = async () => {
    if (!code || code.length !== 6) {
      setError("Please enter the 6-digit code from your email");
      return;
    }

    logger.info("Email OTP verification attempt started", {
      codeLength: code.length,
    });
    setError(null);
    setIsLoading(true);

    try {
      const result = await authClient.twoFactor.verifyOtp({
        code,
      });

      logger.info("Email OTP verification result received", {
        success: !result.error,
      });

      if (result.error) {
        logger.warn("Email OTP verification failed", {
          error: result.error.message,
        });
        setError(result.error.message ?? "Invalid verification code");
        setIsLoading(false);
        return;
      }

      logger.info("Email OTP verification successful, redirecting");
      router.navigate({ to: "/" });
    } catch (err) {
      logger.error("Email OTP verification error occurred", {
        error: err,
      });
      setError("An unexpected error occurred during verification");
      setIsLoading(false);
    }
  };

  /**
   * Handles backup code verification
   * Uses single-use recovery codes for account access when primary 2FA is unavailable
   */
  const handleBackupCodeVerification = async () => {
    if (!code || code.length !== 10) {
      setError("Please enter a valid 10-character backup code");
      return;
    }

    logger.info("Backup code verification attempt started", {
      codeLength: code.length,
    });
    setError(null);
    setIsLoading(true);

    try {
      const result = await authClient.twoFactor.verifyBackupCode({
        code,
      });

      logger.info("Backup code verification result received", {
        success: !result.error,
      });

      if (result.error) {
        logger.warn("Backup code verification failed", {
          error: result.error.message,
        });
        setError(result.error.message ?? "Invalid backup code");
        setIsLoading(false);
        return;
      }

      logger.info("Backup code verification successful, redirecting");
      router.navigate({ to: "/" });
    } catch (err) {
      logger.error("Backup code verification error occurred", {
        error: err,
      });
      setError("An unexpected error occurred during verification");
      setIsLoading(false);
    }
  };

  /**
   * Handles form submission based on selected verification method
   */
  const handleSubmit = async () => {
    switch (verificationMethod) {
      case "totp":
        await handleTotpVerification();
        break;
      case "otp":
        await handleOtpVerification();
        break;
      case "backup":
        await handleBackupCodeVerification();
        break;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="text-center">
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Two-Factor Authentication
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Please verify your identity to continue
          </p>
        </div>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow-lg sm:rounded-lg sm:px-10 border">
          {error && (
            <div className="rounded-md bg-red-50 p-4 mb-6">
              <div className="flex">
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
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-red-800">{error}</h3>
                </div>
              </div>
            </div>
          )}

          {/* Verification Method Tabs */}
          <div className="mb-6">
            <div className="flex space-x-1 rounded-lg bg-gray-100 p-1">
              <button
                onClick={() => setVerificationMethod("totp")}
                className={`flex-1 py-2 px-3 text-sm font-medium rounded-md transition-colors ${
                  verificationMethod === "totp"
                    ? "bg-white text-gray-900 shadow-sm"
                    : "text-gray-500 hover:text-gray-700"
                }`}
              >
                Authenticator App
              </button>
              <button
                onClick={() => setVerificationMethod("otp")}
                className={`flex-1 py-2 px-3 text-sm font-medium rounded-md transition-colors ${
                  verificationMethod === "otp"
                    ? "bg-white text-gray-900 shadow-sm"
                    : "text-gray-500 hover:text-gray-700"
                }`}
              >
                Email Code
              </button>
              <button
                onClick={() => setVerificationMethod("backup")}
                className={`flex-1 py-2 px-3 text-sm font-medium rounded-md transition-colors ${
                  verificationMethod === "backup"
                    ? "bg-white text-gray-900 shadow-sm"
                    : "text-gray-500 hover:text-gray-700"
                }`}
              >
                Backup Code
              </button>
            </div>
          </div>

          <form
            className="space-y-6"
            onSubmit={(e) => {
              e.preventDefault();
              handleSubmit();
            }}
          >
            {/* TOTP Method */}
            {verificationMethod === "totp" && (
              <>
                <div>
                  <label
                    htmlFor="totp-code"
                    className="block text-sm font-medium text-gray-700"
                  >
                    Verification Code
                  </label>
                  <div className="mt-1">
                    <input
                      id="totp-code"
                      name="code"
                      type="text"
                      inputMode="numeric"
                      pattern="[0-9]*"
                      maxLength={6}
                      placeholder="123456"
                      required
                      value={code}
                      onChange={(e) =>
                        setCode(e.target.value.replace(/\D/g, ""))
                      }
                      className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 text-center text-2xl font-mono tracking-widest"
                    />
                  </div>
                  <p className="mt-2 text-sm text-gray-500">
                    Enter the 6-digit code from your authenticator app
                  </p>
                </div>

                <div className="flex items-center">
                  <input
                    id="trust-device"
                    name="trust-device"
                    type="checkbox"
                    checked={trustDevice}
                    onChange={(e) => setTrustDevice(e.target.checked)}
                    className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                  />
                  <label
                    htmlFor="trust-device"
                    className="ml-2 block text-sm text-gray-900"
                  >
                    Trust this device for 60 days
                  </label>
                </div>
              </>
            )}

            {/* Email OTP Method */}
            {verificationMethod === "otp" && (
              <>
                {!otpSent ? (
                  <div className="text-center">
                    <p className="text-sm text-gray-600 mb-4">
                      We'll send a verification code to your email address
                    </p>
                    <Button
                      type="button"
                      onClick={handleSendOtp}
                      disabled={isLoading}
                      className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      {isLoading ? "Sending..." : "Send Verification Code"}
                    </Button>
                  </div>
                ) : (
                  <>
                    <div>
                      <label
                        htmlFor="otp-code"
                        className="block text-sm font-medium text-gray-700"
                      >
                        Email Verification Code
                      </label>
                      <div className="mt-1">
                        <input
                          id="otp-code"
                          name="code"
                          type="text"
                          inputMode="numeric"
                          pattern="[0-9]*"
                          maxLength={6}
                          placeholder="123456"
                          required
                          value={code}
                          onChange={(e) =>
                            setCode(e.target.value.replace(/\D/g, ""))
                          }
                          className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 text-center text-2xl font-mono tracking-widest"
                        />
                      </div>
                      <p className="mt-2 text-sm text-gray-500">
                        Enter the 6-digit code sent to your email
                      </p>
                    </div>

                    <div className="text-center">
                      <Button
                        type="button"
                        onClick={handleSendOtp}
                        disabled={otpCooldown > 0}
                        className="text-sm text-indigo-600 hover:text-indigo-500 disabled:text-gray-400"
                        variant="link"
                      >
                        {otpCooldown > 0
                          ? `Resend in ${otpCooldown}s`
                          : "Resend Code"}
                      </Button>
                    </div>
                  </>
                )}
              </>
            )}

            {/* Backup Code Method */}
            {verificationMethod === "backup" && (
              <>
                <div>
                  <label
                    htmlFor="backup-code"
                    className="block text-sm font-medium text-gray-700"
                  >
                    Backup Code
                  </label>
                  <div className="mt-1">
                    <input
                      id="backup-code"
                      name="code"
                      type="text"
                      maxLength={10}
                      placeholder="abcd-efgh-12"
                      required
                      value={code}
                      onChange={(e) => setCode(e.target.value.toLowerCase())}
                      className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 text-center text-lg font-mono"
                    />
                  </div>
                  <p className="mt-2 text-sm text-gray-500">
                    Enter one of your 10-character backup codes
                  </p>
                </div>
              </>
            )}

            {/* Submit Button */}
            {(verificationMethod !== "otp" || otpSent) && (
              <div>
                <Button
                  type="submit"
                  disabled={!code || isLoading}
                  className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:bg-gray-400"
                >
                  {isLoading ? "Verifying..." : "Verify"}
                </Button>
              </div>
            )}
          </form>

          {/* Help Text */}
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-500">
              Having trouble?{" "}
              <button
                onClick={() => router.navigate({ to: "/sign-in" })}
                className="font-medium text-indigo-600 hover:text-indigo-500"
              >
                Back to sign in
              </button>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

export const Route = createFileRoute("/verify-2fa")({
  component: Verify2FA,
});
