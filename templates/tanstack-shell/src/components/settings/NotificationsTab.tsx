import { toast } from "sonner";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "../ui/card";
import { Label } from "../ui/label";
import { Separator } from "../ui/separator";
import { Switch } from "../ui/switch";
import type { NotificationSettings } from "./types";

interface NotificationsTabProps {
  notifications: NotificationSettings;
  setNotifications: React.Dispatch<React.SetStateAction<NotificationSettings>>;
}

export function NotificationsTab({
  notifications,
  setNotifications,
}: NotificationsTabProps) {
  const handleNotificationChange = (
    key: keyof NotificationSettings,
    value: boolean,
  ) => {
    setNotifications((prev) => ({ ...prev, [key]: value }));
    toast.success("Notification settings updated");
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Notification Preferences</CardTitle>
        <CardDescription>Choose how you want to be notified</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <Label
                htmlFor="email-notifications"
                className="text-base font-medium"
              >
                Email Notifications
              </Label>
              <p className="text-sm text-gray-600">
                Get notified about important updates via email
              </p>
            </div>
            <Switch
              id="email-notifications"
              checked={notifications.emailNotifications}
              onCheckedChange={(checked) =>
                handleNotificationChange("emailNotifications", checked)
              }
            />
          </div>

          <Separator />

          <div className="flex items-center justify-between">
            <div>
              <Label
                htmlFor="push-notifications"
                className="text-base font-medium"
              >
                Push Notifications
              </Label>
              <p className="text-sm text-gray-600">
                Get push notifications on your devices
              </p>
            </div>
            <Switch
              id="push-notifications"
              checked={notifications.pushNotifications}
              onCheckedChange={(checked) =>
                handleNotificationChange("pushNotifications", checked)
              }
            />
          </div>

          <Separator />

          <div className="flex items-center justify-between">
            <div>
              <Label
                htmlFor="sms-notifications"
                className="text-base font-medium"
              >
                SMS Notifications
              </Label>
              <p className="text-sm text-gray-600">
                Receive notifications via text message
              </p>
            </div>
            <Switch
              id="sms-notifications"
              checked={notifications.smsNotifications}
              onCheckedChange={(checked) =>
                handleNotificationChange("smsNotifications", checked)
              }
            />
          </div>

          <Separator />

          <div className="flex items-center justify-between">
            <div>
              <Label
                htmlFor="marketing-emails"
                className="text-base font-medium"
              >
                Marketing Emails
              </Label>
              <p className="text-sm text-gray-600">
                Receive emails about new features and promotions
              </p>
            </div>
            <Switch
              id="marketing-emails"
              checked={notifications.marketingEmails}
              onCheckedChange={(checked) =>
                handleNotificationChange("marketingEmails", checked)
              }
            />
          </div>

          <Separator />

          <div className="flex items-center justify-between">
            <div>
              <Label
                htmlFor="security-alerts"
                className="text-base font-medium"
              >
                Security Alerts
              </Label>
              <p className="text-sm text-gray-600">
                Get notified about security-related events
              </p>
            </div>
            <Switch
              id="security-alerts"
              checked={notifications.securityAlerts}
              onCheckedChange={(checked) =>
                handleNotificationChange("securityAlerts", checked)
              }
            />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
