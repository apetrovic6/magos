{...}: {
  flake.homeModules.walker-menus = {
    config,
    pkgs,
    ...
  }: {
    # System submenu (Lock / Suspend / Logout / Reboot / Shutdown)
    xdg.configFile."elephant/menus/power-menu.toml".text = ''
      name = "power-menu"
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
      icon = "system-sleep"
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
  };
}
