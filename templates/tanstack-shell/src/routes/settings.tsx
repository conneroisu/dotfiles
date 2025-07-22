import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import {
  Bell,
  CreditCard,
  Palette,
  Settings,
  Shield,
  User,
} from "lucide-react";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "../components/ui/tabs";
import { ProfileTab } from "../components/settings/ProfileTab";
import { AccountTab } from "../components/settings/AccountTab";
import { SecurityTab } from "../components/settings/SecurityTab";
import { AppearanceTab } from "../components/settings/AppearanceTab";
import { BillingTab } from "../components/settings/BillingTab";
import { NotificationsTab } from "../components/settings/NotificationsTab";
import type {
  BillingInfo,
  NotificationSettings,
  TwoFactorStep,
  UserProfile,
} from "../components/settings/types";

export const Route = createFileRoute("/settings")({
  component: SettingsPage,
  validateSearch: (search: Record<string, unknown>) => {
    return {
      tab: (search.tab as string) || "profile",
    };
  },
});

function SettingsPage() {
  const { tab } = Route.useSearch();
  const navigate = Route.useNavigate();
  const [activeTab, setActiveTab] = useState(tab);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  const [profile, setProfile] = useState<UserProfile>({
    firstName: "John",
    lastName: "Doe",
    email: "john.doe@example.com",
    phone: "+1 (555) 123-4567",
    bio: "Full-stack developer passionate about creating amazing user experiences.",
    company: "Tech Corp",
    website: "https://johndoe.dev",
    location: "San Francisco, CA",
    timezone: "America/Los_Angeles",
    avatar: "",
  });

  const [billing] = useState<BillingInfo>({
    plan: "Professional",
    status: "Active",
    nextBilling: "2025-02-14",
    amount: 29.99,
    paymentMethod: "Credit Card",
    cardLast4: "4242",
  });

  const [notifications, setNotifications] = useState<NotificationSettings>({
    emailNotifications: true,
    pushNotifications: true,
    smsNotifications: false,
    marketingEmails: false,
    securityAlerts: true,
  });

  const [invoices] = useState([
    { id: "INV-001", date: "2025-01-14", amount: 29.99, status: "Paid" },
    { id: "INV-002", date: "2024-12-14", amount: 29.99, status: "Paid" },
    { id: "INV-003", date: "2024-11-14", amount: 29.99, status: "Paid" },
  ]);

  // Two-Factor Authentication state
  const [twoFactorEnabled, setTwoFactorEnabled] = useState(false);
  const [twoFactorLoading, setTwoFactorLoading] = useState(false);
  const [totpQrCode, setTotpQrCode] = useState<string | null>(null);
  const [backupCodes, setBackupCodes] = useState<Array<string>>([]);
  const [showBackupCodes, setShowBackupCodes] = useState(false);
  const [passwordForTwoFactor, setPasswordForTwoFactor] = useState("");
  const [twoFactorStep, setTwoFactorStep] = useState<TwoFactorStep>("setup");
  const [totpCode, setTotpCode] = useState("");

  // Don't render until client-side hydration is complete
  if (!isClient) {
    return (
      <div className="container mx-auto p-6">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-foreground">Settings</h1>
          <p className="text-muted-foreground mt-2">
            Loading settings...
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-foreground">Settings</h1>
        <p className="text-muted-foreground mt-2">
          Manage your account settings and preferences
        </p>
      </div>

      <Tabs
        value={activeTab}
        onValueChange={(value) => {
          setActiveTab(value);
          navigate({ search: { tab: value } });
        }}
        className="space-y-6"
        aria-label="Settings navigation"
      >
        <div className="w-full max-w-5xl">
          {/* Mobile dropdown for smaller screens */}
          <div className="block md:hidden mb-4">
            <label
              htmlFor="settings-tab-select"
              className="block text-sm font-medium text-foreground mb-2"
            >
              Settings Section
            </label>
            <select
              id="settings-tab-select"
              value={activeTab}
              onChange={(e) => {
                setActiveTab(e.target.value);
                navigate({ search: { tab: e.target.value } });
              }}
              className="w-full px-3 py-2 bg-background border border-input rounded-md text-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent"
            >
              <option value="profile">👤 Profile</option>
              <option value="account">⚙️ Account</option>
              <option value="security">🛡️ Security</option>
              <option value="appearance">🎨 Appearance</option>
              <option value="billing">💳 Billing</option>
              <option value="notifications">🔔 Notifications</option>
            </select>
          </div>

          {/* Desktop tabs */}
          <TabsList className="hidden md:grid grid-cols-6 w-full bg-muted/50 p-1 h-auto rounded-lg border">
            <TabsTrigger
              value="profile"
              className="flex flex-col items-center gap-1.5 px-3 py-4 text-xs font-medium rounded-md data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm data-[state=active]:border data-[state=active]:border-border transition-all duration-200 hover:bg-background/70 focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 relative group"
              aria-label="Profile settings"
            >
              <User
                className="h-4 w-4 group-data-[state=active]:text-primary transition-colors"
                aria-hidden="true"
              />
              <span className="group-data-[state=active]:font-semibold">
                Profile
              </span>
              <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-8 h-0.5 bg-primary rounded-full opacity-0 group-data-[state=active]:opacity-100 transition-opacity duration-200" />
            </TabsTrigger>
            <TabsTrigger
              value="account"
              className="flex flex-col items-center gap-1.5 px-3 py-4 text-xs font-medium rounded-md data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm data-[state=active]:border data-[state=active]:border-border transition-all duration-200 hover:bg-background/70 focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 relative group"
              aria-label="Account settings"
            >
              <Settings
                className="h-4 w-4 group-data-[state=active]:text-primary transition-colors"
                aria-hidden="true"
              />
              <span className="group-data-[state=active]:font-semibold">
                Account
              </span>
              <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-8 h-0.5 bg-primary rounded-full opacity-0 group-data-[state=active]:opacity-100 transition-opacity duration-200" />
            </TabsTrigger>
            <TabsTrigger
              value="security"
              className="flex flex-col items-center gap-1.5 px-3 py-4 text-xs font-medium rounded-md data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm data-[state=active]:border data-[state=active]:border-border transition-all duration-200 hover:bg-background/70 focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 relative group"
              aria-label="Security settings"
            >
              <Shield
                className="h-4 w-4 group-data-[state=active]:text-primary transition-colors"
                aria-hidden="true"
              />
              <span className="group-data-[state=active]:font-semibold">
                Security
              </span>
              <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-8 h-0.5 bg-primary rounded-full opacity-0 group-data-[state=active]:opacity-100 transition-opacity duration-200" />
            </TabsTrigger>
            <TabsTrigger
              value="appearance"
              className="flex flex-col items-center gap-1.5 px-3 py-4 text-xs font-medium rounded-md data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm data-[state=active]:border data-[state=active]:border-border transition-all duration-200 hover:bg-background/70 focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 relative group"
              aria-label="Appearance settings"
            >
              <Palette
                className="h-4 w-4 group-data-[state=active]:text-primary transition-colors"
                aria-hidden="true"
              />
              <span className="group-data-[state=active]:font-semibold">
                Appearance
              </span>
              <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-8 h-0.5 bg-primary rounded-full opacity-0 group-data-[state=active]:opacity-100 transition-opacity duration-200" />
            </TabsTrigger>
            <TabsTrigger
              value="billing"
              className="flex flex-col items-center gap-1.5 px-3 py-4 text-xs font-medium rounded-md data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm data-[state=active]:border data-[state=active]:border-border transition-all duration-200 hover:bg-background/70 focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 relative group"
              aria-label="Billing and subscription"
            >
              <CreditCard
                className="h-4 w-4 group-data-[state=active]:text-primary transition-colors"
                aria-hidden="true"
              />
              <span className="group-data-[state=active]:font-semibold">
                Billing
              </span>
              <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-8 h-0.5 bg-primary rounded-full opacity-0 group-data-[state=active]:opacity-100 transition-opacity duration-200" />
            </TabsTrigger>
            <TabsTrigger
              value="notifications"
              className="flex flex-col items-center gap-1.5 px-3 py-4 text-xs font-medium rounded-md data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm data-[state=active]:border data-[state=active]:border-border transition-all duration-200 hover:bg-background/70 focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 relative group"
              aria-label="Notification preferences"
            >
              <Bell
                className="h-4 w-4 group-data-[state=active]:text-primary transition-colors"
                aria-hidden="true"
              />
              <span className="group-data-[state=active]:font-semibold">
                Notifications
              </span>
              <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-8 h-0.5 bg-primary rounded-full opacity-0 group-data-[state=active]:opacity-100 transition-opacity duration-200" />
            </TabsTrigger>
          </TabsList>
        </div>

        <TabsContent
          value="profile"
          className="space-y-6 focus-visible:outline-none"
          role="tabpanel"
          aria-labelledby="profile-tab"
        >
          <ProfileTab
            profile={profile}
            setProfile={setProfile}
          />
        </TabsContent>

        <TabsContent
          value="account"
          className="space-y-6 focus-visible:outline-none"
          role="tabpanel"
          aria-labelledby="account-tab"
        >
          <AccountTab
            twoFactorEnabled={twoFactorEnabled}
            setTwoFactorEnabled={setTwoFactorEnabled}
            twoFactorLoading={twoFactorLoading}
            setTwoFactorLoading={setTwoFactorLoading}
            totpQrCode={totpQrCode}
            setTotpQrCode={setTotpQrCode}
            backupCodes={backupCodes}
            setBackupCodes={setBackupCodes}
            showBackupCodes={showBackupCodes}
            setShowBackupCodes={setShowBackupCodes}
            passwordForTwoFactor={passwordForTwoFactor}
            setPasswordForTwoFactor={setPasswordForTwoFactor}
            twoFactorStep={twoFactorStep}
            setTwoFactorStep={setTwoFactorStep}
            totpCode={totpCode}
            setTotpCode={setTotpCode}
          />
        </TabsContent>

        <TabsContent
          value="security"
          className="space-y-6 focus-visible:outline-none"
          role="tabpanel"
          aria-labelledby="security-tab"
        >
          <SecurityTab
            twoFactorEnabled={twoFactorEnabled}
            setTwoFactorEnabled={setTwoFactorEnabled}
            twoFactorLoading={twoFactorLoading}
            setTwoFactorLoading={setTwoFactorLoading}
            totpQrCode={totpQrCode}
            setTotpQrCode={setTotpQrCode}
            backupCodes={backupCodes}
            setBackupCodes={setBackupCodes}
            showBackupCodes={showBackupCodes}
            setShowBackupCodes={setShowBackupCodes}
            passwordForTwoFactor={passwordForTwoFactor}
            setPasswordForTwoFactor={setPasswordForTwoFactor}
            twoFactorStep={twoFactorStep}
            setTwoFactorStep={setTwoFactorStep}
            totpCode={totpCode}
            setTotpCode={setTotpCode}
          />
        </TabsContent>

        <TabsContent
          value="appearance"
          className="space-y-6 focus-visible:outline-none"
          role="tabpanel"
          aria-labelledby="appearance-tab"
        >
          <AppearanceTab />
        </TabsContent>

        <TabsContent
          value="billing"
          className="space-y-6 focus-visible:outline-none"
          role="tabpanel"
          aria-labelledby="billing-tab"
        >
          <BillingTab
            billing={billing}
            invoices={invoices}
          />
        </TabsContent>

        <TabsContent
          value="notifications"
          className="space-y-6 focus-visible:outline-none"
          role="tabpanel"
          aria-labelledby="notifications-tab"
        >
          <NotificationsTab
            notifications={notifications}
            setNotifications={setNotifications}
          />
        </TabsContent>
      </Tabs>
    </div>
  );
}
