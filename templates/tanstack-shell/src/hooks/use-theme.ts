import { useTheme as useThemeContext } from "../lib/theme-context";
import type { ThemeOption } from "../components/settings/types";

/**
 * Custom hook for theme management
 *
 * Provides easy access to theme state and actions.
 * Re-exports the theme context hook with additional utilities.
 */
export function useTheme() {
  const context = useThemeContext();

  return {
    ...context,

    /**
     * Check if the current theme is a colorblind-friendly variant
     */
    isColorblindTheme: ["protanopia", "deuteranopia", "tritanopia"].includes(
      context.theme,
    ),

    /**
     * Check if the current theme is dark mode (including colorblind variants)
     */
    isDark: context.theme !== "light",

    /**
     * Get the display name for the current theme
     */
    getThemeDisplayName: (theme: typeof context.theme = context.theme) => {
      switch (theme) {
        case "light":
          return "Light";
        case "dark":
          return "Dark";
        case "protanopia":
          return "Colorblind (Red-blind)";
        case "deuteranopia":
          return "Colorblind (Green-blind)";
        case "tritanopia":
          return "Colorblind (Blue-blind)";
        default:
          return "Unknown";
      }
    },

    /**
     * Get all available themes with display names
     */
    availableThemes: [
      { value: "light" as const, label: "Light" },
      { value: "dark" as const, label: "Dark" },
      {
        value: "protanopia" as const,
        label: "Colorblind (Red-blind)",
      },
      {
        value: "deuteranopia" as const,
        label: "Colorblind (Green-blind)",
      },
      {
        value: "tritanopia" as const,
        label: "Colorblind (Blue-blind)",
      },
    ] as Array<ThemeOption>,
  };
}
