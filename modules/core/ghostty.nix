{ inputs, ... }:{
flake.homeModules.ghostty = {config, lib, pkgs, ... }:
let
  cfg = config.magos.hm.ghostty;
in
{
  options.magos.hm.ghostty.enable = lib.mkEnableOption "Install ghostty";

  config = lib.mkIf cfg.enable {
        programs.wezterm = {
          enable = true;
        };
  };
};
}
