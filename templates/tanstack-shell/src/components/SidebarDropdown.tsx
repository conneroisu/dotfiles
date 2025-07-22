"use client";

import * as React from "react";
import * as DropdownMenuPrimitive from "@radix-ui/react-dropdown-menu";
import { cn } from "../lib/utils";

const SidebarDropdownMenu = DropdownMenuPrimitive.Root;

const SidebarDropdownMenuTrigger = DropdownMenuPrimitive.Trigger;

const SidebarDropdownMenuContent = React.forwardRef<
  React.ComponentRef<typeof DropdownMenuPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Content>
>(({ className, sideOffset = 8, ...props }, ref) => {
  const handleKeyDown = (event: React.KeyboardEvent) => {
    const menuItems = Array.from(
      event.currentTarget.querySelectorAll(
        '[role="menuitem"]:not([data-disabled])',
      ),
    );

    if (menuItems.length === 0) {
      return;
    }

    const currentIndex = menuItems.findIndex(
      (item) => document.activeElement === item,
    );

    switch (event.key) {
      case "ArrowDown": {
        event.preventDefault();
        const nextIndex =
          currentIndex === -1 ? 0 : (currentIndex + 1) % menuItems.length;
        if (menuItems[nextIndex]) {
          (menuItems[nextIndex] as HTMLElement).focus();
        }
        break;
      }

      case "ArrowUp": {
        event.preventDefault();
        const prevIndex =
          currentIndex === -1
            ? menuItems.length - 1
            : currentIndex === 0
              ? menuItems.length - 1
              : currentIndex - 1;
        if (menuItems[prevIndex]) {
          (menuItems[prevIndex] as HTMLElement).focus();
        }
        break;
      }

      case "Home":
        event.preventDefault();
        if (menuItems[0]) {
          (menuItems[0] as HTMLElement).focus();
        }
        break;

      case "End":
        event.preventDefault();
        if (menuItems[menuItems.length - 1]) {
          (menuItems[menuItems.length - 1] as HTMLElement).focus();
        }
        break;
    }
  };

  return (
    <DropdownMenuPrimitive.Portal>
      <DropdownMenuPrimitive.Content
        ref={ref}
        role="menu"
        aria-orientation="vertical"
        sideOffset={sideOffset}
        className={cn(
          "z-[60] min-w-[12rem] overflow-hidden rounded-lg border border-sidebar-border bg-popover/95 backdrop-blur-sm p-1.5 text-popover-foreground shadow-xl",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
          "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
          "data-[side=right]:slide-in-from-left-2 data-[state=closed]:slide-out-to-left-2",
          "data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:slide-out-to-bottom-2",
          "focus:outline-none",
          className,
        )}
        onCloseAutoFocus={(event) => {
          // Prevent auto focus when menu closes to maintain better UX
          event.preventDefault();
        }}
        onKeyDown={handleKeyDown}
        {...props}
      />
    </DropdownMenuPrimitive.Portal>
  );
});
SidebarDropdownMenuContent.displayName =
  DropdownMenuPrimitive.Content.displayName;

const SidebarDropdownMenuItem = React.forwardRef<
  React.ComponentRef<typeof DropdownMenuPrimitive.Item>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Item> & {
    inset?: boolean;
  }
>(({ className, inset, onKeyDown, onFocus, ...props }, ref) => {
  const handleKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
    // Handle Enter and Space for menu items that don't have asChild
    if ((event.key === "Enter" || event.key === " ") && !props.asChild) {
      event.preventDefault();
      (event.currentTarget as HTMLElement).click();
    }

    // Call custom onKeyDown if provided
    onKeyDown?.(event);
  };

  const handleFocus = (event: React.FocusEvent<HTMLDivElement>) => {
    // Implement roving tabindex - only focused item should be tabbable
    const menuItems = document.querySelectorAll('[role="menuitem"]');
    menuItems.forEach((item) => item.setAttribute("tabindex", "-1"));
    event.currentTarget.setAttribute("tabindex", "0");

    // Call custom onFocus if provided
    onFocus?.(event);
  };

  return (
    <DropdownMenuPrimitive.Item
      ref={ref}
      role="menuitem"
      tabIndex={-1}
      className={cn(
        "relative flex cursor-pointer select-none items-center rounded-md px-3 py-2.5 text-sm font-medium outline-none transition-all duration-200",
        "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus:bg-sidebar-accent focus:text-sidebar-accent-foreground",
        "focus:ring-2 focus:ring-ring focus:ring-offset-2",
        "data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
        "active:scale-[0.98]",
        inset && "pl-8",
        className,
      )}
      onKeyDown={handleKeyDown}
      onFocus={handleFocus}
      {...props}
    />
  );
});
SidebarDropdownMenuItem.displayName = DropdownMenuPrimitive.Item.displayName;

const SidebarDropdownMenuSeparator = React.forwardRef<
  React.ComponentRef<typeof DropdownMenuPrimitive.Separator>,
  React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Separator>
>(({ className, ...props }, ref) => (
  <DropdownMenuPrimitive.Separator
    ref={ref}
    className={cn("-mx-1 my-2 h-px bg-sidebar-border", className)}
    {...props}
  />
));
SidebarDropdownMenuSeparator.displayName =
  DropdownMenuPrimitive.Separator.displayName;

export {
  SidebarDropdownMenu,
  SidebarDropdownMenuTrigger,
  SidebarDropdownMenuContent,
  SidebarDropdownMenuItem,
  SidebarDropdownMenuSeparator,
};
