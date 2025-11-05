
{ inputs, ... }:{
flake.homeModules.ghostty = {config, lib, pkgs, ... }:
  {
      options.magos.hm.ghostty.enable = true;
  };
}
