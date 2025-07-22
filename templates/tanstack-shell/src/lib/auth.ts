import { LibsqlDialect } from "@libsql/kysely-libsql";
import { betterAuth } from "better-auth";
import {
  admin,
  apiKey,
  mcp,
  oAuthProxy,
  organization,
  twoFactor,
} from "better-auth/plugins";
import { reactStartCookies } from "better-auth/react-start";

import { email } from "./email";

/**
 * Database dialect configuration for LibSQL/SQLite
 * Uses environment variable for production, falls back to local file for development
 */
const dialect = new LibsqlDialect({
  url: process.env.DATABASE_URL ?? "file:./database.db",
});

/**
 * Better Auth configuration with comprehensive authentication features
 *
 * Features enabled:
 * - Email/password authentication with magic link password reset
 * - Organization management for multi-tenant support
 * - MCP (Model Context Protocol) integration
 * - API key authentication for programmatic access
 * - Admin functionality for user management
 * - React Start cookie integration for SSR
 */
export const auth = betterAuth({
  // Database connection configuration
  database: {
    dialect,
    type: "sqlite",
  },

  // Application name - used as issuer for 2FA TOTP codes
  appName: "Connix API Frontend",

  // Cryptographic secret for signing tokens and sessions
  // SECURITY: Must be a strong, random string in production
  secret:
    process.env.BETTER_AUTH_SECRET ??
    "your-super-secret-key-change-this-in-production",

  trustedOrigins: [
    // CRITICAL: Must match client configuration to prevent infinite redirects
    process.env.BETTER_AUTH_URL ?? "http://localhost:3000",
  ],

  // Base URL for the authentication service
  // CRITICAL: Must match client configuration to prevent infinite redirects
  baseURL: process.env.BETTER_AUTH_URL ?? "http://localhost:3000",

  // Social providers configuration
  // OAuth providers for social authentication
  socialProviders: {
    github: {
      clientId: process.env.GITHUB_CLIENT_ID ?? "",
      clientSecret: process.env.GITHUB_CLIENT_SECRET ?? "",
      // CRITICAL: For OAuth Proxy, this should point to production URL
      // The proxy will automatically handle redirects for development
      redirectURI: `${process.env.BETTER_AUTH_URL ?? "http://localhost:3000"}/api/auth/callback/github`,
    },
  },
  // Email and password authentication configuration
  emailAndPassword: {
    enabled: true,

    // Security: Reset tokens expire after 1 hour to limit attack window
    resetPasswordTokenExpiresIn: 3600,

    /**
     * Custom password reset email handler
     * Sends professional HTML email with fallback text version
     *
     * @param user - User object containing name and email
     * @param url - Pre-generated magic link with embedded token
     * @param token - Raw token (unused, url already contains it)
     * @param request - Original HTTP request object
     */
    sendResetPassword: async ({ user, url }) => {
      await email.emails.send({
        // Professional sender identity
        from: "Acme <onboarding@resend.dev>",
        to: user.email,
        subject: "Reset your password - Acme",

        // HTML version with inline CSS for email client compatibility
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <!-- Header with brand styling -->
            <h2 style="color: #333; text-align: center;">Reset Your Password</h2>
            
            <!-- Personalized greeting -->
            <p style="color: #666; font-size: 16px;">Hello ${user.name || "there"},</p>
            
            <!-- Clear explanation of the email purpose -->
            <p style="color: #666; font-size: 16px;">
              We received a request to reset your password for your Acme account. 
              Click the button below to reset your password:
            </p>
            
            <!-- Primary call-to-action button -->
            <div style="text-align: center; margin: 30px 0;">
              <a href="${url}" 
                 style="background-color: #4F46E5; color: white; padding: 12px 30px; 
                        text-decoration: none; border-radius: 6px; font-weight: bold; 
                        display: inline-block;">
                Reset Password
              </a>
            </div>
            
            <!-- Security warning for unwanted requests -->
            <p style="color: #666; font-size: 14px;">
              If you didn't request this password reset, you can safely ignore this email. 
              Your password will not be changed.
            </p>
            
            <!-- Token expiration notice for urgency -->
            <p style="color: #666; font-size: 14px;">
              This link will expire in 1 hour for security reasons.
            </p>
            
            <!-- Visual separator -->
            <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
            
            <!-- Fallback URL for accessibility -->
            <p style="color: #999; font-size: 12px; text-align: center;">
              If you're having trouble clicking the button, copy and paste this URL into your browser:<br>
              <span style="word-break: break-all;">${url}</span>
            </p>
          </div>
        `,

        // Plain text fallback for email clients that don't support HTML
        text: `Hello ${user.name || "there"},

We received a request to reset your password for your Acme account.

Click the link below to reset your password:
${url}

If you didn't request this password reset, you can safely ignore this email. Your password will not be changed.

This link will expire in 1 hour for security reasons.

Best regards,
The Acme Team`,
      });
    },
  },
  plugins: [
    organization(),
    mcp({
      loginPage: "/sign-in",
    }),
    apiKey(),
    admin(),

    /**
     * OAuth Proxy Plugin for Development and Preview Deployments
     *
     * PROBLEM SOLVED:
     * OAuth providers like GitHub require static redirect URIs configured in their dashboard.
     * In development/preview environments with dynamic URLs (localhost:3000, pr-123.vercel.app),
     * this creates a chicken-and-egg problem where you can't configure the redirect URI beforehand.
     *
     * SOLUTION:
     * The OAuth Proxy acts as a bridge:
     * 1. OAuth provider redirects to your production URL (static, pre-configured)
     * 2. Production app proxies the OAuth callback to your development URL
     * 3. Your dev environment receives the OAuth response as if it came directly from the provider
     *
     * HOW IT WORKS:
     * - Development: OAuth flows go through production proxy → dev environment
     * - Production: OAuth flows work directly (no proxy needed)
     * - Preview deploys: Each gets a unique proxy endpoint via production
     *
     * CONFIGURATION:
     * - productionURL: Your live production app URL (where OAuth providers redirect)
     * - currentURL: Current environment URL (auto-detected, but can be overridden)
     *
     * SECURITY CONSIDERATIONS:
     * - Only use in development/preview environments
     * - Production should have direct OAuth configuration
     * - Proxy adds an extra network hop, so expect slight latency
     * - All OAuth state/PKCE security measures remain intact through the proxy
     *
     * GITHUB OAUTH SETUP EXAMPLE:
     * 1. Create GitHub OAuth App with redirect URI: https://your-production-app.com/api/auth/callback/github
     * 2. Production receives GitHub callback → proxies to dev environment
     * 3. Dev environment processes OAuth response normally
     *
     * ENVIRONMENT VARIABLES REQUIRED:
     * - OAUTH_PROXY_PRODUCTION_URL: Your production app URL (where GitHub redirects)
     * - BETTER_AUTH_URL: Current environment URL (fallback for both settings)
     * - GITHUB_CLIENT_ID & GITHUB_CLIENT_SECRET: OAuth app credentials
     *
     * @see /better-auth/oauth-proxy for detailed documentation and examples
     * @see https://better-auth.com/docs/plugins/oauth-proxy for official plugin docs
     * @see GitHub OAuth setup: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps
     */
    oAuthProxy({
      // Production URL - where OAuth providers should redirect in production
      // This should be your live production app URL that's configured in OAuth provider dashboards
      productionURL:
        process.env.OAUTH_PROXY_PRODUCTION_URL ??
        process.env.BETTER_AUTH_URL ??
        "http://localhost:3000",

      // Current URL - automatically detected, but can be overridden for development
      // This is the URL of the current environment that will receive the proxied OAuth response
      currentURL: process.env.BETTER_AUTH_URL ?? "http://localhost:3000",
    }),

    /**
     * Two-Factor Authentication Plugin
     * Adds an extra layer of security with TOTP, OTP, and backup codes
     *
     * FEATURES:
     * - TOTP (Time-based One-Time Password) with authenticator apps
     * - OTP (One-Time Password) sent via email
     * - Backup codes for account recovery
     * - Trusted device management (60-day trust period)
     * - Skip verification on enable for localhost development
     *
     * SECURITY BENEFITS:
     * - Protects against password-only attacks
     * - Reduces risk of account takeover
     * - Provides recovery options if primary 2FA method is lost
     * - Device trust reduces friction for regular users
     *
     * DEVELOPMENT CONFIGURATION:
     * - skipVerificationOnEnable: true for localhost to streamline development
     * - Production should require verification before enabling 2FA
     * - Issuer set to app name for TOTP authenticator app display
     *
     * TOTP SETUP:
     * 1. User enables 2FA with password verification
     * 2. System generates secret and backup codes
     * 3. QR code displayed for authenticator app scanning
     * 4. User verifies TOTP code to activate 2FA
     * 5. Backup codes shown for safekeeping
     *
     * SIGN-IN FLOW WITH 2FA:
     * 1. User enters email/password
     * 2. If 2FA enabled, twoFactorRedirect: true returned
     * 3. User redirected to 2FA verification page
     * 4. User enters TOTP code or backup code
     * 5. Optional: mark device as trusted
     * 6. User signed in successfully
     *
     * OTP CONFIGURATION:
     * - Email-based OTP for users without authenticator apps
     * - 3-minute expiration for security
     * - Integrates with existing email service
     *
     * @see https://better-auth.com/docs/plugins/2fa for comprehensive documentation
     * @see Settings page implementation for UI examples
     */
    twoFactor({
      // Skip TOTP verification step when enabling 2FA in development
      // This streamlines the development workflow while maintaining security in production
      skipVerificationOnEnable: (
        process.env.BETTER_AUTH_URL ?? "http://localhost:3000"
      ).includes("localhost"),

      // Issuer name displayed in authenticator apps (Google Authenticator, Authy, etc.)
      issuer: "Connix",

      // TOTP configuration for authenticator apps
      totpOptions: {
        digits: 6, // Standard 6-digit codes
        period: 30, // 30-second refresh interval
      },

      // OTP configuration for email-based verification
      otpOptions: {
        period: 3, // 3-minute expiration for email OTP codes

        /**
         * Email OTP sender function
         * Integrates with the existing email service to send 2FA codes
         *
         * @param user - User object with email and name
         * @param otp - Generated OTP code (6 digits)
         * @param request - HTTP request object for context
         */
        async sendOTP({ user, otp }) {
          await email.emails.send({
            from: "Connix Security <security@connix.dev>",
            to: user.email,
            subject: "Your Two-Factor Authentication Code",

            // HTML email with security-focused styling
            html: `
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="text-align: center; margin-bottom: 30px;">
                  <h2 style="color: #1f2937; margin: 0;">Security Verification Required</h2>
                </div>
                
                <p style="color: #374151; font-size: 16px; margin-bottom: 20px;">
                  Hello ${user.name || "there"},
                </p>
                
                <p style="color: #374151; font-size: 16px; margin-bottom: 20px;">
                  Someone is trying to sign in to your Connix account. To complete the sign-in, 
                  please use the verification code below:
                </p>
                
                <div style="text-align: center; margin: 30px 0;">
                  <div style="background-color: #f3f4f6; border: 2px solid #e5e7eb; border-radius: 8px; 
                              display: inline-block; padding: 20px 40px; font-size: 32px; 
                              font-weight: bold; letter-spacing: 8px; color: #1f2937;">
                    ${otp}
                  </div>
                </div>
                
                <p style="color: #6b7280; font-size: 14px; margin-bottom: 20px;">
                  This code will expire in 3 minutes for your security.
                </p>
                
                <div style="background-color: #fef3c7; border-left: 4px solid #f59e0b; padding: 16px; margin: 20px 0;">
                  <p style="color: #92400e; font-size: 14px; margin: 0;">
                    <strong>Security Notice:</strong> If you didn't request this code, someone may be 
                    trying to access your account. Please change your password immediately and contact support.
                  </p>
                </div>
                
                <p style="color: #6b7280; font-size: 12px; text-align: center; margin-top: 30px;">
                  This is an automated security message from Connix. Do not reply to this email.
                </p>
              </div>
            `,

            // Plain text fallback
            text: `
Security Verification Required

Hello ${user.name || "there"},

Someone is trying to sign in to your Connix account. To complete the sign-in, please use this verification code: ${otp}

This code will expire in 3 minutes for your security.

Security Notice: If you didn't request this code, someone may be trying to access your account. Please change your password immediately and contact support.

This is an automated security message from Connix.
            `.trim(),
          });
        },
      },

      // Backup codes configuration for account recovery
      backupCodeOptions: {
        amount: 8, // Generate 8 backup codes
        length: 10, // Each code is 10 characters long
      },
    }),

    reactStartCookies(), // CRITICAL: Must be the last plugin in the array
  ],
});
