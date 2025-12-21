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
          windowrule = let
            size = "size 875 700";
          in [
            "float 1, center 1, ${size}, match:class (ghostty.audio)"
            "float 1, center 1, ${size}, match:class (ghostty.bluetooth)"
            "float 1, center 1, ${size}, match:class (ghostty.wifi)"
            "float 1, center 1, ${size}, match:class (ghostty.docker)"
            "float 1, center 1, ${size}, match:class (ghostty.filemanager)"
            "float 1, pin 1, size 500 300, match:title (Picture-in-Picture)"

            "opacity ${toString config.stylix.opacity.applications}, match:title (.*hx.*)"
            "opacity ${toString config.stylix.opacity.applications}, match:title (.*nvim.*)"
          ];

          layerrule = [
            "match:class walker, blur 1, blur_popups 1, ignore_alpha 0.5"
            "match:class walker, blur 1, blur_popups 1, ignore_alpha 0.5"
            "match:class swaync-control-center, blur 1, blur_popups 1, ignore_alpha 0.5"
            "match:class swaync-notification-window, blur 1, blur_popups 1, ignore_alpha 0.5"
            "match:class waybar, blur 1, blur_popups 1, ignore_alpha 0.5"
          ];
          decoration = {
            rounding = 10;

            inactive_opacity = config.stylix.opacity.applications - 0.01;
            # active_opacity = config.stylix.opacity.applications;

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
