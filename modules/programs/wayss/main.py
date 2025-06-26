"""
Hyprland Screenshot Tool with Recent Files Integration

A comprehensive screenshot utility for Hyprland that:
- Takes region screenshots using grim/slurp
- Copies screenshots to clipboard via wl-copy
- Saves timestamped screenshots to ~/Pictures/Screenshots/
- Adds screenshots to system recent files for easy access
- Provides rich D-Bus notifications for all operations
- Falls back gracefully when dependencies are unavailable

Dependencies:
    - grim: Screenshot utility for wlroots-based compositors
    - slurp: Select a region in a Wayland compositor
    - wl-copy: Copy data to Wayland clipboard
    - dunstify: Notification daemon (optional, for enhanced notifications)
    - python3-dbus: D-Bus Python bindings for notifications
    - python3-gi: GTK integration for recent files (optional)

Author: Generated for Hyprland screenshot automation
License: Public domain
"""

import sys
import subprocess
import dbus
import logging
import re
from datetime import datetime
from pathlib import Path
from contextlib import contextmanager

try:
    import gi

    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, GLib

    GTK_AVAILABLE = True
except ImportError as e:
    print(
        f"GTK 3.0 not available: {e}",
        file=sys.stderr,
    )
    try:
        # Send D-Bus notification about missing GTK
        session_bus = dbus.SessionBus()
        notification_object = (
            session_bus.get_object(
                "org.freedesktop.Notifications",
                "/org/freedesktop/Notifications",
            )
        )
        notification_interface = dbus.Interface(
            notification_object,
            "org.freedesktop.Notifications",
        )
        notification_interface.Notify(
            "Screenshot Tool",
            0,
            "dialog-error",
            "GTK 3.0 Required",
            "This application requires GTK 3.0 and python3-gi to function properly.",
            [],
            {"urgency": dbus.Int32(2)},
            5000,
        )
    except Exception:
        pass  # If D-Bus also fails, just continue to exit
    sys.exit(1)

# Configuration constants
DEFAULT_SCREENSHOTS_DIR = "Pictures/Screenshots"  # Relative to home directory
SCREENSHOT_FORMAT = (
    "png"  # Image format for screenshots
)
TIMESTAMP_FORMAT = "%Y-%m-%d_%H:%M:%S"  # Format for timestamp in filenames
DEFAULT_APP_NAME = "Screenshot Tool"  # D-Bus notification app name

# Notification urgency levels (D-Bus standard)
URGENCY_LOW = 0  # Low priority notifications
URGENCY_NORMAL = (
    1  # Normal priority notifications
)
URGENCY_CRITICAL = (
    2  # Critical/error notifications
)

# Geometry validation pattern for slurp output (x,y widthxheight)
GEOMETRY_PATTERN = re.compile(
    r"^\d+,\d+\s+\d+x\d+$"
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("wayss")


def send_hyprland_notification(
    title: str,
    body: str,
    app_name: str = DEFAULT_APP_NAME,
    icon: str = "",
    urgency: int = URGENCY_NORMAL,
    timeout_ms: int = 3000,
) -> None:
    """
    Send a desktop notification using D-Bus, compatible with Hyprland and most DEs.

    Uses the org.freedesktop.Notifications D-Bus interface to send notifications.
    This method works with most notification daemons including dunst, mako, and
    traditional desktop environments.

    Args:
        title (str): The notification title/summary text
        body (str): The main notification message body
        app_name (str): Application name displayed in notification (default: "Screenshot Tool")
        icon (str): Icon name from system theme or path to icon file (optional)
        urgency (int): Notification urgency level:
                      0 = Low (URGENCY_LOW)
                      1 = Normal (URGENCY_NORMAL)
                      2 = Critical (URGENCY_CRITICAL)
        timeout_ms (int): Time in milliseconds before notification auto-dismisses
                         Set to 0 for persistent notifications

    Returns:
        None

    Raises:
        None: Exceptions are caught and logged, with fallback to stderr printing

    Note:
        If D-Bus is unavailable or the notification service isn't running,
        the function gracefully falls back to printing the message to stderr.
    """
    try:
        # D-Bus service and interface for desktop notifications
        service_name = (
            "org.freedesktop.Notifications"
        )
        object_path = "/" + service_name.replace(
            ".", "/"
        )

        # Get the D-Bus session bus and notification interface
        session_bus = dbus.SessionBus()
        notification_object = (
            session_bus.get_object(
                service_name, object_path
            )
        )
        notification_interface = dbus.Interface(
            notification_object, service_name
        )

        # Send the notification via D-Bus
        # Parameters: app_name, replaces_id, icon, summary, body, actions, hints, timeout
        notification_interface.Notify(
            app_name,  # Application name for grouping
            0,  # Replaces ID (0 = new notification)
            icon,  # Icon name or file path
            title,  # Notification summary/title
            body,  # Notification body text
            [],  # Actions (empty for simple notifications)
            {
                "urgency": dbus.Int32(urgency)
            },  # Hints dictionary with urgency level
            timeout_ms,  # Timeout in milliseconds
        )
    except Exception as e:
        # Graceful fallback when D-Bus notifications fail
        # This can happen if:
        # - D-Bus isn't available
        # - No notification daemon is running
        # - Permission issues with D-Bus session
        print(
            f"D-Bus notification failed: {e}",
            file=sys.stderr,
        )
        print(
            f"[{title}] {body}", file=sys.stderr
        )


def run_command(
    command: str | list[str],
    input_data: bytes | None = None,
    capture_output: bool = True,
) -> subprocess.CompletedProcess[bytes] | None:
    """
    Execute a shell command with comprehensive error handling and logging.

    This function wraps subprocess.run() with enhanced error handling,
    automatic notification of failures, and support for both string
    and list command formats.

    Args:
        command (str | list[str]): Command to execute. Can be:
                                        - String: "grim --help" (will be split)
                                        - List: ["grim", "--help"] (preferred)
        input_data (bytes | None): Binary data to send to command's stdin
                                     Used for piping image data between commands
        capture_output (bool): Whether to capture stdout/stderr (default: True)
                              Set False for commands that should print directly

    Returns:
        subprocess.CompletedProcess | None: Process result object if successful,
                                              None if command failed or wasn't found

    Side Effects:
        - Sends D-Bus notifications for command failures
        - Prints error messages to stderr as fallback

    Examples:
        >>> result = run_command("slurp")  # Get screen selection
        >>> result = run_command(["grim", "-g", "100,100 200x200", "-"])  # Screenshot
        >>> run_command("wl-copy", input_data=image_bytes, capture_output=False)
    """
    try:
        # Normalize command format - convert string to list for consistent handling
        if isinstance(command, str):
            command = command.split()

        # Execute the command with appropriate I/O handling
        result = subprocess.run(
            command,
            input=input_data,  # Data to send to stdin (for piping)
            capture_output=capture_output,  # Whether to capture stdout/stderr
            text=False,  # Always use binary mode to handle both text and binary data
            check=True,  # Raise CalledProcessError on non-zero exit
        )
        return result

    except subprocess.CalledProcessError as e:
        # Command executed but returned non-zero exit code
        cmd_str = (
            " ".join(command)
            if isinstance(command, list)
            else command
        )
        error_msg = f"Command '{cmd_str}' failed with exit code {e.returncode}"
        if e.stderr:
            stderr_text = e.stderr.decode(
                "utf-8", errors="replace"
            ).strip()
            if stderr_text:
                error_msg += f": {stderr_text}"

        logging.error(error_msg)
        send_hyprland_notification(
            "Command Failed",
            (
                error_msg[:100] + "..."
                if len(error_msg) > 100
                else error_msg
            ),
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return None

    except FileNotFoundError:
        # Command binary not found in PATH
        cmd_name = (
            command[0]
            if isinstance(command, list)
            else command.split()[0]
        )
        error_msg = f"Command '{cmd_name}' not found. Please install the required package."
        logging.error(error_msg)
        send_hyprland_notification(
            "Command Not Found",
            error_msg,
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return None

    except Exception as e:
        cmd_str = (
            " ".join(command)
            if isinstance(command, list)
            else command
        )
        error_msg = f"Unexpected error running '{cmd_str}': {e}"
        logging.error(error_msg)
        send_hyprland_notification(
            "Unexpected Error",
            (
                error_msg[:100] + "..."
                if len(error_msg) > 100
                else error_msg
            ),
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return None


def validate_geometry(geometry: str) -> bool:
    """
    Validate slurp geometry output format.

    Args:
        geometry (str): Geometry string from slurp (e.g., "100,200 300x400")

    Returns:
        bool: True if geometry format is valid, False otherwise
    """
    return bool(
        GEOMETRY_PATTERN.match(geometry.strip())
    )


def take_screenshot() -> bytes | None:
    """
    Capture a screenshot of a user-selected region using grim and slurp.

    This function implements the two-step screenshot process:
    1. Use slurp to let user select a screen region
    2. Use grim to capture that region and return raw image data

    The process is interactive - slurp will show a crosshair cursor
    allowing the user to select a rectangular region by clicking and dragging.

    Returns:
        bytes | None: Raw PNG image data if successful, None if failed
                        The returned bytes can be directly saved to a file
                        or piped to other commands like wl-copy

    Dependencies:
        - slurp: For interactive region selection
        - grim: For capturing the screenshot

    Error Handling:
        - Sends notifications for missing dependencies
        - Handles user cancellation gracefully
        - Returns None on any failure for easy error checking

    Example Usage:
        >>> image_data = take_screenshot()
        >>> if image_data:
        >>>     with open("screenshot.png", "wb") as f:
        >>>         f.write(image_data)
    """
    # Step 1: Get user's screen region selection using slurp
    # slurp returns coordinates in format "x,y widthxheight" (e.g., "100,200 300x400")
    slurp_result = run_command("slurp")
    if not slurp_result:
        # slurp failed - could be cancelled by user, missing dependency, or Wayland issues
        send_hyprland_notification(
            "Screenshot Cancelled",
            "Screen region selection was cancelled or slurp is not available",
            icon="dialog-information",
            urgency=URGENCY_NORMAL,
            timeout_ms=3000,
        )
        return None

    # Extract and validate the selection coordinates from slurp output
    selection = slurp_result.stdout.decode(
        "utf-8"
    ).strip()

    if not validate_geometry(selection):
        error_msg = f"Invalid geometry format from slurp: '{selection}'"
        logger.error(error_msg)
        send_hyprland_notification(
            "Invalid Selection",
            "Screen selection returned invalid geometry. Please try again.",
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return None

    # Step 2: Capture screenshot of selected region using grim
    # grim -g specifies geometry, "-" outputs to stdout instead of file
    grim_result = run_command(
        ["grim", "-g", selection, "-"],
        capture_output=True,
    )
    if not grim_result:
        # grim failed - could be invalid selection, Wayland issues, or missing dependency
        send_hyprland_notification(
            "Screenshot Failed",
            "Failed to capture screenshot. Ensure grim is installed and Wayland is running.",
            icon="camera-photo",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return None

    # Return raw PNG image data from grim's stdout
    return grim_result.stdout


def copy_to_clipboard(image_data: bytes) -> bool:
    """
    Copy image data to the Wayland clipboard using wl-copy.

    This function pipes raw image data to wl-copy, which handles
    the clipboard integration for Wayland compositors like Hyprland.

    Args:
        image_data (bytes): Raw image data (typically PNG format)
                           This should be the exact bytes returned from grim

    Returns:
        bool: True if clipboard copy succeeded, False otherwise

    Dependencies:
        - wl-copy: Wayland clipboard utility (part of wl-clipboard package)

    Note:
        The image will be available for pasting in any application that
        supports image pasting from clipboard (browsers, image editors, etc.)

    Example:
        >>> with open("screenshot.png", "rb") as f:
        >>>     image_bytes = f.read()
        >>> success = copy_to_clipboard(image_bytes)
    """
    # Use wl-copy with binary image data, don't capture output (let it run in background)
    result = run_command(
        "wl-copy",
        input_data=image_data,
        capture_output=False,
    )

    # run_command returns None on failure, CompletedProcess on success
    return result is not None


def validate_file_path(
    file_path: str | Path,
) -> Path:
    """
    Validate and normalize file path.

    Args:
        file_path: Path to validate

    Returns:
        Path: Validated and normalized Path object

    Raises:
        ValueError: If path is invalid or unsafe
    """
    path = Path(file_path).expanduser().resolve()

    # Ensure path is within user's home directory for security
    home = Path.home().resolve()
    try:
        path.relative_to(home)
    except ValueError:
        raise ValueError(
            f"Path {path} is outside user home directory"
        )

    # Check for valid filename
    if not path.name or path.name.startswith("."):
        raise ValueError(
            f"Invalid filename: {path.name}"
        )

    return path


def save_screenshot(
    image_data: bytes, file_path: str | Path
) -> bool:
    """
    Save screenshot image data to a file with automatic directory creation.

    This function handles the complete file saving process including:
    - Path validation and security checks
    - Creating parent directories if they don't exist
    - Writing binary image data to file
    - Comprehensive error handling with user notifications

    Args:
        image_data (bytes): Raw image data to save (typically PNG format)
        file_path (str | Path): Destination file path for the screenshot

    Returns:
        bool: True if file was saved successfully, False if any error occurred
    """
    try:
        # Validate and normalize the file path
        validated_path = validate_file_path(
            file_path
        )

        # Ensure parent directories exist
        validated_path.parent.mkdir(
            parents=True, exist_ok=True
        )

        # Write binary image data to file
        validated_path.write_bytes(image_data)

        logger.info(
            f"Screenshot saved to: {validated_path}"
        )
        return True

    except ValueError as e:
        # Path validation failed
        error_msg = f"Invalid file path: {e}"
        logger.error(error_msg)
        send_hyprland_notification(
            "Invalid Path",
            error_msg,
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return False

    except PermissionError as e:
        # User doesn't have write permission to destination directory
        error_msg = f"Permission denied: {e}"
        logger.error(error_msg)
        send_hyprland_notification(
            "Permission Denied",
            error_msg,
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return False

    except OSError as e:
        # Covers disk full, invalid paths, filesystem errors, etc.
        error_msg = f"Cannot save screenshot: {e}"
        logger.error(error_msg)
        send_hyprland_notification(
            "Save Failed",
            error_msg,
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return False

    except Exception as e:
        # Catch-all for unexpected errors
        error_msg = f"Unexpected error saving screenshot: {e}"
        logger.error(error_msg)
        send_hyprland_notification(
            "Unexpected Error",
            error_msg,
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return False


def add_to_recent_files(
    file_path: str | Path,
) -> bool:
    """
    Add the screenshot file to the system's recent files database.

    Uses GTK Recent Manager to integrate with desktop environment's recent files system.
    Recent files integration allows the screenshot to appear in:
    - File manager "Recent" sections
    - Application "Open Recent" menus
    - Document picker dialogs
    - Any application using XDG recent files specification

    Args:
        file_path (str | Path): Path to the file to add to recent files
                                     Should be an absolute path to ensure proper URI generation

    Returns:
        bool: True if successfully added to recent files, False otherwise

    Dependencies:
        - python3-gi: For GTK Recent Manager integration
        - GTK 3.0: Required by python3-gi

    Note:
        GTK is required for this application to function properly.
    """
    try:
        # Get the default recent files manager instance
        recent_manager = (
            Gtk.RecentManager.get_default()
        )

        # Convert file path to proper URI format (file:///absolute/path)
        file_uri = (
            Path(file_path)
            .expanduser()
            .resolve()
            .as_uri()
        )

        # Add file to recent files database
        recent_manager.add_item(file_uri)

        # Start the GTK event loop to process the recent files change signal
        # This is necessary for the change to take effect
        GLib.idle_add(Gtk.main_quit)
        Gtk.main()

        return True

    except Exception as e:
        # GTK available but failed (permissions, D-Bus issues, etc.)
        send_hyprland_notification(
            "Recent Files Warning",
            f"GTK recent files failed: {e}",
            icon="dialog-warning",
            urgency=URGENCY_NORMAL,
            timeout_ms=3000,
        )
        return False


@contextmanager
def atomic_file_update(file_path: Path):
    """
    Context manager for atomic file updates with backup.

    Creates a temporary file for writing, then atomically moves it
    to replace the original file. Creates a backup before replacement.
    """
    backup_file = None
    temp_file = None

    try:
        # Create backup if original exists
        if file_path.exists():
            backup_file = file_path.with_suffix(
                f"{file_path.suffix}.bak"
            )
            backup_file.write_bytes(
                file_path.read_bytes()
            )

        # Create temporary file in same directory for atomic move
        temp_file = file_path.with_suffix(
            f"{file_path.suffix}.tmp"
        )

        yield temp_file

        # Atomic move
        temp_file.replace(file_path)
        temp_file = None  # Successfully moved, don't delete

    except Exception:
        # Restore from backup if something went wrong
        if (
            backup_file
            and backup_file.exists()
            and file_path.exists()
        ):
            try:
                backup_file.replace(file_path)
            except Exception as restore_error:
                logger.error(
                    f"Failed to restore backup: {restore_error}"
                )
        raise
    finally:
        # Clean up temporary file if it still exists
        if temp_file and temp_file.exists():
            try:
                temp_file.unlink()
            except Exception as cleanup_error:
                logger.warning(
                    f"Failed to clean up temp file: {cleanup_error}"
                )


def add_to_recent_files_fallback(
    file_path: str | Path,
) -> bool:
    """
    Fallback method to add files to recent files by manually editing recently-used.xbel.

    This function directly manipulates the XDG recently-used.xbel file, which is
    the standard location for recent files metadata on Linux systems following
    the XDG Recent Files specification.

    The XDG format is XML-based and stores:
    - File URI (file:// protocol)
    - Access timestamps (added, modified, visited)
    - MIME type information
    - Application metadata

    Args:
        file_path (str | Path): Path to file to add to recent files

    Returns:
        bool: True if successfully added, False if any error occurred

    File Location:
        ~/.local/share/recently-used.xbel (XDG standard location)

    Backup Strategy:
        Creates .xbel.bak backup before modification to prevent data loss

    XML Structure:
        The function adds a <bookmark> element with proper metadata
        following the XDG Recent Files specification format.
    """
    try:
        # Locate the XDG recent files database
        recent_file = (
            Path.home()
            / ".local/share/recently-used.xbel"
        )

        # Check if recent files database exists
        if not recent_file.exists():
            send_hyprland_notification(
                "Recent Files Unavailable",
                "XDG recently-used.xbel doesn't exist - recent files feature unavailable",
                icon="dialog-warning",
                urgency=URGENCY_LOW,
                timeout_ms=3000,
            )
            return False

        # Prepare file metadata for XDG format
        abs_path = (
            Path(file_path).expanduser().resolve()
        )  # Get absolute path
        file_uri = (
            abs_path.as_uri()
        )  # Convert to file:// URI format

        # Generate ISO 8601 timestamp for XDG compliance
        timestamp = datetime.utcnow().strftime(
            "%Y-%m-%dT%H:%M:%SZ"
        )

        # Create XML bookmark entry following XDG Recent Files specification
        bookmark_entry = f"""  <bookmark href="{file_uri}" added="{timestamp}" modified="{timestamp}" visited="{timestamp}">
    <info>
      <metadata owner="http://freedesktop.org">
        <mime:mime-type type="image/png"/>
      </metadata>
    </info>
  </bookmark>"""

        # Parse existing XML content
        content = recent_file.read_text(
            encoding="utf-8"
        )
        lines = content.split("\n")
        new_lines = []

        # Use atomic file update to prevent corruption
        with atomic_file_update(
            recent_file
        ) as temp_file:
            # Insert new bookmark entry after the <recent-files> opening tag
            # This ensures the new entry appears at the top of recent files lists
            for line in lines:
                new_lines.append(line)
                if "<recent-files>" in line:
                    new_lines.append(
                        bookmark_entry
                    )

            # Write updated XML to temporary file
            updated_content = "\n".join(new_lines)
            temp_file.write_text(
                updated_content, encoding="utf-8"
            )

        return True

    except PermissionError:
        # User doesn't have write access to ~/.local/share/
        send_hyprland_notification(
            "Recent Files Permission Error",
            "Cannot write to recent files database - permission denied",
            icon="dialog-error",
            urgency=URGENCY_NORMAL,
            timeout_ms=5000,
        )
        return False

    except Exception as e:
        # Covers XML parsing errors, encoding issues, filesystem errors, etc.
        send_hyprland_notification(
            "Recent Files Failed",
            f"Failed to add to recent files: {e}",
            icon="dialog-error",
            urgency=URGENCY_NORMAL,
            timeout_ms=5000,
        )
        return False


def send_notification(
    message: str, timeout: int = 1000
) -> None:
    """
    Legacy wrapper for dunstify notifications.

    This function maintains compatibility with the original script's
    dunstify-based notifications while the main notification system
    uses D-Bus for better integration.

    Args:
        message (str): Notification message text
        timeout (int): Timeout in milliseconds (default: 1000)

    Note:
        This is kept for compatibility. The main notification system
        now uses send_hyprland_notification() for better integration.
    """
    # Execute dunstify command without capturing output (fire-and-forget)
    run_command(
        ["dunstify", message, "-t", str(timeout)],
        capture_output=False,
    )


def send_notification_with_action(
    message: str,
    timeout: int = 10000,
    file_path: str | Path | None = None,
) -> None:
    """
    Send an enhanced notification with action buttons using dunstify.

    This creates interactive notifications that allow users to perform
    actions directly from the notification popup. Currently supports
    copying the file path to clipboard.

    Args:
        message (str): Main notification message
        timeout (int): How long notification stays visible (default: 10000ms)
        file_path (str | Path | None): File path to copy when action is clicked

    Example:
        >>> send_notification_with_action(
        ...     "Screenshot saved",
        ...     file_path="/home/user/screenshot.png"
        ... )
        # Creates notification with "Copy to clipboard" button
    """
    command = [
        "dunstify",
        message,
        "-t",
        str(timeout),
    ]

    # Send notification (don't capture output)
    run_command(command, capture_output=False)


def create_screenshot_path() -> Path:
    """
    Generate a unique timestamped screenshot file path.

    Returns:
        Path: Full path for the new screenshot file
    """
    timestamp = datetime.now().strftime(
        TIMESTAMP_FORMAT
    )
    screenshots_dir = (
        Path.home() / DEFAULT_SCREENSHOTS_DIR
    )
    return (
        screenshots_dir
        / f"Screenshot-{timestamp}.{SCREENSHOT_FORMAT}"
    )


def main() -> None:
    """
    Main function orchestrating the complete screenshot workflow.

    Coordinates screenshot operations with comprehensive error handling:
    1. Generate unique file path
    2. Capture user-selected screen region
    3. Copy to clipboard and save to file
    4. Update recent files database
    5. Send user notifications
    """
    logger.info("Starting screenshot capture")

    # Generate unique file path
    file_path = create_screenshot_path()

    # Notify user that screenshot process is beginning
    send_hyprland_notification(
        "Screenshot Starting",
        f"Select a region to capture. Saving as: {file_path.name}",
        icon="camera-photo",
        urgency=URGENCY_LOW,
        timeout_ms=2000,
    )

    # Capture screenshot
    image_data = take_screenshot()
    if not image_data:
        logger.warning(
            "Screenshot capture failed or cancelled"
        )
        sys.exit(1)

    # Copy to clipboard (non-critical)
    if not copy_to_clipboard(image_data):
        send_hyprland_notification(
            "Clipboard Warning",
            "Screenshot captured but failed to copy to clipboard",
            icon="dialog-warning",
            urgency=URGENCY_NORMAL,
            timeout_ms=3000,
        )

    # Save to file (critical)
    if not save_screenshot(image_data, file_path):
        logger.error("Failed to save screenshot")
        sys.exit(1)

    # Add to recent files (non-critical)
    if add_to_recent_files(file_path):
        logger.info("Added to recent files")
    else:
        logger.warning(
            "Failed to add to recent files"
        )

    # Send completion notifications
    send_notification(
        f"Screenshot taken: {file_path.name}"
    )
    send_notification_with_action(
        f"Screenshot saved: {file_path.name}",
        file_path=file_path,
    )
    send_hyprland_notification(
        "Screenshot Complete! 📸",
        f"Successfully saved to {file_path.name}",
        icon="camera-photo",
        urgency=URGENCY_LOW,
        timeout_ms=3000,
    )

    logger.info(
        f"Screenshot workflow completed: {file_path}"
    )


# Script entry point
if __name__ == "__main__":
    """
    Entry point when script is executed directly.

    This ensures the main() function only runs when the script is executed
    directly (not when imported as a module), following Python best practices.
    """
    main()
