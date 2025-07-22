import {
  HeadContent,
  Outlet,
  Scripts,
  createRootRouteWithContext,
  useLocation,
} from "@tanstack/react-router";
import { TanStackRouterDevtools } from "@tanstack/react-router-devtools";
import { useEffect, useState } from "react";

import Sidebar from "../components/Sidebar";
import { Toaster } from "../components/ui/sonner";
import { authClient } from "../lib/auth-client";
import { ThemeProvider } from "../lib/theme-context";

import TanStackQueryLayout from "../integrations/tanstack-query/layout.tsx";
import type { QueryClient } from "@tanstack/react-query";

// Import styles directly to avoid Vite's timestamp query parameter that causes hydration mismatches
import "../styles.css";

interface MyRouterContext {
  queryClient: QueryClient;
}

export const Route = createRootRouteWithContext<MyRouterContext>()({
  head: () => ({
    meta: [
      {
        charSet: "utf-8",
      },
      {
        name: "viewport",
        content: "width=device-width, initial-scale=1",
      },
      {
        title: "TanStack Start Starter",
      },
    ],
  }),

  component: RootComponent,
  notFoundComponent: NotFoundComponent,
});

function NotFoundComponent() {
  return (
    <div className="flex items-center justify-center h-full">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-gray-300 mb-4">404</h1>
        <h2 className="text-2xl font-semibold text-gray-700 mb-2">
          Page Not Found
        </h2>
        <p className="text-gray-500 mb-6">
          The page you're looking for doesn't exist.
        </p>
        <a
          href="/"
          className="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          ← Back to Home
        </a>
      </div>
    </div>
  );
}

function RootComponent() {
  const location = useLocation();
  const [isSidebarMinimized, setIsSidebarMinimized] = useState(false);

  // Authentication state starts as null to differentiate between "loading" and "not authenticated"
  // This prevents hydration mismatches by ensuring the sidebar isn't rendered until we know the auth state
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null);

  const toggleSidebar = () => {
    setIsSidebarMinimized(!isSidebarMinimized);
  };

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const session = await authClient.getSession();
        setIsAuthenticated(!!session.data?.user);
      } catch {
        setIsAuthenticated(false);
      }
    };

    checkAuth();
  }, [location.pathname]);

  // Determine if current route is an authentication page
  const authRoutes = [
    "/sign-in",
    "/sign-up",
    "/forgot-password",
    "/reset-password",
  ];
  const isAuthRoute = authRoutes.includes(location.pathname);

  // Only show sidebar when:
  // 1. User is authenticated (not null, which would cause hydration mismatch)
  // 2. Not on an authentication page
  const showSidebar = isAuthenticated === true && !isAuthRoute;

  return (
    <RootDocument>
      <ThemeProvider defaultTheme="dark">
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 bg-blue-600 text-white px-4 py-2 rounded shadow-lg transition-all"
        >
          Skip to main content
        </a>

        <div className="flex h-screen">
          {/* Sidebar container always renders to prevent hydration issues */}
          <aside
            role="complementary"
            aria-label="Sidebar navigation"
            className={showSidebar ? "" : "hidden"}
          >
            <Sidebar
              isMinimized={isSidebarMinimized}
              onToggle={toggleSidebar}
            />
          </aside>

          {/* Main content area with dynamic margin based on sidebar state */}
          <main
            id="main-content"
            role="main"
            className={`flex-1 transition-all duration-300 ease-in-out ${
              showSidebar ? (isSidebarMinimized ? "ml-16" : "ml-64") : ""
            }`}
          >
            <div className="h-full overflow-auto">
              <Outlet />
            </div>
          </main>
        </div>
        <TanStackRouterDevtools />
        <TanStackQueryLayout />
        <Toaster />
      </ThemeProvider>
    </RootDocument>
  );
}

function RootDocument({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  );
}
