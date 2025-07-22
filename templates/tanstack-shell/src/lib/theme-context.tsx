import React, { createContext, useContext, useEffect, useState } from "react";
import type {
  ThemeContextType,
  ThemeProviderProps,
  ThemeValue,
} from "../components/settings/types";

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export function useTheme() {
  const context = useContext(ThemeContext);
  if (context === undefined) {
    throw new Error("useTheme must be used within a ThemeProvider");
  }
  return context;
}

export function ThemeProvider({
  children,
  defaultTheme = "dark",
}: ThemeProviderProps) {
  const [theme, setThemeState] = useState<ThemeValue>(defaultTheme);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Apply theme to document root
  const applyTheme = (newTheme: ThemeValue) => {
    if (typeof window === "undefined") {
      return;
    }

    // Remove all theme classes
    document.documentElement.classList.remove(
      "light",
      "dark",
      "protanopia",
      "deuteranopia",
      "tritanopia",
    );

    // Add the new theme class (light is default, no class needed)
    if (newTheme !== "light") {
      document.documentElement.classList.add(newTheme);
    }
  };

  // Load initial theme from localStorage
  useEffect(() => {
    const loadUserTheme = () => {
      try {
        setIsLoading(true);
        setError(null);

        if (typeof window === "undefined") {
          setThemeState(defaultTheme);
          setIsLoading(false);
          return;
        }

        // Get theme from localStorage
        const savedTheme = localStorage.getItem(
          "connix-theme",
        ) as ThemeValue | null;

        if (
          savedTheme &&
          [
            "light",
            "dark",
            "protanopia",
            "deuteranopia",
            "tritanopia",
          ].includes(savedTheme)
        ) {
          setThemeState(savedTheme);
          applyTheme(savedTheme);
        } else {
          // Use default theme if no valid saved theme
          setThemeState(defaultTheme);
          applyTheme(defaultTheme);
          // Save default to localStorage
          localStorage.setItem("connix-theme", defaultTheme);
        }
      } catch (err) {
        console.error("Failed to load theme from localStorage:", err);
        setError("Failed to load theme preferences");
        // Use default theme on error
        setThemeState(defaultTheme);
        applyTheme(defaultTheme);
      } finally {
        setIsLoading(false);
      }
    };

    loadUserTheme();
  }, [defaultTheme]);

  const setTheme = (newTheme: ThemeValue) =>
    Promise.resolve().then(() => {
      try {
        setError(null);

        // Apply theme immediately for better UX
        setThemeState(newTheme);
        applyTheme(newTheme);

        // Save to localStorage for persistence
        if (typeof window !== "undefined") {
          localStorage.setItem("connix-theme", newTheme);
        }
      } catch (err) {
        console.error("Failed to update theme:", err);
        setError("Failed to update theme");
        // Keep the UI updated even if saving failed
      }
    });

  const value: ThemeContextType = {
    theme,
    setTheme,
    isLoading,
    error,
  };

  return (
    <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
  );
}
