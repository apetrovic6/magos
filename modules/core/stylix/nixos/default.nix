# modules/stylix/nixos.nix
{inputs, ...}: {
  # Export a NixOS module at flake.nixosModules.stylix
  flake.nixosModules.stylix = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) mkIf mkOption mkEnableOption types optionalAttrs;
    cfg = config.magos.stylix;
  in {
    # Pull in the upstream Stylix NixOS module
    imports = [inputs.stylix.nixosModules.stylix];

    options.magos.stylix = {
      enable = mkEnableOption "Enable Stylix on this system";

      # Optional wallpaper; if unset, we won't pass it to Stylix
      image = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional wallpaper path for Stylix.";
      };

      base16Scheme = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Name of the base16 scheme from https://github.com/tinted-theming/schemes/tree/spec-0.11/base16";
      };

      polarity = mkOption {
        type = types.enum ["light" "dark"];
        default = "dark";
        description = "Theme polarity.";
      };
    };

    config = mkIf cfg.enable {
      stylix =
        {
          enable = true;
          polarity = cfg.polarity;
          # base16Scheme = mkIf cfg.base16Scheme.

          opacity = {
            terminal = 0.8;
            desktop = 0.8;
            popups = 0.8;
            applications = 0.8;
          };

          fonts = {
            monospace = {
              package = pkgs.nerd-fonts.jetbrains-mono;
              name = "jetbrains-mono";
            };

            sizes = {
              applications = 10;
              terminal = 10;
              desktop = 10;
              popups = 10;
            };
          };

          targets.regreet = {
            enable = true;
            useWallpaper = true;
          };

          targets.nvf = {
            enable = true;
          };

          cursor = {
            package = pkgs.adwaita-icon-theme;
            name = "Adwaita";
            size = 24;
          };

          targets.chromium.enable = true;
        }
        // optionalAttrs (cfg.image != null) {
          image = cfg.image;
        }
        // optionalAttrs (cfg.base16Scheme != null) {
          base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.base16Scheme}.yaml";
        };
    };
  };
}
