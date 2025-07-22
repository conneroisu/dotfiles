import { Eye, Moon, Palette, RefreshCw, Sun } from "lucide-react";
import { useTheme } from "../../hooks/use-theme";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "../ui/card";
import { Label } from "../ui/label";
import { Separator } from "../ui/separator";

export function AppearanceTab() {
  const {
    theme,
    setTheme,
    isLoading: themeLoading,
    error: themeError,
    availableThemes,
    getThemeDisplayName,
  } = useTheme();

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <Palette className="h-5 w-5" />
          <span>Theme Settings</span>
        </CardTitle>
        <CardDescription>
          Customize the appearance of your interface. Choose from
          accessibility-friendly themes that support colorblind users.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {themeError && (
          <div className="p-3 text-sm text-destructive bg-destructive/10 border border-destructive/20 rounded-lg">
            {themeError}
          </div>
        )}

        <div className="space-y-4">
          <div>
            <Label className="text-base font-medium">Current Theme</Label>
            <p className="text-sm text-gray-600 mb-3">
              Selected: {getThemeDisplayName(theme)}
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {availableThemes.map((themeOption) => {
              const isSelected = theme === themeOption.value;
              const getThemeIcon = (themeValue: string) => {
                if (themeValue === "light") {
                  return Sun;
                }
                if (themeValue === "dark") {
                  return Moon;
                }
                if (
                  ["protanopia", "deuteranopia", "tritanopia"].includes(
                    themeValue,
                  )
                ) {
                  return Eye;
                }
                return Palette;
              };

              const ThemeIcon = getThemeIcon(themeOption.value);

              return (
                <button
                  key={themeOption.value}
                  onClick={() => setTheme(themeOption.value)}
                  disabled={themeLoading}
                  className={`
                    relative p-4 border-2 rounded-lg transition-all duration-200 text-left
                    ${
                      isSelected
                        ? "border-primary bg-primary/5 shadow-md"
                        : "border-border hover:border-primary/50 hover:bg-muted/50"
                    }
                    ${themeLoading ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}
                  `}
                >
                  <div className="flex items-center space-x-3">
                    <div
                      className={`
                      p-2 rounded-md
                      ${isSelected ? "bg-primary text-primary-foreground" : "bg-muted"}
                    `}
                    >
                      <ThemeIcon className="h-4 w-4" />
                    </div>
                    <div className="flex-1">
                      <p className="font-medium">{themeOption.label}</p>
                      <p className="text-xs text-muted-foreground">
                        {themeOption.value === "light" && "Bright interface"}
                        {themeOption.value === "dark" && "Dark interface"}
                        {themeOption.value === "protanopia" &&
                          "Red-blind optimized"}
                        {themeOption.value === "deuteranopia" &&
                          "Green-blind optimized"}
                        {themeOption.value === "tritanopia" &&
                          "Blue-blind optimized"}
                      </p>
                    </div>
                    {isSelected && (
                      <div className="absolute top-2 right-2">
                        <div className="w-2 h-2 bg-primary rounded-full"></div>
                      </div>
                    )}
                  </div>
                </button>
              );
            })}
          </div>

          {themeLoading && (
            <div className="flex items-center justify-center py-4">
              <RefreshCw className="h-4 w-4 animate-spin mr-2" />
              <span className="text-sm text-muted-foreground">
                Updating theme...
              </span>
            </div>
          )}
        </div>

        <Separator />

        <div className="space-y-3">
          <h3 className="text-sm font-medium">Accessibility Information</h3>
          <div className="text-sm text-muted-foreground space-y-2">
            <p>
              <strong>Colorblind-friendly themes:</strong> These themes are
              specifically designed to be accessible for users with different
              types of color vision deficiency.
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>
                <strong>Protanopia:</strong> Optimized for red-blind users
                (blue/cyan focus)
              </li>
              <li>
                <strong>Deuteranopia:</strong> Optimized for green-blind users
                (purple/orange focus)
              </li>
              <li>
                <strong>Tritanopia:</strong> Optimized for blue-blind users
                (red/green focus)
              </li>
            </ul>
            <p className="text-xs">
              All themes maintain proper contrast ratios for readability and
              follow WCAG accessibility guidelines.
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
