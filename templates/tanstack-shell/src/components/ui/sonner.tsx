import { Toaster as Sonner } from "sonner";
import type { ToasterProps as SonnerToasterProps } from "sonner";

type ToasterProps = Pick<
  SonnerToasterProps,
  | "position"
  | "expand"
  | "richColors"
  | "closeButton"
  | "invert"
  | "theme"
  | "hotkey"
  | "duration"
  | "gap"
  | "visibleToasts"
  | "toastOptions"
  | "className"
  | "style"
  | "offset"
  | "mobileOffset"
  | "dir"
  | "swipeDirections"
  | "icons"
  | "containerAriaLabel"
>;

const Toaster = ({ position = "bottom-right", ...props }: ToasterProps) => {
  return (
    <Sonner
      position={position}
      className="toaster group"
      richColors
      closeButton
      {...props}
    />
  );
};

export { Toaster };
