{inputs, ...}: {
  flake.homeModules.waybar = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) types mkOption mkEnableOption;
    cfg = config.magos.hm.core.waybar;
  in {
    options.magos.hm.core.waybar = {
      enable = mkEnableOption "Enable Waybar";
    };

    config = lib.mkIf cfg.enable {
      programs.waybar = {
        enable = cfg.enable;

        systemd.enable = true;
      };
    };
  };
}
