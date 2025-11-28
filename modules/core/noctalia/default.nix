{self, ...}: {
  flake.homeModules.noctalia = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) types mkOption mkIf mkEnableOption;
    c = config.magos.palette;
    cfg = config.magos.hm.noctalia;
  in {
    imports = [
      self.inputs.noctalia.homeModules.default
      # ../../theme/palette.nix
    ];

    options.magos.hm.noctalia = {
      enable = mkEnableOption "Enable Noctalia Shell";
    };

    config = mkIf cfg.enable {
      programs.noctalia-shell = {
        enable = true;

        systemd.enable = true;

        settings = {
          wallpaper.enabled = false;
          bar = {
            density = "mini";
            position = "top";
            floating = true;
            marginVertical = 0.25;
            opacity = config.stylix.opacity.desktop;
            showCapsule = true;

            widgets = {
              left = [
                {
                  id = "SidePanelToggle";
                  useDistroLogo = true;
                  colorizeDistroLogo = false;
                }

                {
                  it = "AudioVisualizer";
                }

                {
                  hideUnoccupied = false;
                  id = "Workspace";
                  labelMode = "none";
                }
                {
                  id = "MediaMini";
                }
              ];
              center = [
                {
                  formatHorizontal = "HH:mm";
                  formatVertical = "HH mm";
                  id = "Clock";
                  useMonospacedFont = true;
                  usePrimaryColor = true;
                }
              ];
              right = [
                {
                  alwaysShowPercentage = false;
                  id = "Battery";
                  warningThreshold = 30;
                }

                {
                  id = "Tray";
                }

                {
                  id = "Volume";
                }

                {
                  id = "WiFi";
                }
                {
                  id = "Bluetooth";
                }

                {
                  id = "SystemMonitor";
                }

                {
                  id = "KeyboardLayout";
                }

                {
                  id = "NotificationHistory";
                }

                {
                  id = "SessionMenu";
                }
              ];
            };
          };

          osd = {
            enabled = true;
            location = "bottom_center";
          };

          nightLight = {
            enabled = false;
            forced = false;
            autoSchedule = true;
            nightTemp = "4000";
            dayTemp = "6500";
            manualSunrise = "06:30";
            manualSunset = "18:30";
          };

          general = {};

          location = {
          };
        };

        colors = {
          mError = "#${config.lib.stylix.colors.base08}";
          mOnError = "#${config.lib.stylix.colors.base00}";
          mOnPrimary = "#${config.lib.stylix.colors.base05}";
          mOnSecondary = "#${config.lib.stylix.colors.base06}";
          mOnSurface = "#${config.lib.stylix.colors.base06}";
          mOnSurfaceVariant = "#${config.lib.stylix.colors.base04}";
          mOnTertiary = "#${config.lib.stylix.colors.base07}";
          mOnHover = "#${config.lib.stylix.colors.base05}";
          mOutline = "#${config.lib.stylix.colors.base04}";
          mPrimary = "#${config.lib.stylix.colors.base06}";
          mSecondary = "#${config.lib.stylix.colors.base04}";
          mShadow = "#${config.lib.stylix.colors.base00}";
          mSurface = "#${config.lib.stylix.colors.base00}";
          mHover = "#${config.lib.stylix.colors.base0B}";
          mSurfaceVariant = "#${config.lib.stylix.colors.base01}";
          mTertiary = "#${config.lib.stylix.colors.base07}";
        };
      };
    };
  };
}
