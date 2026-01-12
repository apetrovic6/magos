{...}: {
  flake.homeModules.walker-resolution-menu = {
    config,
    pkgs,
    lib,
    ...
  }: let
    # Script to list all available resolutions for all monitors
    resolutionListScript = pkgs.writeShellScriptBin "walker-resolution-list" ''
      set -euo pipefail

      # Get monitor data from hyprctl
      monitors_json=$(${pkgs.hyprland}/bin/hyprctl monitors -j)

      # Parse and display resolutions for each monitor
      echo "$monitors_json" | ${pkgs.jq}/bin/jq -r '
        .[] |
        .name as $monitor |
        .availableModes[] |
        "\($monitor)|\(.)"
      ' | while IFS='|' read -r monitor resolution; do
        # Parse resolution to get width, height, and refresh rate
        if [[ $resolution =~ ([0-9]+)x([0-9]+)@([0-9.]+)Hz ]]; then
          width="''${BASH_REMATCH[1]}"
          height="''${BASH_REMATCH[2]}"
          refresh="''${BASH_REMATCH[3]}"

          # Display format: "[Monitor] 1920x1080 @ 144Hz"
          printf "[%s] %sx%s @ %sHz\n" "$monitor" "$width" "$height" "$refresh"
        fi
      done
    '';

    # Script to apply resolution based on selection
    resolutionApplyScript = pkgs.writeShellScriptBin "walker-resolution-apply" ''
      set -euo pipefail

      # Input format: "[DP-2] 3840x2160 @ 120.00Hz"
      selection="$1"

      # Extract monitor name from brackets
      if [[ $selection =~ ^\[([^]]+)\] ]]; then
        monitor="''${BASH_REMATCH[1]}"
      else
        ${pkgs.libnotify}/bin/notify-send "Resolution Error" "Failed to parse monitor name"
        exit 1
      fi

      # Extract resolution (e.g., "3840x2160@120.00Hz")
      if [[ $selection =~ ([0-9]+)x([0-9]+)\ @\ ([0-9.]+)Hz ]]; then
        width="''${BASH_REMATCH[1]}"
        height="''${BASH_REMATCH[2]}"
        refresh="''${BASH_REMATCH[3]}"
        resolution="''${width}x''${height}@''${refresh}Hz"
      else
        ${pkgs.libnotify}/bin/notify-send "Resolution Error" "Failed to parse resolution"
        exit 1
      fi

      # Apply the resolution using hyprctl
      if ${pkgs.hyprland}/bin/hyprctl keyword monitor "$monitor,$resolution,auto,1"; then
        ${pkgs.libnotify}/bin/notify-send "Resolution Changed" "Set $monitor to $resolution"
      else
        ${pkgs.libnotify}/bin/notify-send "Resolution Error" "Failed to apply $resolution to $monitor"
        exit 1
      fi
    '';

    # Main resolution picker script that uses walker's dmenu mode
    resolutionPickerScript = pkgs.writeShellScriptBin "hypr-resolution-picker" ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Get all available resolutions
      resolutions=$(${resolutionListScript}/bin/walker-resolution-list)

      if [ -z "$resolutions" ]; then
        ${pkgs.libnotify}/bin/notify-send "Resolution Error" "No resolutions found"
        exit 1
      fi

      # Use walker in dmenu mode to select resolution
      selected=$(echo "$resolutions" | ${pkgs.walker}/bin/walker --dmenu)

      if [ -n "$selected" ]; then
        ${resolutionApplyScript}/bin/walker-resolution-apply "$selected"
      fi
    '';
  in {
    home.packages = [
      resolutionListScript
      resolutionApplyScript
      resolutionPickerScript
    ];

    # Create elephant menu for the resolution picker
    xdg.configFile."elephant/menus/resolution-menu.toml".text = ''
      name = "resolution-menu"
      name_pretty = "Display Resolution"
      icon = "video-display"

      action = "walker-resolution-apply %VALUE%"

      # Note: Elephant menus are static, so we'll use the dmenu approach instead
      # Users should bind this to a key: hypr-resolution-picker
      [[entries]]
      text = "Change Resolution"
      icon = "preferences-desktop-display"
      value = "hypr-resolution-picker"
    '';
  };
}
