export interface UserProfile {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  bio: string;
  company: string;
  website: string;
  location: string;
  timezone: string;
  avatar: string;
}

export interface BillingInfo {
  plan: string;
  status: string;
  nextBilling: string;
  amount: number;
  paymentMethod: string;
  cardLast4: string;
}

export interface NotificationSettings {
  emailNotifications: boolean;
  pushNotifications: boolean;
  smsNotifications: boolean;
  marketingEmails: boolean;
  securityAlerts: boolean;
}

export interface Invoice {
  id: string;
  date: string;
  amount: number;
  status: string;
}

export type TwoFactorStep = "setup" | "qr" | "verify" | "backup";

export type ThemeValue =
  | "light"
  | "dark"
  | "protanopia"
  | "deuteranopia"
  | "tritanopia";

export interface ThemeOption {
  value: ThemeValue;
  label: string;
  description?: string;
}

export interface ThemeContextType {
  theme: ThemeValue;
  setTheme: (theme: ThemeValue) => Promise<void>;
  isLoading: boolean;
  error: string | null;
}

export interface ThemeProviderProps {
  children: React.ReactNode;
  defaultTheme?: ThemeValue;
}
