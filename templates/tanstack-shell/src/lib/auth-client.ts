/**
 * Better Auth Client Configuration
 *
 * This module configures the client-side Better Auth instance for handling
 * authentication operations in the frontend application.
 */

// Better Auth client imports
import { createAuthClient } from "better-auth/client";
import {
  adminClient,
  apiKeyClient,
  multiSessionClient,
  organizationClient,
  twoFactorClient,
} from "better-auth/client/plugins";

/**
 * Configured Better Auth client instance
 *
 * Provides client-side authentication methods including:
 * - Sign up/sign in with email and password
 * - Password reset functionality (requestPasswordReset, resetPassword)
 * - Organization management for multi-tenant applications
 * - API key authentication for programmatic access
 * - Admin functionality for user management
 *
 * Usage Examples:
 * ```typescript
 * // Request password reset
 * await authClient.requestPasswordReset({
 *   email: 'user@example.com',
 *   redirectTo: '/reset-password'
 * });
 *
 * // Complete password reset
 * await authClient.resetPassword({
 *   newPassword: 'newSecurePassword',
 *   token: 'reset-token-from-email'
 * });
 *
 * // Sign in user
 * await authClient.signIn({
 *   email: 'user@example.com',
 *   password: 'userPassword'
 * });
 * ```
 *
 * @constant
 */
export const authClient = createAuthClient({
  // Base URL for authentication API - must match server configuration
  // CRITICAL: Mismatched URLs between client and server cause infinite redirects
  baseURL: process.env.BETTER_AUTH_URL ?? "http://localhost:3000",

  // Client-side plugins for extended functionality
  plugins: [
    /**
     * Organization Client Plugin
     * Provides client-side methods for multi-tenant organization management
     *
     * Features:
     * - Create, update, and delete organizations
     * - Manage organization memberships and roles
     * - Switch between organizations in the UI
     * - Organization-scoped data access
     *
     * @see https://better-auth.com/docs/plugins/organization for usage examples
     */
    organizationClient(),

    /**
     * Admin Client Plugin
     * Provides client-side administrative functions for user management
     *
     * Features:
     * - List and manage users (admin-only operations)
     * - Update user roles and permissions
     * - Disable/enable user accounts
     * - Audit user activities
     *
     * @see https://better-auth.com/docs/plugins/admin for administrative operations
     */
    adminClient(),

    /**
     * API Key Client Plugin
     * Enables programmatic access through API keys
     *
     * Features:
     * - Generate API keys for programmatic access
     * - Manage API key permissions and scopes
     * - Revoke and rotate API keys
     * - API key-based authentication for services
     *
     * @see https://better-auth.com/docs/plugins/api-key for API integration patterns
     */
    apiKeyClient(),

    /**
     * Multi-Session Client Plugin
     * Provides client-side methods for managing multiple user sessions
     *
     * This plugin works in conjunction with the server-side multiSession plugin
     * to enable comprehensive session management across devices.
     *
     * FEATURES:
     * - List all active sessions with device information
     * - Switch between sessions (useful for account switching)
     * - Revoke individual sessions remotely
     * - Device fingerprinting and session metadata
     *
     * OAUTH PROXY INTEGRATION:
     * When using OAuth Proxy for development, each OAuth sign-in creates a new session.
     * The multi-session plugin helps manage these sessions effectively:
     *
     * 1. OAuth sign-in via proxy creates a new session
     * 2. User can see all active sessions (including OAuth ones)
     * 3. Sessions can be managed (revoked, switched) from any device
     * 4. Device detection shows which sessions are from development vs production
     *
     * SECURITY CONSIDERATIONS:
     * - Each session has its own tokens and security context
     * - Revoking a session immediately invalidates its tokens
     * - Session switching doesn't require re-authentication
     * - Device fingerprinting helps identify suspicious sessions
     *
     * USAGE EXAMPLES:
     * ```typescript
     * // List all sessions for current user
     * const sessions = await authClient.multiSession.listDeviceSessions();
     *
     * // Switch to a different session
     * await authClient.multiSession.switchSession(sessionId);
     *
     * // Revoke a specific session
     * await authClient.multiSession.revokeSession(sessionId);
     *
     * // Revoke all other sessions (keep current)
     * await authClient.multiSession.revokeOtherSessions();
     * ```
     *
     * @see /better-auth/multi-session for detailed documentation
     * @see https://better-auth.com/docs/plugins/multi-session for official plugin docs
     * @see Settings page implementation for UI examples
     */
    multiSessionClient(),

    /**
     * Two-Factor Authentication Client Plugin
     * Provides client-side methods for managing 2FA authentication
     *
     * This plugin works in conjunction with the server-side twoFactor plugin
     * to provide comprehensive two-factor authentication functionality.
     *
     * FEATURES:
     * - Enable/disable 2FA with password verification
     * - Generate and verify TOTP codes with authenticator apps
     * - Send and verify email-based OTP codes
     * - Generate and manage backup codes for account recovery
     * - Trusted device management (60-day trust period)
     * - QR code generation for authenticator app setup
     *
     * TOTP WORKFLOW:
     * 1. Enable 2FA: authClient.twoFactor.enable({ password })
     * 2. Get QR code: authClient.twoFactor.getTotpUri({ password })
     * 3. User scans QR code with authenticator app
     * 4. Verify setup: authClient.twoFactor.verifyTotp({ code })
     * 5. 2FA is now active for the user account
     *
     * SIGN-IN WITH 2FA:
     * 1. Normal sign-in returns twoFactorRedirect: true
     * 2. User redirected to 2FA verification page
     * 3. Verify with TOTP: authClient.twoFactor.verifyTotp({ code, trustDevice })
     * 4. Or verify with backup: authClient.twoFactor.verifyBackupCode({ code })
     * 5. User successfully authenticated
     *
     * EMAIL OTP WORKFLOW:
     * 1. Send OTP: authClient.twoFactor.sendOtp()
     * 2. User receives email with 6-digit code
     * 3. Verify OTP: authClient.twoFactor.verifyOtp({ code })
     * 4. User authenticated (alternative to TOTP)
     *
     * BACKUP CODES:
     * - Generated automatically when enabling 2FA
     * - Use: authClient.twoFactor.verifyBackupCode({ code })
     * - Regenerate: authClient.twoFactor.generateBackupCodes({ password })
     * - Each code can only be used once
     *
     * TRUSTED DEVICES:
     * - Mark device as trusted during verification
     * - Skip 2FA for 60 days on trusted devices
     * - Trust period refreshes on each successful sign-in
     *
     * 2FA REDIRECT HANDLING:
     * - onTwoFactorRedirect callback for global handling
     * - Redirects user to 2FA verification page when needed
     * - Can be customized per-application requirements
     *
     * USAGE EXAMPLES:
     * ```typescript
     * // Enable 2FA
     * const result = await authClient.twoFactor.enable({
     *   password: "user-password",
     *   issuer: "My App" // optional
     * });
     *
     * // Get QR code for setup
     * const qrData = await authClient.twoFactor.getTotpUri({
     *   password: "user-password"
     * });
     *
     * // Verify TOTP code
     * await authClient.twoFactor.verifyTotp({
     *   code: "123456",
     *   trustDevice: true,
     *   callbackURL: "/dashboard"
     * });
     *
     * // Generate new backup codes
     * const backupCodes = await authClient.twoFactor.generateBackupCodes({
     *   password: "user-password"
     * });
     *
     * // Disable 2FA
     * await authClient.twoFactor.disable({
     *   password: "user-password"
     * });
     * ```
     *
     * @see https://better-auth.com/docs/plugins/2fa for comprehensive documentation
     * @see Settings page implementation for complete UI examples
     * @see Sign-in page for 2FA verification flow
     */
    twoFactorClient({
      // Global handler for 2FA redirect requirements
      // Called when sign-in requires 2FA verification
      onTwoFactorRedirect() {
        // Redirect to 2FA verification page
        window.location.href = "/verify-2fa";
      },
    }),
  ],
});
