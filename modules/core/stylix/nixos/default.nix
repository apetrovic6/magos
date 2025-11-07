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

          opacity = {
            terminal = 0.8;
            desktop = 0.5;
            popups = 0.5;
            applications = 0.5;
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

          cursor = {
            package = pkgs.adwaita-icon-theme;
            name = "Adwaita";
            size = 24;
          };

          targets.chromium.enable = true;
        }
        // optionalAttrs (cfg.image != null) {
          image = cfg.image;
        };
    };
  };
}
