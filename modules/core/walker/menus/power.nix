{ config, pkgs, ... }:

{
  # Main menu (omarchy-style)
  xdg.configFile."elephant/menus/omarchy-menu.toml".text = ''
    name = "omarchy-menu"
    name_pretty = "System Menu"
    icon = "applications-system"

    # When you hit Enter on an entry, run its `value` as a shell command
    action = "%VALUE%"

    [[entries]]
    text = "Apps"
    icon = "applications-other"
    value = "walker"  # plain Walker launcher

    [[entries]]
    text = "Files"
    icon = "system-file-manager"
    value = "thunar"  # or dolphin, nautilus, etc.

    [[entries]]
    text = "System"
    icon = "system-shutdown"
    # This opens another menu instead of running a command
    submenu = "omarchy-system"
  '';

  # System submenu (Lock / Suspend / Logout / Reboot / Shutdown)
  xdg.configFile."elephant/menus/omarchy-system.toml".text = ''
    name = "omarchy-system"
    name_pretty = "System Actions"
    icon = "system-shutdown"

    # Again: Enter → run the `value` command
    action = "%VALUE%"

    [[entries]]
    text = "Lock"
    icon = "system-lock-screen"
    value = "loginctl lock-session"

    [[entries]]
    text = "Suspend"
    icon = "system-suspend"
    value = "systemctl suspend"

    [[entries]]
    text = "Logout"
    icon = "system-log-out"
    # Hyprland logout; swap for uwsm / swaymsg / etc if needed
    value = "hyprctl dispatch exit"

    [[entries]]
    text = "Reboot"
    icon = "system-reboot"
    value = "systemctl reboot"

    [[entries]]
    text = "Shutdown"
    icon = "system-shutdown"
    value = "systemctl poweroff"
  '';
}

