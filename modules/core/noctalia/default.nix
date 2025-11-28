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
                  colorizeDistroLogo = true;
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
          mSurface = "#${config.lib.stylix.colors.base00}";
          mSurfaceVariant = "#${config.lib.stylix.colors.base01}";
          mOnSurface = "#${config.lib.stylix.colors.base05}";
          mOnSurfaceVariant = "#${config.lib.stylix.colors.base04}";

          mPrimary = "#${config.lib.stylix.colors.base0D}";
          mOnPrimary = "#${config.lib.stylix.colors.base00}";
          mSecondary = "#${config.lib.stylix.colors.base0E}";
          mOnSecondary = "#${config.lib.stylix.colors.base00}";
          mTertiary = "#${config.lib.stylix.colors.base0C}";
          mOnTertiary = "#${config.lib.stylix.colors.base00}";

          mHover = "#${config.lib.stylix.colors.base0B}";
          mOnHover = "#${config.lib.stylix.colors.base05}";

          mError = "#${config.lib.stylix.colors.base08}";
          mOnError = "#${config.lib.stylix.colors.base00}";

          mOutline = "#${config.lib.stylix.colors.base03}";
          mShadow = "#${config.lib.stylix.colors.base00}";
        };
      };
    };
  };
}
