
{ inputs, ... }:{
flake.homeManagerModules = {config, lib, pkgs, ... }:
  {
      options.magos.hm.ghostty.enable = true;
  };
}
