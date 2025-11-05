{ inputs, ... }:{
flake.homeModules.wezterm = {config, lib, pkgs, ... }:
let
  cfg = config.magos.hm.wezterm;
in
{
  options.magos.hm.wezterm.enable = lib.mkEnableOption "Install wezterm";

  config = lib.mkIf cfg.enable {
        programs.wezterm = {
          enable = true;
        };
  };
};
}
