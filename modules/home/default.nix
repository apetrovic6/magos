
{ inputs, ... }:{
flake.homeManagerModules = {config, lib, pkgs, ... }:
  {
      magos.hm.wezterm.enable = true;
  };
}
