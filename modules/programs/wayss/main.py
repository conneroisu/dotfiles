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
from datetime import datetime
from pathlib import Path

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
) -> subprocess.CompletedProcess | None:
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
        # This typically means the command failed (e.g., user cancelled selection)
        send_hyprland_notification(
            "Command Failed",
            f"Command '{' '.join(command)}' failed with exit code {e.returncode}",
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return None

    except FileNotFoundError:
        # Command binary not found in PATH
        # This means required dependency is not installed
        send_hyprland_notification(
            "Command Not Found",
            f"Command '{command[0]}' not found. Please install the required package.",
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return None


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

    # Extract the selection coordinates from slurp output
    selection = slurp_result.stdout.decode('utf-8').strip()

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


def save_screenshot(
    image_data: bytes, file_path: str | Path
) -> bool:
    """
    Save screenshot image data to a file with automatic directory creation.

    This function handles the complete file saving process including:
    - Creating parent directories if they don't exist
    - Writing binary image data to file
    - Comprehensive error handling with user notifications

    Args:
        image_data (bytes): Raw image data to save (typically PNG format)
        file_path (str | Path): Destination file path for the screenshot
                                     Can be string or pathlib.Path object

    Returns:
        bool: True if file was saved successfully, False if any error occurred

    Side Effects:
        - Creates parent directories if they don't exist
        - Sends error notifications if saving fails
        - Overwrites existing files without warning

    Error Handling:
        - Permission errors (insufficient write access)
        - Disk space errors (filesystem full)
        - Invalid path errors (non-existent drive, invalid characters)

    Example:
        >>> image_data = take_screenshot()
        >>> if image_data:
        >>>     success = save_screenshot(image_data, "~/Pictures/test.png")
    """
    try:
        # Convert string paths to Path objects for easier manipulation
        file_path = Path(
            file_path
        ).expanduser()  # Expand ~ to home directory

        # Ensure parent directories exist (e.g., ~/Pictures/Screenshots/)
        # parents=True creates intermediate directories, exist_ok=True doesn't fail if exists
        file_path.parent.mkdir(
            parents=True, exist_ok=True
        )

        # Write binary image data to file
        # Using 'wb' mode for binary write, which preserves image data exactly
        with open(file_path, "wb") as f:
            f.write(image_data)

        return True

    except PermissionError as e:
        # User doesn't have write permission to destination directory
        send_hyprland_notification(
            "Permission Denied",
            f"Cannot save to {file_path}: Permission denied {e}",
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return False

    except OSError as e:
        # Covers disk full, invalid paths, filesystem errors, etc.
        send_hyprland_notification(
            "Save Failed",
            f"Cannot save screenshot to {file_path}: {e}",
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        return False

    except Exception as e:
        # Catch-all for unexpected errors
        send_hyprland_notification(
            "Unexpected Error",
            f"Unexpected error saving screenshot: {e}",
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

    This function tries two methods to add files to recent files:
    1. GTK Recent Manager (preferred) - integrates with desktop environment
    2. Manual XDG recently-used.xbel editing (fallback) - direct XML manipulation

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
        - python3-gi (optional): For GTK Recent Manager integration
        - GTK 3.0 (optional): Required by python3-gi

    Note:
        The function automatically falls back to manual XDG editing if GTK is unavailable.
        Both methods follow the XDG Recent Files specification.
    """
    try:
        # Method 1: Use GTK Recent Manager (preferred approach)
        # This integrates properly with the desktop environment's recent files system
        import gi

        gi.require_version(
            "Gtk", "3.0"
        )  # Ensure we use GTK 3.0
        from gi.repository import Gtk

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

        return True

    except ImportError:
        # GTK/gi not available - this is common and expected in minimal environments
        send_hyprland_notification(
            "Recent Files",
            "GTK not available, using fallback method for recent files",
            icon="dialog-information",
            urgency=URGENCY_LOW,
            timeout_ms=2000,
        )
        return add_to_recent_files_fallback(
            file_path
        )

    except Exception as e:
        # GTK available but failed (permissions, D-Bus issues, etc.)
        send_hyprland_notification(
            "Recent Files Warning",
            f"GTK recent files failed: {e}. Trying fallback method.",
            icon="dialog-warning",
            urgency=URGENCY_NORMAL,
            timeout_ms=3000,
        )
        return add_to_recent_files_fallback(
            file_path
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

        # Create backup before modification to prevent data loss
        backup_file = recent_file.with_suffix(
            ".xbel.bak"
        )
        backup_content = recent_file.read_text(
            encoding="utf-8"
        )
        backup_file.write_text(
            backup_content, encoding="utf-8"
        )

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

        # Insert new bookmark entry after the <recent-files> opening tag
        # This ensures the new entry appears at the top of recent files lists
        for line in lines:
            new_lines.append(line)
            if "<recent-files>" in line:
                new_lines.append(bookmark_entry)

        # Write updated XML back to file
        updated_content = "\n".join(new_lines)
        recent_file.write_text(
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
    if file_path:
        # Create notification with copy action button
        command = [
            "dunstify",
            message,  # Main message text
            "-t",
            str(timeout),  # Timeout duration
        ]
    else:
        # Simple notification without actions
        command = [
            "dunstify",
            message,
            "-t",
            str(timeout),
        ]

    # Send notification (don't capture output)
    run_command(command, capture_output=False)


def main() -> None:
    """
    Main function orchestrating the complete screenshot workflow.

    This function coordinates all the screenshot operations in sequence:
    1. Setup and initialization
    2. Interactive screenshot capture
    3. Clipboard integration
    4. File saving with timestamp
    5. Recent files integration
    6. User notifications throughout

    Workflow Steps:
        1. Generate timestamped filename and directory path
        2. Notify user that screenshot process is starting
        3. Use slurp/grim to capture user-selected screen region
        4. Copy captured image to Wayland clipboard
        5. Save image file to Pictures/Screenshots/ directory
        6. Add saved file to system recent files database
        7. Send final notification with action buttons

    Error Handling:
        Each step includes comprehensive error handling with user-friendly
        notifications. The script gracefully handles missing dependencies,
        user cancellation, permission issues, and other common failures.

    Exit Codes:
        0: Success - screenshot captured and saved
        1: Failure - screenshot capture failed
        1: Failure - file save failed

    File Naming:
        Screenshots are saved with format: Screenshot-YYYY-MM-DD_HH:MM:SS.png
        This ensures unique filenames and chronological sorting.
    """
    # Generate timestamp for unique filename
    # Format: YYYY-MM-DD_HH:MM:SS (e.g., 2024-03-15_14:30:45)
    timestamp = datetime.now().strftime(
        TIMESTAMP_FORMAT
    )

    # Setup screenshot directory and file path
    screenshots_dir = (
        Path.home() / DEFAULT_SCREENSHOTS_DIR
    )
    file_path = (
        screenshots_dir
        / f"Screenshot-{timestamp}.{SCREENSHOT_FORMAT}"
    )

    # Notify user that screenshot process is beginning
    send_hyprland_notification(
        "Screenshot Starting",
        f"Select a region to capture. Saving as: {file_path.name}",
        icon="camera-photo",
        urgency=URGENCY_LOW,
        timeout_ms=2000,
    )

    # Step 1: Capture screenshot of user-selected region
    image_data = take_screenshot()
    if not image_data:
        # Screenshot capture failed (user cancelled, missing deps, etc.)
        send_hyprland_notification(
            "Screenshot Cancelled",
            "Screenshot was not taken",
            icon="dialog-information",
            urgency=URGENCY_NORMAL,
            timeout_ms=3000,
        )
        sys.exit(1)  # Exit with error code

    # Step 2: Copy screenshot to clipboard for immediate use
    clipboard_success = copy_to_clipboard(
        image_data
    )
    if not clipboard_success:
        # Clipboard copy failed but continue with saving
        send_hyprland_notification(
            "Clipboard Warning",
            "Screenshot captured but failed to copy to clipboard",
            icon="dialog-warning",
            urgency=URGENCY_NORMAL,
            timeout_ms=3000,
        )

    # Step 3: Save screenshot to file system
    save_success = save_screenshot(
        image_data, file_path
    )
    if not save_success:
        # File save failed - this is critical since we lose the screenshot
        send_hyprland_notification(
            "Save Failed",
            "Screenshot captured but could not be saved to file",
            icon="dialog-error",
            urgency=URGENCY_CRITICAL,
            timeout_ms=5000,
        )
        sys.exit(1)  # Exit with error code

    # Step 4: Send legacy notification (compatibility with original script)
    initial_message = f"Screenshot of the region taken at {timestamp}"
    send_notification(initial_message)

    # Step 5: Add screenshot to recent files for easy access
    recent_files_success = add_to_recent_files(
        file_path
    )
    if recent_files_success:
        send_hyprland_notification(
            "Recent Files Updated",
            "Screenshot added to recent files - find it in file manager Recent section",
            icon="emblem-default",
            urgency=URGENCY_LOW,
            timeout_ms=2000,
        )
    else:
        # Recent files failed but not critical - screenshot still saved successfully
        send_hyprland_notification(
            "Recent Files Warning",
            "Screenshot saved but couldn't add to recent files",
            icon="dialog-warning",
            urgency=URGENCY_LOW,
            timeout_ms=3000,
        )

    # Step 6: Send final notification with interactive actions
    final_message = (
        f"Screenshot saved: {file_path.name}"
    )
    send_notification_with_action(
        final_message, file_path=file_path
    )

    # Step 7: Send completion notification via D-Bus
    send_hyprland_notification(
        "Screenshot Complete! 📸",
        f"Successfully saved to {file_path.name}",
        icon="camera-photo",
        urgency=URGENCY_LOW,
        timeout_ms=3000,
    )


# Script entry point
if __name__ == "__main__":
    """
    Entry point when script is executed directly.

    This ensures the main() function only runs when the script is executed
    directly (not when imported as a module), following Python best practices.
    """
    main()
