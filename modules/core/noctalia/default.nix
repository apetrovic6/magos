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
          settingsVersion = 25;
          changelog.lastSeenVersion = "3.4.0-git";

          wallpaper = {
            enabled = true;
            defaultWallpaper = lib.mkForce config.stylix.image;
          };
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
                  usePrimaryColor = false;
                }
              ];
              right = [
                {
                  alwaysShowPercentage = true;
                  id = "Battery";
                  warningThreshold = 30;
                  displayMode = "alwaysShow";
                }

                {
                  id = "Tray";
                }

                {
                  id = "Volume";
                  displayMode = "alwaysShow";
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
                  displayMode = "forceOpen";
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

          ui = {
            fontDefault = config.stylix.fonts.monospace.name;
            fontFixed = config.stylix.fonts.monospace.name;
            tooltipsEnabled = true;
            panelBackgroundOpacity = 1;
            panelsAttachedToBar = false;
            settingsPanelsAttachToBar = false;
          };

          calendar = {
            cards = [
              {
                id = "banner-card";
                enabled = true;
              }
              {
                id = "calendar-card";
                enabled = true;
              }
              {
                id = "timer-card";
                enabled = false;
              }
              {
                id = "weather-card";
                enabled = true;
              }
            ];
          };

          dock.enabled = false;

          sessionMenu = {
            showHeader = false;
            powerOptions = [
              {
                action = "lock";
                enabled = true;
              }
              {
                action = "suspend";
                enabled = true;
              }
              {
                action = "hibernate";
                enabled = false;
              }
              {
                action = "reboot";
                enabled = true;
              }
              {
                action = "logout";
                enabled = true;
              }
              {
                action = "shutdown";
                enabled = true;
              }
            ];
          };

          controlCenter = {
            position = "close_to_bar_button";
            shortcuts = {
              left = [
              ];
              right = [
                {
                  id = "ScreenRecorder";
                }
                {
                  id = "Notifications";
                }
                {
                  id = "PowerProfile";
                }
                {
                  id = "KeepAwake";
                }
                {
                  id = "NightLight";
                }
              ];
            };
            cards = [
              {
                enabled = true;
                id = "profile-card";
              }
              {
                enabled = true;
                id = "shortcuts-card";
              }
              {
                enabled = false;
                id = "audio-card";
              }
              {
                enabled = false;
                id = "weather-card";
              }
              {
                enabled = false;
                id = "media-sysmon-card";
              }
            ];
          };
        };

        colors = {
          # Semantic
          mError = "#${config.lib.stylix.colors.base08}";
          mOnError = "#${config.lib.stylix.colors.base00}";

          # Accents
          mPrimary = "#${config.lib.stylix.colors.base0D}";
          mOnPrimary = "#${config.lib.stylix.colors.base00}";
          mSecondary = "#${config.lib.stylix.colors.base0E}";
          mOnSecondary = "#${config.lib.stylix.colors.base00}";
          mTertiary = "#${config.lib.stylix.colors.base0B}";
          mOnTertiary = "#${config.lib.stylix.colors.base00}";

          # Surfaces
          mSurface = "#${config.lib.stylix.colors.base00}";
          mOnSurface = "#${config.lib.stylix.colors.base05}";
          mSurfaceVariant = "#${config.lib.stylix.colors.base01}";
          mOnSurfaceVariant = "#${config.lib.stylix.colors.base04}";

          # Hover & utilities
          mHover = "#${config.lib.stylix.colors.base02}";
          mOnHover = "#${config.lib.stylix.colors.base05}";
          mOutline = "#${config.lib.stylix.colors.base03}";
          mShadow = "#${config.lib.stylix.colors.base00}";
        };
      };
    };
  };
}
