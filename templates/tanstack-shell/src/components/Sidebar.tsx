import { useEffect, useRef, useState } from "react";
import { Link, useLocation } from "@tanstack/react-router";
import { authClient } from "../lib/auth-client";
import { Avatar, AvatarFallback, AvatarImage } from "./ui/avatar";
import {
  SidebarDropdownMenu,
  SidebarDropdownMenuContent,
  SidebarDropdownMenuItem,
  SidebarDropdownMenuSeparator,
  SidebarDropdownMenuTrigger,
} from "./SidebarDropdown";
import { Button } from "./ui/button";

interface SidebarProps {
  isMinimized: boolean;
  onToggle: () => void;
}

const navigationItems = [
  {
    label: "Home",
    path: "/",
    icon: "🏠",
  },
  {
    label: "Auth Demo",
    path: "/auth-demo",
    icon: "🔐",
  },
];

export default function Sidebar({ isMinimized, onToggle }: SidebarProps) {
  const location = useLocation();
  const sidebarRef = useRef<HTMLElement>(null);
  const [skipLinkFocused, setSkipLinkFocused] = useState(false);
  const [dropdownOpen, setDropdownOpen] = useState(false);

  const handleLogout = async () => {
    try {
      await authClient.signOut();
      // Force reload to reset authentication state completely
      window.location.href = "/";
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  const handleSkipToMain = () => {
    const mainContent = document.querySelector(
      'main, [role="main"], #main-content',
    );
    if (mainContent) {
      (mainContent as HTMLElement).focus();
      (mainContent as HTMLElement).scrollIntoView();
    }
  };

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      // Toggle sidebar with Ctrl + .
      if (event.ctrlKey && event.key === ".") {
        event.preventDefault();
        onToggle();
        // Announce state change to screen readers
        const announcement = isMinimized
          ? "Sidebar expanded"
          : "Sidebar collapsed";
        announceToScreenReader(announcement);
      }

      // Focus management for sidebar navigation
      if (sidebarRef.current?.contains(event.target as Node)) {
        if (event.key === "Escape") {
          // Focus the toggle button when pressing Escape
          const toggleButton = sidebarRef.current.querySelector(
            "[data-sidebar-toggle]",
          );
          if (toggleButton) {
            (toggleButton as HTMLElement).focus();
          }
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [onToggle, isMinimized]);

  // Announce changes to screen readers
  const announceToScreenReader = (message: string) => {
    const announcement = document.createElement("div");
    announcement.setAttribute("aria-live", "polite");
    announcement.setAttribute("aria-atomic", "true");
    announcement.className = "sr-only";
    announcement.textContent = message;
    document.body.appendChild(announcement);

    setTimeout(() => {
      document.body.removeChild(announcement);
    }, 1000);
  };

  return (
    <>
      {/* Skip to main content link for screen readers */}
      <a
        href="#main-content"
        onClick={(e) => {
          e.preventDefault();
          handleSkipToMain();
        }}
        onFocus={() => setSkipLinkFocused(true)}
        onBlur={() => setSkipLinkFocused(false)}
        className={`${
          skipLinkFocused
            ? "fixed top-4 left-4 z-[100] px-4 py-2 bg-primary text-primary-foreground rounded-md focus:outline-none focus:ring-2 focus:ring-ring"
            : "sr-only"
        }`}
      >
        Skip to main content
      </a>

      <aside
        ref={sidebarRef}
        role="navigation"
        aria-label="Main navigation"
        aria-expanded={!isMinimized}
        className={`fixed left-0 top-0 h-full bg-sidebar border-r border-sidebar-border shadow-lg transition-all duration-300 ease-in-out z-50 flex flex-col ${
          isMinimized ? "w-16" : "w-64"
        }`}
      >
        {/* Header with toggle button */}
        <header className="flex items-center justify-between p-4 border-b border-sidebar-border">
          {!isMinimized && (
            <h1
              className="text-xl font-bold text-sidebar-foreground"
              id="sidebar-title"
            >
              Connix
            </h1>
          )}
          <Button
            variant="ghost"
            size="sm"
            onClick={onToggle}
            data-sidebar-toggle
            className="p-2 hover:bg-sidebar-accent transition-all duration-200 hover:scale-110 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
            aria-label={isMinimized ? "Expand sidebar" : "Collapse sidebar"}
            aria-expanded={!isMinimized}
            aria-controls="sidebar-navigation"
            title={`${isMinimized ? "Expand" : "Collapse"} sidebar (Ctrl + .)`}
          >
            <span
              className="text-sidebar-foreground font-bold"
              aria-hidden="true"
            >
              {isMinimized ? "→" : "←"}
            </span>
          </Button>
        </header>

        {/* Main navigation */}
        <nav
          className="flex-1 py-4"
          id="sidebar-navigation"
          aria-labelledby={isMinimized ? undefined : "sidebar-title"}
          aria-label={isMinimized ? "Main navigation" : undefined}
        >
          <ul
            className="space-y-2 px-2"
            role="list"
          >
            {navigationItems.map((item) => {
              const isActive = location.pathname === item.path;
              return (
                <li
                  key={item.path}
                  role="listitem"
                >
                  <Link
                    to={item.path}
                    className={`flex items-center gap-3 px-3 py-2 rounded-lg transition-all duration-200 hover:bg-sidebar-accent hover:scale-105 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 ${
                      isActive
                        ? "bg-sidebar-primary/10 text-sidebar-primary border border-sidebar-primary/20 shadow-sm"
                        : "text-sidebar-foreground"
                    } ${isMinimized ? "justify-center" : ""}`}
                    aria-label={isMinimized ? item.label : undefined}
                    aria-current={isActive ? "page" : undefined}
                    title={isMinimized ? item.label : undefined}
                    tabIndex={0}
                  >
                    <span
                      className="text-xl flex-shrink-0"
                      aria-hidden="true"
                      role="img"
                      aria-label={`${item.label} icon`}
                    >
                      {item.icon}
                    </span>
                    {!isMinimized && (
                      <span className="font-medium">{item.label}</span>
                    )}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>

        {/* User menu section */}
        <footer className="border-t border-sidebar-border p-4 relative">
          <SidebarDropdownMenu
            modal={false}
            open={dropdownOpen}
            onOpenChange={(open) => {
              setDropdownOpen(open);
              if (open) {
                // Focus first menu item when dropdown opens
                setTimeout(() => {
                  const firstMenuItem = document.querySelector(
                    '[role="menuitem"]:not([data-disabled])',
                  );
                  if (firstMenuItem) {
                    firstMenuItem.setAttribute("tabindex", "0");
                    firstMenuItem.focus();
                  }
                }, 0);
              }
            }}
          >
            <SidebarDropdownMenuTrigger asChild>
              <Button
                variant="ghost"
                className={`w-full justify-start gap-3 hover:bg-sidebar-accent/80 transition-all duration-200 hover:scale-[1.02] rounded-lg focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 ${
                  isMinimized ? "px-2" : "px-3"
                }`}
                aria-label={isMinimized ? "User menu" : "Open user menu"}
                aria-haspopup="menu"
                aria-expanded={dropdownOpen}
              >
                <Avatar className="h-8 w-8 flex-shrink-0">
                  <AvatarImage
                    src="/placeholder-avatar.jpg"
                    alt="User avatar"
                  />
                  <AvatarFallback
                    className="bg-sidebar-primary text-sidebar-primary-foreground text-sm"
                    aria-label="User initials"
                  >
                    U
                  </AvatarFallback>
                </Avatar>
                {!isMinimized && (
                  <>
                    <div className="flex flex-col items-start text-left">
                      <span className="text-sm font-medium text-sidebar-foreground">
                        User Name
                      </span>
                      <span className="text-xs text-muted-foreground">
                        user@example.com
                      </span>
                    </div>
                    <span
                      className="ml-auto text-muted-foreground"
                      aria-hidden="true"
                    >
                      ›
                    </span>
                  </>
                )}
              </Button>
            </SidebarDropdownMenuTrigger>
            <SidebarDropdownMenuContent
              align={isMinimized ? "start" : "center"}
              side={isMinimized ? "right" : "top"}
              sideOffset={isMinimized ? 12 : 8}
              className={isMinimized ? "w-48" : "w-56"}
              avoidCollisions={true}
              collisionPadding={16}
              aria-label="User account options"
              aria-describedby="user-menu-description"
            >
              <div
                id="user-menu-description"
                className="sr-only"
              >
                User account options including profile, settings, and sign out
              </div>
              <SidebarDropdownMenuItem asChild>
                <Link
                  to="/settings"
                  className="w-full"
                  search={{ tab: "profile" }}
                >
                  Profile
                </Link>
              </SidebarDropdownMenuItem>
              <SidebarDropdownMenuItem asChild>
                <Link
                  to="/settings"
                  className="w-full"
                  search={{ tab: "settings" }}
                >
                  Settings
                </Link>
              </SidebarDropdownMenuItem>
              <SidebarDropdownMenuItem asChild>
                <Link
                  to="/settings"
                  className="w-full"
                  search={{ tab: "billing" }}
                >
                  Billing
                </Link>
              </SidebarDropdownMenuItem>
              <SidebarDropdownMenuSeparator />
              <SidebarDropdownMenuItem
                onClick={handleLogout}
                className="text-destructive hover:text-destructive hover:bg-destructive/10 cursor-pointer font-medium"
                aria-label="Sign out of your account"
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") {
                    e.preventDefault();
                    handleLogout();
                  }
                }}
              >
                <span>Sign Out</span>
              </SidebarDropdownMenuItem>
            </SidebarDropdownMenuContent>
          </SidebarDropdownMenu>
        </footer>

        {/* Screen reader only status announcements */}
        <div
          aria-live="polite"
          aria-atomic="true"
          className="sr-only"
        >
          Sidebar is {isMinimized ? "collapsed" : "expanded"}
          {dropdownOpen && " - User menu opened"}
        </div>
      </aside>
    </>
  );
}
