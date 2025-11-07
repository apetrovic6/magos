{
  inputs,
  self,
  ...
}: {
  flake.homeManagerModules.hyprland = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkOption types mkIf optionals mkMerge;
    cfg = config.magos.hm.core.hyprland;
    hypr = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    imports = [
      self.homeModules.hyprland-config
      self.homeModules.hyprland-binds
    ];

    options.magos.hm.core.hyprland = {
      enable = mkEnableOption "Enable Hyprland (Home Manager)";

      systemdEnable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable user systemd integration for Hyprland.";
      };

      rounding = mkOption {
        type = types.ints.unsigned;
        default = 10;
        description = "Corner rounding in px.";
      };

      blur = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };
        size = mkOption {
          type = types.ints.unsigned;
          default = 10;
        };
        passes = mkOption {
          type = types.ints.unsigned;
          default = 2;
        };
        contrast = mkOption {
          type = types.float;
          default = 1.5;
        };
        ignoreOpacity = mkOption {
          type = types.bool;
          default = true;
        };
        newOptimizations = mkOption {
          type = types.bool;
          default = true;
        };
        popups = mkOption {
          type = types.bool;
          default = true;
        };
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
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = true;
        # set the flake package
        package = self.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage = self.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

        settings = {
          # Blur Walker’s layer surface (namespace is “walker”)
          layerrule = [
            "blur, walker"
            "blurpopups, walker" # if Walker shows popups/tooltips
            "ignorealpha 0.5, walker" # reduces halo at fully transparent pixels
          ];
          decoration = {
            rounding = 10;

            blur = {
              enabled = true;
              size = 10;
              passes = 2;
              contrast = 1.5;
              ignore_opacity = true;
              new_optimizations = true;
              popups = true;
            };
          };
        };
      };
    };
  };
}
