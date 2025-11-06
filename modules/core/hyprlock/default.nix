{inputs, ...}: {
  flake.homeModules.hyprlock = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) types mkOption mkIf mkEnableOption;
    cfg = config.magos.hm.hyprlock;
  in {
    options.magos.hm.hyprlock = {
      enable = mkEnableOption "Enable and setup Hyprlock";
    };

    config = mkIf cfg.enable {
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            hide_cursor = true;
            ignore_empty_input = true;
          };

          label = [
            {
              text = "cmd[update:1000] echo $TIME";
              halign = "center";
              valign = "center";
              position = "0, 150";
              font_size = 64; # tweak to taste
              #font_family = config.stylix.fonts.monospace;   # or your favorite font
            }
          ];

          animations = {
            enabled = true;
            fade_in = {
              duration = 300;
              bezier = "easeOutQuint";
            };

            fade_out = {
              duration = 300;
              bezier = "easeOutQuint";
            };
          };

          background = lib.mkForce [
            {
              # keep using the wallpaper Stylix set
              path = config.stylix.image;

              # blur & tone settings — tweak to taste
              blur_passes = 3; # >0 enables blur
              blur_size = 7; # larger = stronger blur
            }
          ];
        };
      };
    };
  };
}
