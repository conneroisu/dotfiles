# constants.nix - User Constants Configuration Module
#
# This module defines read-only user constants that are used throughout the configuration.
# These values are centralized here to ensure consistency across all modules and platforms.
#
# All constants are marked as read-only to prevent accidental modification during runtime.
# These values are used for:
# - User account creation and configuration
# - Git configuration
# - Email setup and identification
# - Home directory paths and permissions
#
# To modify these values, edit this file directly and rebuild the configuration.
{delib, ...}:
delib.module {
  name = "constants";

  options.constants = with delib; {
    # Primary username for the system (used for account creation and home directory)
    username = readOnly (strOption "connerohnesorge");

    # Full display name for the user (used in Git commits and system identification)
    userfullname = readOnly (strOption "Conner Ohnesorge");

    # Primary email address (used for Git commits, SSH keys, and notifications)
    useremail = readOnly (strOption "conneroisu@outlook.com");
  };
}
