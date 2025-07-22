import { useState } from "react";
import QRCode from "react-qr-code";
import { toast } from "sonner";
import { logger } from "@sentry/tanstackstart-react";
import {
  AlertTriangle,
  CheckCircle,
  Copy,
  Download,
  Key,
  QrCode,
  Shield,
} from "lucide-react";
import { authClient } from "../../lib/auth-client";
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
import { Separator } from "../ui/separator";
import { Badge } from "../ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "../ui/dialog";
import type { TwoFactorStep } from "./types";

interface AccountTabProps {
  twoFactorEnabled: boolean;
  setTwoFactorEnabled: React.Dispatch<React.SetStateAction<boolean>>;
  twoFactorLoading: boolean;
  setTwoFactorLoading: React.Dispatch<React.SetStateAction<boolean>>;
  totpQrCode: string | null;
  setTotpQrCode: React.Dispatch<React.SetStateAction<string | null>>;
  backupCodes: Array<string>;
  setBackupCodes: React.Dispatch<React.SetStateAction<Array<string>>>;
  showBackupCodes: boolean;
  setShowBackupCodes: React.Dispatch<React.SetStateAction<boolean>>;
  passwordForTwoFactor: string;
  setPasswordForTwoFactor: React.Dispatch<React.SetStateAction<string>>;
  twoFactorStep: TwoFactorStep;
  setTwoFactorStep: React.Dispatch<React.SetStateAction<TwoFactorStep>>;
  totpCode: string;
  setTotpCode: React.Dispatch<React.SetStateAction<string>>;
}

export function AccountTab({
  twoFactorEnabled,
  setTwoFactorEnabled,
  twoFactorLoading,
  setTwoFactorLoading,
  totpQrCode,
  setTotpQrCode,
  backupCodes,
  setBackupCodes,
  showBackupCodes,
  setShowBackupCodes,
  passwordForTwoFactor,
  setPasswordForTwoFactor,
  twoFactorStep,
  setTwoFactorStep,
  totpCode,
  setTotpCode,
}: AccountTabProps) {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [confirmDisableOpen, setConfirmDisableOpen] = useState(false);

  const handleEnable2FA = async () => {
    if (!passwordForTwoFactor) {
      toast.error("Please enter your password to enable 2FA");
      return;
    }

    setTwoFactorLoading(true);
    try {
      const result = await authClient.twoFactor.enable({
        password: passwordForTwoFactor,
        issuer: "Connix API Frontend",
      });

      if (result.error) {
        toast.error(result.error.message ?? "Failed to enable 2FA");
        setTwoFactorLoading(false);
        return;
      }
      setBackupCodes(result.data.backupCodes);
      setTwoFactorStep("qr");
      setDialogOpen(true);
      toast.success("2FA setup initiated! Please scan the QR code.");
      await handleGetQrCode();
    } catch (error) {
      logger.error("Error enabling 2FA:", error);
      toast.error("An unexpected error occurred while enabling 2FA");
    } finally {
      setTwoFactorLoading(false);
    }
  };

  const handleGetQrCode = async () => {
    try {
      const result = await authClient.twoFactor.getTotpUri({
        password: passwordForTwoFactor,
      });

      if (result.error) {
        toast.error(result.error.message ?? "Failed to get QR code");
        return;
      }

      if (result.data.totpURI) {
        setTotpQrCode(result.data.totpURI);
      }
    } catch (error) {
      logger.error("Error getting QR code:", error);
      toast.error("Failed to generate QR code");
    }
  };

  const handleVerifyTotp = async () => {
    if (!totpCode || totpCode.length !== 6) {
      toast.error("Please enter a valid 6-digit code");
      return;
    }

    setTwoFactorLoading(true);
    try {
      const result = await authClient.twoFactor.verifyTotp({
        code: totpCode,
      });

      if (result.error) {
        toast.error(result.error.message ?? "Invalid verification code");
        setTwoFactorLoading(false);
        return;
      }

      setTwoFactorEnabled(true);
      setTwoFactorStep("backup");
      toast.success("2FA enabled successfully!");
    } catch (error) {
      logger.error("Error verifying TOTP:", error);
      toast.error("An unexpected error occurred during verification");
    } finally {
      setTwoFactorLoading(false);
    }
  };

  const handleDisable2FA = () => {
    if (!passwordForTwoFactor) {
      toast.error("Please enter your password to disable 2FA");
      return;
    }

    setConfirmDisableOpen(true);
  };

  const handleGenerateNewBackupCodes = async () => {
    if (!passwordForTwoFactor) {
      toast.error("Please enter your password to generate new backup codes");
      return;
    }

    setTwoFactorLoading(true);
    try {
      const result = await authClient.twoFactor.generateBackupCodes({
        password: passwordForTwoFactor,
      });

      if (result.error) {
        toast.error(result.error.message ?? "Failed to generate backup codes");
        setTwoFactorLoading(false);
        return;
      }

      setBackupCodes(result.data.backupCodes);
      setShowBackupCodes(true);
      toast.success("New backup codes generated successfully");
    } catch (error) {
      logger.error("Error generating backup codes:", error);
      toast.error("An unexpected error occurred while generating backup codes");
    } finally {
      setTwoFactorLoading(false);
    }
  };

  const handleCopyBackupCodes = () => {
    const codesText = backupCodes.join("\n");
    navigator.clipboard
      .writeText(codesText)
      .then(() => {
        toast.success("Backup codes copied to clipboard");
      })
      .catch(() => {
        toast.error("Failed to copy backup codes");
      });
  };

  const handleDownloadBackupCodes = () => {
    const codesText = backupCodes.join("\n");
    const blob = new Blob(
      [
        `Connix API Frontend - Backup Codes\n\nGenerated: ${new Date().toLocaleString()}\n\n${codesText}\n\nKeep these codes safe and secure. Each code can only be used once.`,
      ],
      {
        type: "text/plain",
      },
    );
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `connix-backup-codes-${new Date().toISOString().split("T")[0]}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    toast.success("Backup codes downloaded");
  };

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>Account Settings</CardTitle>
          <CardDescription>
            Manage your account security and preferences
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-4">
            <div>
              <h3 className="text-lg font-medium">Password</h3>
              <p className="text-sm text-gray-600">Last changed 3 months ago</p>
              <Button
                variant="outline"
                className="mt-2"
              >
                Change Password
              </Button>
            </div>

            <Separator />

            <div>
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <h3 className="text-lg font-medium flex items-center space-x-2">
                    <Shield className="h-5 w-5" />
                    <span>Two-Factor Authentication</span>
                  </h3>
                  <p className="text-sm text-gray-600">
                    Add an extra layer of security to your account with TOTP
                    authenticator apps
                  </p>
                </div>
                <div className="flex items-center space-x-2 ml-4">
                  <Badge variant={twoFactorEnabled ? "default" : "destructive"}>
                    {twoFactorEnabled ? "Enabled" : "Disabled"}
                  </Badge>
                  {twoFactorEnabled && (
                    <Badge
                      variant="secondary"
                      className="bg-accent text-accent-foreground"
                    >
                      <CheckCircle className="h-3 w-3 mr-1" />
                      Protected
                    </Badge>
                  )}
                </div>
              </div>

              <div className="mt-4 space-y-4">
                {!twoFactorEnabled ? (
                  <div className="space-y-4">
                    {twoFactorStep === "setup" && (
                      <div className="space-y-3">
                        <div className="bg-muted border rounded-lg p-4">
                          <div className="flex items-start space-x-3">
                            <AlertTriangle className="h-5 w-5 text-muted-foreground mt-0.5" />
                            <div>
                              <h4 className="text-sm font-medium text-foreground">
                                Enable Two-Factor Authentication
                              </h4>
                              <p className="text-sm text-muted-foreground mt-1">
                                Protect your account with an authenticator app
                                like Google Authenticator, Authy, or 1Password.
                              </p>
                            </div>
                          </div>
                        </div>

                        <div className="space-y-2">
                          <Label htmlFor="password-2fa">Current Password</Label>
                          <div className="flex gap-2">
                            <Input
                              id="password-2fa"
                              type="password"
                              placeholder="Enter your current password"
                              value={passwordForTwoFactor}
                              onChange={(e) =>
                                setPasswordForTwoFactor(e.target.value)
                              }
                              disabled={twoFactorLoading}
                              className="flex-1"
                            />
                            <Button
                              onClick={handleEnable2FA}
                              disabled={
                                !passwordForTwoFactor || twoFactorLoading
                              }
                            >
                              {twoFactorLoading
                                ? "Setting up..."
                                : "Enable 2FA"}
                            </Button>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="bg-muted border rounded-lg p-4">
                      <div className="flex items-start space-x-3">
                        <CheckCircle className="h-5 w-5 text-muted-foreground mt-0.5" />
                        <div>
                          <h4 className="text-sm font-medium text-foreground">
                            Two-Factor Authentication Active
                          </h4>
                          <p className="text-sm text-muted-foreground mt-1">
                            Your account is protected with two-factor
                            authentication using TOTP.
                          </p>
                        </div>
                      </div>
                    </div>

                    <div className="space-y-3">
                      <div className="space-y-2">
                        <Label htmlFor="password-2fa-manage">
                          Current Password
                        </Label>
                        <Input
                          id="password-2fa-manage"
                          type="password"
                          placeholder="Enter your current password"
                          value={passwordForTwoFactor}
                          onChange={(e) =>
                            setPasswordForTwoFactor(e.target.value)
                          }
                          disabled={twoFactorLoading}
                        />
                      </div>

                      <div className="flex flex-col sm:flex-row gap-2">
                        <Button
                          variant="outline"
                          onClick={handleGenerateNewBackupCodes}
                          disabled={!passwordForTwoFactor || twoFactorLoading}
                          className="flex-1"
                        >
                          <Key className="h-4 w-4 mr-2" />
                          {twoFactorLoading
                            ? "Generating..."
                            : "Generate New Backup Codes"}
                        </Button>
                        <Button
                          variant="destructive"
                          onClick={handleDisable2FA}
                          disabled={!passwordForTwoFactor || twoFactorLoading}
                          className="flex-1"
                        >
                          <Shield className="h-4 w-4 mr-2" />
                          {twoFactorLoading ? "Disabling..." : "Disable 2FA"}
                        </Button>
                      </div>
                    </div>

                    {showBackupCodes && backupCodes.length > 0 && (
                      <div className="bg-gray-50 border rounded-lg p-4">
                        <h4 className="font-medium mb-3 flex items-center space-x-2">
                          <Key className="h-4 w-4" />
                          <span>New Backup Codes</span>
                        </h4>
                        <div className="grid grid-cols-2 gap-2 font-mono text-sm">
                          {backupCodes.map((code, index) => (
                            <div
                              key={index}
                              className="bg-white p-2 rounded border text-center"
                            >
                              {code}
                            </div>
                          ))}
                        </div>
                        <div className="flex space-x-2 mt-3">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={handleCopyBackupCodes}
                            className="flex-1"
                          >
                            <Copy className="h-4 w-4 mr-2" />
                            Copy
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={handleDownloadBackupCodes}
                            className="flex-1"
                          >
                            <Download className="h-4 w-4 mr-2" />
                            Download
                          </Button>
                        </div>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setShowBackupCodes(false)}
                          className="w-full mt-2"
                        >
                          Hide Codes
                        </Button>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>

            <Separator />

            <div>
              <h3 className="text-lg font-medium text-red-600">Danger Zone</h3>
              <p className="text-sm text-gray-600">
                Permanently delete your account and all data
              </p>
              <Button
                variant="destructive"
                className="mt-2"
              >
                Delete Account
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Dialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
      >
        <DialogContent
          className="sm:max-w-md"
          aria-describedby="dialog-description"
        >
          {twoFactorStep === "qr" && totpQrCode && (
            <>
              <DialogHeader>
                <DialogTitle className="flex items-center gap-2">
                  <QrCode className="h-5 w-5" />
                  Enable Two-Factor Authentication
                </DialogTitle>
                <DialogDescription id="dialog-description">
                  Scan this QR code with your authenticator app and enter the
                  verification code below.
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-4">
                <div className="flex justify-center p-6 bg-muted/30 rounded-lg border">
                  <div className="bg-white p-4 rounded">
                    <QRCode
                      value={totpQrCode}
                      size={200}
                      style={{
                        height: "auto",
                        maxWidth: "100%",
                        width: "100%",
                      }}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="totp-verification">Verification Code</Label>
                  <Input
                    id="totp-verification"
                    type="text"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    maxLength={6}
                    placeholder="123456"
                    value={totpCode}
                    onChange={(e) =>
                      setTotpCode(e.target.value.replace(/\D/g, ""))
                    }
                    disabled={twoFactorLoading}
                    className="text-center text-lg font-mono"
                    aria-label="Enter 6-digit verification code"
                  />
                  <p className="text-sm text-muted-foreground">
                    Enter the 6-digit code from your authenticator app
                  </p>
                </div>
              </div>

              <DialogFooter className="flex-col sm:flex-row gap-2">
                <Button
                  variant="outline"
                  onClick={() => {
                    setDialogOpen(false);
                    setTwoFactorStep("setup");
                    setTotpQrCode(null);
                    setTotpCode("");
                    setPasswordForTwoFactor("");
                  }}
                  disabled={twoFactorLoading}
                  className="w-full sm:w-auto"
                >
                  Cancel
                </Button>
                <Button
                  onClick={handleVerifyTotp}
                  disabled={
                    !totpCode || totpCode.length !== 6 || twoFactorLoading
                  }
                  className="w-full sm:w-auto"
                >
                  {twoFactorLoading ? "Verifying..." : "Verify & Enable"}
                </Button>
              </DialogFooter>
            </>
          )}

          {twoFactorStep === "backup" && backupCodes.length > 0 && (
            <>
              <DialogHeader>
                <DialogTitle className="flex items-center gap-2">
                  <CheckCircle className="h-5 w-5 text-green-600" />
                  2FA Enabled Successfully!
                </DialogTitle>
                <DialogDescription id="dialog-description">
                  Save these backup codes in a secure location. Each code can
                  only be used once.
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-4">
                <div className="bg-muted/50 border rounded-lg p-4">
                  <h4 className="font-medium mb-3 flex items-center gap-2">
                    <Key className="h-4 w-4" />
                    <span>Backup Codes</span>
                  </h4>
                  <div className="grid grid-cols-2 gap-2 font-mono text-sm">
                    {backupCodes.map((code, index) => (
                      <div
                        key={index}
                        className="bg-background p-2 rounded border text-center"
                      >
                        {code}
                      </div>
                    ))}
                  </div>
                  <div className="flex gap-2 mt-3">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handleCopyBackupCodes}
                      className="flex-1"
                    >
                      <Copy className="h-4 w-4 mr-2" />
                      Copy
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handleDownloadBackupCodes}
                      className="flex-1"
                    >
                      <Download className="h-4 w-4 mr-2" />
                      Download
                    </Button>
                  </div>
                </div>
              </div>

              <DialogFooter>
                <Button
                  onClick={() => {
                    setDialogOpen(false);
                    setTwoFactorStep("setup");
                    setShowBackupCodes(false);
                    setPasswordForTwoFactor("");
                    setTotpCode("");
                  }}
                  className="w-full"
                >
                  Complete Setup
                </Button>
              </DialogFooter>
            </>
          )}
        </DialogContent>
      </Dialog>

      <Dialog
        open={confirmDisableOpen}
        onOpenChange={setConfirmDisableOpen}
      >
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-destructive" />
              Disable Two-Factor Authentication?
            </DialogTitle>
            <DialogDescription>
              This will make your account less secure. You'll need to set up 2FA
              again if you want to re-enable it.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="flex-col sm:flex-row gap-2">
            <Button
              variant="outline"
              onClick={() => setConfirmDisableOpen(false)}
              className="w-full sm:w-auto"
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={async () => {
                setConfirmDisableOpen(false);
                setTwoFactorLoading(true);
                try {
                  const result = await authClient.twoFactor.disable({
                    password: passwordForTwoFactor,
                  });

                  if (result.error) {
                    toast.error(
                      result.error.message ?? "Failed to disable 2FA",
                    );
                    setTwoFactorLoading(false);
                    return;
                  }

                  setTwoFactorEnabled(false);
                  setTwoFactorStep("setup");
                  setTotpQrCode(null);
                  setBackupCodes([]);
                  setPasswordForTwoFactor("");
                  setTotpCode("");
                  toast.success("2FA disabled successfully");
                } catch (error) {
                  logger.error("Error disabling 2FA:", error);
                  toast.error(
                    "An unexpected error occurred while disabling 2FA",
                  );
                } finally {
                  setTwoFactorLoading(false);
                }
              }}
              disabled={twoFactorLoading}
              className="w-full sm:w-auto"
            >
              {twoFactorLoading ? "Disabling..." : "Disable 2FA"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
