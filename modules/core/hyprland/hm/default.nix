
{ inputs, ... }:
{
  flake.homeManagerModules.hyprland =
    { lib, config, pkgs, ... }:
    let
      inherit (lib) mkEnableOption mkOption types mkIf optionals mkMerge;
      cfg  = config.magos.hm.core.hyprland;
      hypr = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      options.magos.hm.core.hyprland = {
        enable = mkEnableOption "Enable Hyprland (Home Manager)";

        systemdEnable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable user systemd integration for Hyprland.";
        };

        # Use Hyprland/portal from inputs.hyprland (recommended).
        useHyprlandInputFlake = mkOption {
          type = types.bool;
          default = true;
          description = "Use inputs.hyprland.packages.<system>.hyprland as the compositor package.";
        };

        # Decoration + blur
        rounding = mkOption {
          type = types.ints.unsigned;
          default = 10;
          description = "Corner rounding in px.";
        };

        blur = {
          enable = mkOption { type = types.bool;  default = true;  };
          size   = mkOption { type = types.ints.unsigned; default = 10; };
          passes = mkOption { type = types.ints.unsigned; default = 2;  };
          contrast = mkOption { type = types.float; default = 1.5; };
          ignoreOpacity   = mkOption { type = types.bool; default = true;  };
          newOptimizations = mkOption { type = types.bool; default = true;  };
          popups          = mkOption { type = types.bool; default = true;  };
        };

        # Walker blur rules
        enableWalkerBlurRules = mkOption {
          type = types.bool;
          default = true;
          description = "Add layerrule entries to blur the 'walker' layer surface.";
        };

        extraLayerrules = mkOption {
          type = with types; listOf str;
          default = [];
          description = "Additional layerrule lines to append.";
        };

        # Free-form settings merged last (your escape hatch)
        extraSettings = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = "Extra wayland.windowManager.hyprland.settings merged last.";
        };
      };

      config = mkIf cfg.enable {

          imports = [
            ./binds
            ./config
          ];

        wayland.windowManager.hyprland = mkMerge ([
          {
            enable = true;
            systemd.enable = cfg.systemdEnable;

            settings = {
              # Blur Walker’s layer surface
              layerrule =
                (optionals cfg.enableWalkerBlurRules [
                  "blur, walker"
                  "blurpopups, walker"
                  "ignorealpha 0.5, walker"
                ])
                ++ cfg.extraLayerrules;

              decoration = {
                rounding = cfg.rounding;
                blur = {
                  enabled          = cfg.blur.enable;
                  size             = cfg.blur.size;
                  passes           = cfg.blur.passes;
                  contrast         = cfg.blur.contrast;
                  ignore_opacity   = cfg.blur.ignoreOpacity;
                  new_optimizations= cfg.blur.newOptimizations;
                  popups           = cfg.blur.popups;
                };
              };
            };
          }

          # Merge any user-provided additions last
          { settings = cfg.extraSettings; }
        ] ++ (optionals cfg.useHyprlandInputFlake [
          { package = hypr.hyprland; }
        ]));
      };
    };
}
