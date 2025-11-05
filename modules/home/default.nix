
{ inputs,self, ... }:{

# flake.nixosModules.terminal = {config, lib, pkgs, ...}:
#   {
#       environment.systemPackages = with pkgs; [
#         ghostty
#       ];
#   };

flake.homeManagerModules.default = {config, lib, pkgs, ... }:
  {
      imports = [
        self.homeModules.ghostty 
        self.homeModules.starship
        self.homeModules.walker
      ];

      magos.hm.ghostty.enable = lib.mkDefault true;
      magos.hm.starship.enable = lib.mkDefault true;
      magos.hm.walker.enable = lib.mkDefault true;
  };
}
