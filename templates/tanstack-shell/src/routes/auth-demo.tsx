import { createFileRoute } from "@tanstack/react-router";
import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import {
  AlertCircle,
  CheckCircle,
  Copy,
  Key,
  LogOut,
  Plus,
  Shield,
  Trash2,
  Users,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { authClient } from "@/lib/auth-client";
import logger from "@/lib/logger";

function AuthDemo() {
  const [session, setSession] = useState<unknown>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [apiKeys, setApiKeys] = useState<Array<unknown>>([]);
  const [organizations, setOrganizations] = useState<Array<unknown>>([]);
  const [newApiKeyName, setNewApiKeyName] = useState("");
  const [newOrgName, setNewOrgName] = useState("");
  const [showApiKeyModal, setShowApiKeyModal] = useState(false);
  const [newlyCreatedApiKey, setNewlyCreatedApiKey] = useState<string>("");
  const [apiKeyLoading, setApiKeyLoading] = useState(false);
  const [orgLoading, setOrgLoading] = useState(false);
  const [deletingApiKey, setDeletingApiKey] = useState<string | null>(null);
  const [errors, setErrors] = useState<{
    apiKey?: string;
    organization?: string;
    general?: string;
  }>({});

  // Refs for focus management
  const apiKeyInputRef = useRef<HTMLInputElement>(null);
  const orgInputRef = useRef<HTMLInputElement>(null);
  const modalCloseRef = useRef<HTMLButtonElement>(null);
  const modalCopyRef = useRef<HTMLButtonElement>(null);

  const loadSession = useCallback(async () => {
    try {
      logger.info("Loading user session");
      const { data } = await authClient.getSession();
      setSession(data);

      if (data) {
        logger.info("Session loaded successfully", {
          userId: data.user.id,
          email: data.user.email,
        });
        loadApiKeys();
        loadOrganizations();
      } else {
        logger.info("No active session found");
      }
    } catch (error) {
      logger.error("Failed to load session", { error });
    } finally {
      setIsLoading(false);
    }
  }, []);

  const loadApiKeys = async () => {
    try {
      logger.debug("Loading API keys");
      const { data } = await authClient.apiKey.list();
      setApiKeys(data ?? []);
      logger.info("API keys loaded", { count: data?.length ?? 0 });
    } catch (error) {
      logger.error("Failed to load API keys", { error });
    }
  };

  const loadOrganizations = async () => {
    try {
      logger.debug("Loading organizations");
      const { data } = await authClient.organization.list();
      setOrganizations(data ?? []);
      logger.info("Organizations loaded", { count: data?.length ?? 0 });
    } catch (error) {
      logger.error("Failed to load organizations", { error });
    }
  };

  const handleSignOut = async () => {
    try {
      logger.info("Sign out initiated");
      await authClient.signOut();
      setSession(null);
      setApiKeys([]);
      setOrganizations([]);
      logger.info("Sign out successful");
    } catch (error) {
      logger.error("Sign out failed", { error });
    }
  };

  const createApiKey = async () => {
    const trimmedName = newApiKeyName.trim();
    if (!trimmedName) {
      setErrors((prev) => ({ ...prev, apiKey: "API key name is required" }));
      apiKeyInputRef.current?.focus();
      return;
    }

    setApiKeyLoading(true);
    setErrors((prev) => ({ ...prev, apiKey: undefined }));

    try {
      logger.info("Creating API key", { name: trimmedName });
      const result = await authClient.apiKey.create({
        body: {
          name: trimmedName,
          permissions: {
            files: ["read"],
            users: ["read"],
          },
        },
      });
      logger.info("API Key created successfully", { name: trimmedName });

      if (result.data?.key) {
        setNewlyCreatedApiKey(result.data.key);
        setShowApiKeyModal(true);
        toast.success("API key created successfully!", {
          description: `Key "${trimmedName}" is ready to use`,
        });
      }

      setNewApiKeyName("");
      await loadApiKeys();
    } catch (error) {
      logger.error("Failed to create API key", { name: trimmedName, error });
      const errorMessage = error?.message ?? "Unknown error occurred";
      setErrors((prev) => ({ ...prev, apiKey: errorMessage }));
      toast.error("Failed to create API key", {
        description: errorMessage,
      });
    } finally {
      setApiKeyLoading(false);
    }
  };

  const copyApiKey = async () => {
    try {
      await navigator.clipboard.writeText(newlyCreatedApiKey);
      toast.success("API key copied to clipboard!");
    } catch {
      // Fallback for browsers that don't support clipboard API
      const textArea = document.createElement("textarea");
      textArea.value = newlyCreatedApiKey;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand("copy");
      document.body.removeChild(textArea);
      toast.success("API key copied to clipboard!");
    }
  };

  const closeApiKeyModal = () => {
    setShowApiKeyModal(false);
    setNewlyCreatedApiKey("");
  };

  const createOrganization = async () => {
    const trimmedName = newOrgName.trim();
    if (!trimmedName) {
      setErrors((prev) => ({
        ...prev,
        organization: "Organization name is required",
      }));
      orgInputRef.current?.focus();
      return;
    }

    setOrgLoading(true);
    setErrors((prev) => ({ ...prev, organization: undefined }));

    try {
      const slug = trimmedName.toLowerCase().replace(/\s+/g, "-");
      logger.info("Creating organization", { name: trimmedName, slug });
      await authClient.organization.create({
        name: trimmedName,
        slug,
      });
      logger.info("Organization created successfully", {
        name: trimmedName,
        slug,
      });
      setNewOrgName("");
      toast.success("Organization created successfully!", {
        description: `"${trimmedName}" is ready to use`,
      });
      await loadOrganizations();
    } catch (error) {
      logger.error("Failed to create organization", {
        name: trimmedName,
        error,
      });
      const errorMessage = error?.message ?? "Unknown error occurred";
      setErrors((prev) => ({ ...prev, organization: errorMessage }));
      toast.error("Failed to create organization", {
        description: errorMessage,
      });
    } finally {
      setOrgLoading(false);
    }
  };

  const deleteApiKey = async (keyId: string, keyName: string) => {
    if (
      !confirm(
        `Are you sure you want to delete the API key "${keyName}"? This action cannot be undone.`,
      )
    ) {
      return;
    }

    setDeletingApiKey(keyId);

    try {
      logger.info("Deleting API key", { keyId, keyName });
      await authClient.apiKey.delete({ keyId });
      logger.info("API key deleted successfully", { keyId, keyName });
      toast.success("API key deleted successfully", {
        description: `"${keyName}" has been removed`,
      });
      await loadApiKeys();
    } catch (error) {
      logger.error("Failed to delete API key", { keyId, keyName, error });
      const errorMessage = error?.message ?? "Unknown error occurred";
      toast.error("Failed to delete API key", {
        description: errorMessage,
      });
    } finally {
      setDeletingApiKey(null);
    }
  };

  useEffect(() => {
    loadSession();
  }, [loadSession]);

  // Enhanced modal focus management and keyboard handling
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape" && showApiKeyModal) {
        closeApiKeyModal();
      }
    };

    if (showApiKeyModal) {
      document.addEventListener("keydown", handleEscape);
      document.body.style.overflow = "hidden";
      // Focus the copy button when modal opens
      setTimeout(() => {
        modalCopyRef.current?.focus();
      }, 100);
    } else {
      document.body.style.overflow = "unset";
    }

    return () => {
      document.removeEventListener("keydown", handleEscape);
      document.body.style.overflow = "unset";
    };
  }, [showApiKeyModal]);

  // Handle form submissions with Enter key
  const handleApiKeyKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !apiKeyLoading) {
      e.preventDefault();
      createApiKey();
    }
  };

  const handleOrgKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !orgLoading) {
      e.preventDefault();
      createOrganization();
    }
  };

  if (isLoading) {
    return (
      <div
        className="flex items-center justify-center min-h-screen"
        role="status"
        aria-live="polite"
      >
        <div className="text-center space-y-4">
          <div
            className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"
            aria-hidden="true"
          />
          <div className="text-lg font-medium text-foreground">
            Loading authentication demo...
          </div>
          <div className="text-sm text-muted-foreground">
            Please wait while we fetch your session data
          </div>
        </div>
      </div>
    );
  }

  if (!session) {
    return (
      <div
        className="flex items-center justify-center min-h-screen"
        role="main"
        aria-labelledby="auth-required-title"
      >
        <Card className="w-full max-w-md mx-4">
          <CardHeader className="text-center">
            <div className="mx-auto mb-4 w-12 h-12 rounded-full bg-muted flex items-center justify-center">
              <Shield
                className="h-6 w-6 text-muted-foreground"
                aria-hidden="true"
              />
            </div>
            <CardTitle
              id="auth-required-title"
              className="text-2xl"
            >
              Authentication Required
            </CardTitle>
            <CardDescription>
              Please sign in to access the Better Auth demo features
            </CardDescription>
          </CardHeader>
          <CardContent className="text-center">
            <Button
              onClick={() => (window.location.href = "/sign-in")}
              className="w-full"
              aria-describedby="signin-help"
            >
              Go to Sign In
            </Button>
            <p
              id="signin-help"
              className="text-xs text-muted-foreground mt-2"
            >
              You'll be redirected to the sign-in page
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <main
      className="container mx-auto py-8 space-y-8"
      role="main"
    >
      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-foreground">
            Better Auth Demo
          </h1>
          <p className="text-muted-foreground mt-1">
            Explore authentication features and manage your API keys
          </p>
        </div>
        <Button
          onClick={handleSignOut}
          variant="outline"
          aria-label="Sign out of your account"
        >
          <LogOut
            className="h-4 w-4 mr-2"
            aria-hidden="true"
          />
          Sign Out
        </Button>
      </header>

      {errors.general && (
        <div
          className="bg-destructive/10 border border-destructive/20 text-destructive rounded-lg p-4 flex items-start space-x-3"
          role="alert"
          aria-live="polite"
        >
          <AlertCircle
            className="h-5 w-5 mt-0.5 flex-shrink-0"
            aria-hidden="true"
          />
          <div>
            <h3 className="font-medium">Error</h3>
            <p className="text-sm mt-1">{errors.general}</p>
          </div>
        </div>
      )}

      {/* User Info */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Users
              className="h-5 w-5"
              aria-hidden="true"
            />
            <span>User Session</span>
          </CardTitle>
          <CardDescription>
            Current user information and session details
          </CardDescription>
        </CardHeader>
        <CardContent>
          <dl className="space-y-3">
            <div className="flex flex-col sm:flex-row sm:justify-between">
              <dt className="font-medium text-foreground">Name:</dt>
              <dd className="text-muted-foreground">
                {session.user?.name ?? "N/A"}
              </dd>
            </div>
            <div className="flex flex-col sm:flex-row sm:justify-between">
              <dt className="font-medium text-foreground">Email:</dt>
              <dd className="text-muted-foreground break-all">
                {session.user?.email}
              </dd>
            </div>
            <div className="flex flex-col sm:flex-row sm:justify-between">
              <dt className="font-medium text-foreground">Role:</dt>
              <dd className="text-muted-foreground">
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-accent text-accent-foreground">
                  {session.user?.role ?? "user"}
                </span>
              </dd>
            </div>
            <div className="flex flex-col sm:flex-row sm:justify-between">
              <dt className="font-medium text-foreground">Session ID:</dt>
              <dd className="text-muted-foreground font-mono text-sm break-all">
                {session.session?.id}
              </dd>
            </div>
          </dl>
        </CardContent>
      </Card>

      {/* API Keys Section */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Key
              className="h-5 w-5"
              aria-hidden="true"
            />
            <span>API Keys</span>
          </CardTitle>
          <CardDescription>
            Create and manage API keys for accessing your account
            programmatically
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <label
              htmlFor="api-key-name"
              className="text-sm font-medium text-foreground"
            >
              Create New API Key
            </label>
            <div className="flex gap-2">
              <div className="flex-1 space-y-1">
                <Input
                  id="api-key-name"
                  ref={apiKeyInputRef}
                  placeholder="Enter API key name (e.g., 'Production App')"
                  value={newApiKeyName}
                  onChange={(e) => setNewApiKeyName(e.target.value)}
                  onKeyDown={handleApiKeyKeyDown}
                  aria-describedby={
                    errors.apiKey ? "api-key-error" : "api-key-help"
                  }
                  aria-invalid={!!errors.apiKey}
                  disabled={apiKeyLoading}
                />
                {errors.apiKey && (
                  <p
                    id="api-key-error"
                    className="text-sm text-destructive"
                    role="alert"
                  >
                    {errors.apiKey}
                  </p>
                )}
                {!errors.apiKey && (
                  <p
                    id="api-key-help"
                    className="text-xs text-muted-foreground"
                  >
                    Choose a descriptive name to identify this key
                  </p>
                )}
              </div>
              <Button
                onClick={createApiKey}
                disabled={apiKeyLoading || !newApiKeyName.trim()}
                aria-describedby="create-key-status"
              >
                {apiKeyLoading ? (
                  <>
                    <div
                      className="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"
                      aria-hidden="true"
                    />
                    <span>Creating...</span>
                  </>
                ) : (
                  <>
                    <Plus
                      className="h-4 w-4 mr-2"
                      aria-hidden="true"
                    />
                    <span>Create API Key</span>
                  </>
                )}
              </Button>
            </div>
            {apiKeyLoading && (
              <div
                id="create-key-status"
                className="sr-only"
                aria-live="polite"
              >
                Creating API key, please wait
              </div>
            )}
          </div>

          <div className="space-y-2">
            <h3 className="text-sm font-medium text-foreground">
              Existing API Keys
            </h3>
            {apiKeys.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                <Key
                  className="h-12 w-12 mx-auto mb-4 opacity-50"
                  aria-hidden="true"
                />
                <p>No API keys created yet</p>
                <p className="text-xs mt-1">
                  Create your first API key to get started
                </p>
              </div>
            ) : (
              <div
                className="space-y-2"
                role="list"
                aria-label="API Keys"
              >
                {apiKeys.map((key) => (
                  <div
                    key={key.id}
                    className="flex justify-between items-center p-4 border rounded-lg hover:bg-muted/50 transition-colors"
                    role="listitem"
                  >
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-foreground truncate">
                        {key.name}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        Created: {new Date(key.createdAt).toLocaleDateString()}
                      </p>
                    </div>
                    <Button
                      onClick={() => deleteApiKey(key.id, key.name)}
                      variant="destructive"
                      size="sm"
                      disabled={deletingApiKey === key.id}
                      aria-label={`Delete API key: ${key.name}`}
                    >
                      {deletingApiKey === key.id ? (
                        <>
                          <div
                            className="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"
                            aria-hidden="true"
                          />
                          <span>Deleting...</span>
                        </>
                      ) : (
                        <>
                          <Trash2
                            className="h-4 w-4 mr-2"
                            aria-hidden="true"
                          />
                          <span>Delete</span>
                        </>
                      )}
                    </Button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Organizations Section */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Users
              className="h-5 w-5"
              aria-hidden="true"
            />
            <span>Organizations</span>
          </CardTitle>
          <CardDescription>
            Create and manage organizations for team collaboration
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <label
              htmlFor="org-name"
              className="text-sm font-medium text-foreground"
            >
              Create New Organization
            </label>
            <div className="flex gap-2">
              <div className="flex-1 space-y-1">
                <Input
                  id="org-name"
                  ref={orgInputRef}
                  placeholder="Enter organization name (e.g., 'My Company')"
                  value={newOrgName}
                  onChange={(e) => setNewOrgName(e.target.value)}
                  onKeyDown={handleOrgKeyDown}
                  aria-describedby={
                    errors.organization ? "org-error" : "org-help"
                  }
                  aria-invalid={!!errors.organization}
                  disabled={orgLoading}
                />
                {errors.organization && (
                  <p
                    id="org-error"
                    className="text-sm text-destructive"
                    role="alert"
                  >
                    {errors.organization}
                  </p>
                )}
                {!errors.organization && (
                  <p
                    id="org-help"
                    className="text-xs text-muted-foreground"
                  >
                    Organization slug will be auto-generated
                  </p>
                )}
              </div>
              <Button
                onClick={createOrganization}
                disabled={orgLoading || !newOrgName.trim()}
                aria-describedby="create-org-status"
              >
                {orgLoading ? (
                  <>
                    <div
                      className="animate-spin rounded-full h-4 w-4 border-b-2 border-current mr-2"
                      aria-hidden="true"
                    />
                    <span>Creating...</span>
                  </>
                ) : (
                  <>
                    <Plus
                      className="h-4 w-4 mr-2"
                      aria-hidden="true"
                    />
                    <span>Create Organization</span>
                  </>
                )}
              </Button>
            </div>
            {orgLoading && (
              <div
                id="create-org-status"
                className="sr-only"
                aria-live="polite"
              >
                Creating organization, please wait
              </div>
            )}
          </div>

          <div className="space-y-2">
            <h3 className="text-sm font-medium text-foreground">
              Your Organizations
            </h3>
            {organizations.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                <Users
                  className="h-12 w-12 mx-auto mb-4 opacity-50"
                  aria-hidden="true"
                />
                <p>No organizations created yet</p>
                <p className="text-xs mt-1">
                  Create your first organization to collaborate with your team
                </p>
              </div>
            ) : (
              <div
                className="space-y-2"
                role="list"
                aria-label="Organizations"
              >
                {organizations.map((org) => (
                  <div
                    key={org.id}
                    className="p-4 border rounded-lg hover:bg-muted/50 transition-colors"
                    role="listitem"
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-medium text-foreground">
                          {org.name}
                        </p>
                        <p className="text-sm text-muted-foreground">
                          Slug:{" "}
                          <code className="bg-muted px-1 rounded">
                            {org.slug}
                          </code>
                        </p>
                      </div>
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-accent text-accent-foreground">
                        Active
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* MCP Info */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <CheckCircle
              className="h-5 w-5 text-accent-foreground"
              aria-hidden="true"
            />
            <span>MCP Integration</span>
          </CardTitle>
          <CardDescription>
            Model Context Protocol configuration and status
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="bg-muted border rounded-lg p-4">
            <div className="flex items-start space-x-3">
              <CheckCircle
                className="h-5 w-5 text-muted-foreground mt-0.5 flex-shrink-0"
                aria-hidden="true"
              />
              <div>
                <h3 className="text-sm font-medium text-foreground">
                  MCP Ready
                </h3>
                <p className="text-sm text-muted-foreground mt-1">
                  Model Context Protocol is configured and ready. The auth
                  system will handle OAuth flows for MCP clients automatically.
                </p>
              </div>
            </div>
          </div>
          <div className="text-sm">
            <span className="font-medium text-foreground">Login endpoint:</span>{" "}
            <code className="bg-muted px-2 py-1 rounded text-muted-foreground">
              /sign-in
            </code>
          </div>
        </CardContent>
      </Card>

      {/* Admin Features */}
      {session.user?.role === "admin" && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Shield
                className="h-5 w-5 text-accent-foreground"
                aria-hidden="true"
              />
              <span>Admin Features</span>
            </CardTitle>
            <CardDescription>
              Administrative capabilities for system management
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="bg-muted border rounded-lg p-4 mb-4">
              <div className="flex items-start space-x-3">
                <Shield
                  className="h-5 w-5 text-muted-foreground mt-0.5 flex-shrink-0"
                  aria-hidden="true"
                />
                <div>
                  <h3 className="text-sm font-medium text-foreground">
                    Administrator Access
                  </h3>
                  <p className="text-sm text-muted-foreground mt-1">
                    You have elevated privileges for system administration.
                  </p>
                </div>
              </div>
            </div>
            <div className="space-y-2">
              <h3 className="text-sm font-medium text-foreground mb-3">
                Available Features:
              </h3>
              <ul
                className="space-y-2 text-sm text-muted-foreground"
                role="list"
              >
                <li className="flex items-center space-x-2">
                  <CheckCircle
                    className="h-4 w-4 text-accent-foreground flex-shrink-0"
                    aria-hidden="true"
                  />
                  <span>User role management</span>
                </li>
                <li className="flex items-center space-x-2">
                  <CheckCircle
                    className="h-4 w-4 text-accent-foreground flex-shrink-0"
                    aria-hidden="true"
                  />
                  <span>Session management</span>
                </li>
                <li className="flex items-center space-x-2">
                  <CheckCircle
                    className="h-4 w-4 text-accent-foreground flex-shrink-0"
                    aria-hidden="true"
                  />
                  <span>User banning/unbanning</span>
                </li>
                <li className="flex items-center space-x-2">
                  <CheckCircle
                    className="h-4 w-4 text-accent-foreground flex-shrink-0"
                    aria-hidden="true"
                  />
                  <span>System administration</span>
                </li>
              </ul>
            </div>
          </CardContent>
        </Card>
      )}

      {/* API Key Modal */}
      {showApiKeyModal && (
        <div
          className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50"
          onClick={closeApiKeyModal}
          role="dialog"
          aria-modal="true"
          aria-labelledby="modal-title"
          aria-describedby="modal-description"
        >
          <Card
            className="max-w-md w-full mx-4 shadow-lg"
            onClick={(e) => e.stopPropagation()}
          >
            <CardHeader>
              <CardTitle
                id="modal-title"
                className="flex items-center space-x-2"
              >
                <CheckCircle
                  className="h-5 w-5 text-accent-foreground"
                  aria-hidden="true"
                />
                <span>API Key Created Successfully!</span>
              </CardTitle>
              <CardDescription id="modal-description">
                Your API key has been created. <strong>Copy it now</strong> -
                you won't be able to see it again for security reasons.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="bg-muted border rounded-lg p-3">
                <label
                  htmlFor="generated-key"
                  className="sr-only"
                >
                  Generated API Key
                </label>
                <code
                  id="generated-key"
                  className="text-sm font-mono break-all text-foreground block"
                  aria-label="Generated API key value"
                >
                  {newlyCreatedApiKey}
                </code>
              </div>

              <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-3">
                <div className="flex items-start space-x-2">
                  <AlertCircle
                    className="h-4 w-4 text-destructive mt-0.5 flex-shrink-0"
                    aria-hidden="true"
                  />
                  <p className="text-xs text-destructive">
                    <strong>Security Warning:</strong> Make sure to copy this
                    key now. You will not be able to see it again for security
                    reasons.
                  </p>
                </div>
              </div>

              <div className="flex gap-2">
                <Button
                  ref={modalCopyRef}
                  onClick={copyApiKey}
                  className="flex-1"
                  aria-describedby="copy-help"
                >
                  <Copy
                    className="h-4 w-4 mr-2"
                    aria-hidden="true"
                  />
                  Copy to Clipboard
                </Button>
                <Button
                  ref={modalCloseRef}
                  onClick={closeApiKeyModal}
                  variant="outline"
                  className="flex-1"
                >
                  Close
                </Button>
              </div>
              <p
                id="copy-help"
                className="text-xs text-muted-foreground text-center"
              >
                Use Ctrl+C (or Cmd+C on Mac) after clicking Copy
              </p>
            </CardContent>
          </Card>
        </div>
      )}
    </main>
  );
}

export const Route = createFileRoute("/auth-demo")({
  component: AuthDemo,
});
