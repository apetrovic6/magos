
{ inputs,self, ... }:{

# flake.nixosModules.terminal = {config, lib, pkgs, ...}:
#   {
#       environment.systemPackages = with pkgs; [
#         ghostty
#       ];
#   };

flake.homeManagerModules.default = {config, lib, pkgs, ... }:
  {
      imports = [ self.homeModules.ghostty ];

      magos.hm.ghostty.enable = lib.mkDefault true;
  };
}
