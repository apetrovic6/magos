{...}: {
  flake.homeManagerModules.hypridle = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.magos.hm.core.hypridle;
  in {
    options.magos.hm.core.hypridle = {
      enable = lib.mkEnableOption "Enable Hypridle with sane defaults";

      systemdTarget = lib.mkOption {
        type = lib.types.str;
        default = "hyprland-session.target";
        description = "User systemd target Hypridle binds to.";
      };

      enableKeyboardBacklightRule = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Toggle the keyboard backlight listener rules.";
      };

      extraListeners = lib.mkOption {
        type = with lib.types; listOf attrs;
        default = [];
        description = "Extra Hypridle listener blocks to append.";
      };
    };

    config = lib.mkIf cfg.enable {
      # Needed for the brightness listeners
      home.packages = [pkgs.brightnessctl];

      services.hypridle = {
        enable = true;
        systemdTarget = cfg.systemdTarget;

        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };

          listener =
            [
              {
                timeout = 150; # 2.5 min
                "on-timeout" = "brightnessctl -s set 10";
                "on-resume" = "brightnessctl -r";
              }
            ]
            ++ lib.optionals cfg.enableKeyboardBacklightRule [
              {
                timeout = 150; # 2.5 min
                "on-timeout" = "brightnessctl -sd rgb:kbd_backlight set 0";
                "on-resume" = "brightnessctl -rd rgb:kbd_backlight";
              }
            ]
            ++ [
              {
                timeout = 300;
                "on-timeout" = "loginctl lock-session";
              } # 5 min
              {
                timeout = 1800;
                "on-timeout" = "systemctl suspend";
              } # 30 min
            ]
            ++ cfg.extraListeners;
        };
      };
    };
  };
}
