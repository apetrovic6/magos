
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
        inputs.walker.homeManagerModules.default

        self.homeModules.ghostty 
        self.homeModules.starship
        self.homeModules.walker
      ];

        nix.settings = {
            extra-substituters = ["https://walker.cachix.org" "https://walker-git.cachix.org"];
            extra-trusted-public-keys = ["walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM=" "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="];
        };

      magos.hm.ghostty.enable = lib.mkDefault true;
      magos.hm.starship.enable = lib.mkDefault true;
      magos.hm.walker.enable = lib.mkDefault true;
  };
}
