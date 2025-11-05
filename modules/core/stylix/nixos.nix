{inputs, ... }:{
flake.nixosModules.stylix = {config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption mkEnableOption types;
  cfg = config.magos.core.stylix;
in
  {
  options.magos.core.stylix = {
      enable = mkEnableOption "Install and setup Stylix";

      image = mkOption {
      type = types.path;
      description = "Path to the wallpaper image to use.";
    };


    polarity = mkOption {
      type = types.enum [ "light" "dark" ];
      default = "dark";
      description = "Polarity of the theme.";
    };
  };

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      image = cfg.image;
      polarity = cfg.polarity;

      targets.regreet = {
        enable = true;
        useWallpaper = true;
      };

     cursor = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        size = 24;
      };
    };
   };
  };
}

