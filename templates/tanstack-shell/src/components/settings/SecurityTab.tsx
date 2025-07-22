import { Shield } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "../ui/card";
import { AccountTab } from "./AccountTab";
import type { TwoFactorStep } from "./types";

interface SecurityTabProps {
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

export function SecurityTab(props: SecurityTabProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <Shield className="h-5 w-5" />
          <span>Security Settings</span>
        </CardTitle>
        <CardDescription>
          Manage your account security, two-factor authentication, and access
          controls
        </CardDescription>
      </CardHeader>
      <CardContent>
        <AccountTab {...props} />
      </CardContent>
    </Card>
  );
}
