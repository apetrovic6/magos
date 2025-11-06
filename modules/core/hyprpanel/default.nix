{ ... }:
{
  flake.homeManagerModules.hyprpanel =
    { lib, config, pkgs, ... }:
    let
      cfg = config.magos.hm.core.hyprpanel;

      # Stylix font fallback (works even if Stylix isn't present)
      hasStylixFonts = lib.hasAttrByPath [ "stylix" "fonts" ] config;
      fontName  = if hasStylixFonts then config.stylix.fonts.monospace.name else "monospace";
      fontSize  = if hasStylixFonts then "${toString config.stylix.fonts.sizes.desktop}px" else "10px";

      # We sometimes need mkForce here because upstream hyprpanel sets a *string*,
      # while we want an attrset { background.opacity = ... }.
      hoverAttr = { background.opacity = cfg.hoverOpacity; };
      forceOrId = if cfg.forceHoverOverride then lib.mkForce else lib.id;
    in
    {
      options.magos.hm.core.hyprpanel = {
        enable = lib.mkEnableOption "Enable Hyprpanel with sane defaults";

        systemdEnable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Hyprpanel user systemd service.";
        };

        hoverOpacity = lib.mkOption {
          type = lib.types.ints.between 0 100;
          default = 50;
          description = "Bar button hover background opacity (0–100).";
        };

        forceHoverOverride = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Use mkForce on theme.bar.buttons.hover to override upstream's string value.
            Keep this true if you see “... is defined multiple times” errors.
          '';

        };

        transparentBar = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Make the bar background transparent.";
        };

        enableBorders = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable bar button borders.";
        };

        layouts = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {
            "*" = {
              left   = [ "dashboard" "workspaces" "media" "cava" ];
              middle = [ "clock" ];
              right  = [ "volume" "network" "bluetooth" "battery" "notifications" "kbinput" "systray" ];
            };
          };
          description = "Per-monitor Hyprpanel layouts.";
        };

        extraSettings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {};
          description = "Additional settings merged into programs.hyprpanel.settings.";
        };
      };

      config = lib.mkIf cfg.enable {
        programs.hyprpanel = {
          enable = true;
          systemd.enable = cfg.systemdEnable;

          settings = lib.mkMerge [
            {
              scalingPriority = "hyprland";

              bar = {
                layouts = cfg.layouts;

                launcher.autoDetectIcon = true;

                workspaces = {
                  monitorSpecific = false;
                  show_icons = true;
                };

                bluetooth.label = true;
              };

              menus.clock = {
                time = {
                  military = true;
                  hideSeconds = true;
                };
                weather.unit = "metric";
              };

              menus.dashboard = {
                directories.enabled = false;
                stats.enable_gpu = false;
              };

              theme = {
                bar = {
                  transparent = cfg.transparentBar;
                  buttons = {
                    enableBorders = cfg.enableBorders;
                    hover = (forceOrId hoverAttr);
                  };
                };
              };

              osd = {
                orientation = "horizontal";
                location = "bottom";
                margins = "7px 7px 70px 7px";
                enableShadow = true;
                muteVolumeAsZero = true;
              };

              volume.allowRaisingVolumeAbove100 = false;

              font = {
                name = fontName;
                size = fontSize;
              };
            }

            # Let callers extend/override anything:
            cfg.extraSettings
          ];
        };
      };
    };
}
