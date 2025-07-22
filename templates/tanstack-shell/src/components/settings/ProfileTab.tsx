import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import {
  AlertCircle,
  CheckCircle,
  Copy,
  Key,
  Plus,
  Shield,
  Trash2,
  Users,
} from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "../ui/card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { Textarea } from "../ui/textarea";
import { Separator } from "../ui/separator";
import { Avatar, AvatarFallback, AvatarImage } from "../ui/avatar";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../ui/select";
import { authClient } from "../../lib/auth-client";
import logger from "../../lib/logger";
import type { UserProfile } from "./types";

interface ProfileTabProps {
  profile: UserProfile;
  setProfile: React.Dispatch<React.SetStateAction<UserProfile>>;
}

export function ProfileTab({ profile, setProfile }: ProfileTabProps) {
  const [isLoading, setIsLoading] = useState(false);

  // Auth demo state
  const [session, setSession] = useState<unknown>(null);
  const [isAuthLoading, setIsAuthLoading] = useState(true);
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

  const handleProfileSave = async () => {
    setIsLoading(true);
    try {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      toast.success("Profile updated successfully!");
    } catch {
      toast.error("Failed to update profile. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

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
      setIsAuthLoading(false);
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

  useEffect(() => {
    loadSession();
  }, [loadSession]);

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>Profile Information</CardTitle>
          <CardDescription>
            Update your personal information and profile details
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center space-x-4">
            <Avatar className="h-20 w-20">
              <AvatarImage
                src={profile.avatar}
                alt={`${profile.firstName} ${profile.lastName}`}
              />
              <AvatarFallback className="text-lg">
                {profile.firstName[0]}
                {profile.lastName[0]}
              </AvatarFallback>
            </Avatar>
            <div>
              <Button
                variant="outline"
                size="sm"
              >
                Change Photo
              </Button>
              <p className="text-sm text-gray-500 mt-1">
                JPG, PNG, or GIF (max 5MB)
              </p>
            </div>
          </div>

          <Separator />

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="firstName">First Name</Label>
              <Input
                id="firstName"
                value={profile.firstName}
                onChange={(e) =>
                  setProfile((prev) => ({
                    ...prev,
                    firstName: e.target.value,
                  }))
                }
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="lastName">Last Name</Label>
              <Input
                id="lastName"
                value={profile.lastName}
                onChange={(e) =>
                  setProfile((prev) => ({
                    ...prev,
                    lastName: e.target.value,
                  }))
                }
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              value={profile.email}
              onChange={(e) =>
                setProfile((prev) => ({ ...prev, email: e.target.value }))
              }
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="phone">Phone</Label>
            <Input
              id="phone"
              value={profile.phone}
              onChange={(e) =>
                setProfile((prev) => ({ ...prev, phone: e.target.value }))
              }
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="bio">Bio</Label>
            <Textarea
              id="bio"
              rows={3}
              value={profile.bio}
              onChange={(e) =>
                setProfile((prev) => ({ ...prev, bio: e.target.value }))
              }
              placeholder="Tell us a bit about yourself..."
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="company">Company</Label>
              <Input
                id="company"
                value={profile.company}
                onChange={(e) =>
                  setProfile((prev) => ({
                    ...prev,
                    company: e.target.value,
                  }))
                }
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="website">Website</Label>
              <Input
                id="website"
                value={profile.website}
                onChange={(e) =>
                  setProfile((prev) => ({
                    ...prev,
                    website: e.target.value,
                  }))
                }
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="location">Location</Label>
              <Input
                id="location"
                value={profile.location}
                onChange={(e) =>
                  setProfile((prev) => ({
                    ...prev,
                    location: e.target.value,
                  }))
                }
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="timezone">Timezone</Label>
              <Select
                value={profile.timezone}
                onValueChange={(value) =>
                  setProfile((prev) => ({ ...prev, timezone: value }))
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select timezone" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="America/Los_Angeles">
                    Pacific Time (PT)
                  </SelectItem>
                  <SelectItem value="America/Denver">
                    Mountain Time (MT)
                  </SelectItem>
                  <SelectItem value="America/Chicago">
                    Central Time (CT)
                  </SelectItem>
                  <SelectItem value="America/New_York">
                    Eastern Time (ET)
                  </SelectItem>
                  <SelectItem value="Europe/London">London (GMT)</SelectItem>
                  <SelectItem value="Europe/Berlin">Berlin (CET)</SelectItem>
                  <SelectItem value="Asia/Tokyo">Tokyo (JST)</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex justify-end space-x-2">
            <Button variant="outline">Cancel</Button>
            <Button
              onClick={handleProfileSave}
              disabled={isLoading}
            >
              {isLoading ? "Saving..." : "Save Changes"}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Authentication Demo Section */}
      {!isAuthLoading && session && (
        <>
          <Separator className="my-8" />

          <div className="space-y-6">
            <div>
              <h2 className="text-xl font-semibold text-foreground">
                Authentication Demo
              </h2>
              <p className="text-muted-foreground mt-1">
                Manage your authentication features and API keys
              </p>
            </div>

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
                  <Label
                    htmlFor="api-key-name"
                    className="text-sm font-medium text-foreground"
                  >
                    Create New API Key
                  </Label>
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
                              Created:{" "}
                              {new Date(key.createdAt).toLocaleDateString()}
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
                  <Label
                    htmlFor="org-name"
                    className="text-sm font-medium text-foreground"
                  >
                    Create New Organization
                  </Label>
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
                        Create your first organization to collaborate with your
                        team
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
                        system will handle OAuth flows for MCP clients
                        automatically.
                      </p>
                    </div>
                  </div>
                </div>
                <div className="text-sm">
                  <span className="font-medium text-foreground">
                    Login endpoint:
                  </span>{" "}
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
                          You have elevated privileges for system
                          administration.
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
          </div>
        </>
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
                <Label
                  htmlFor="generated-key"
                  className="sr-only"
                >
                  Generated API Key
                </Label>
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
    </>
  );
}
