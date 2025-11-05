
{ inputs,self, ... }:{
flake.homeManagerModules.default = {config, lib, pkgs, ... }:
  {
      imports = [ self.homeModules.ghostty ];

      magos.hm.ghostty.enable = false;
  };
}
