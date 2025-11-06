
{ inputs,self, ... }:{

flake.nixosModules.default = {config, lib, pkgs, ...}:
  {
imports = [
      self.nixosModules.stylix
      # add more modules here later (networking, hyprland, etc.)
    ];

    # Optional soft defaults (easy to override without mkForce)
    magos.stylix.enable = lib.mkDefault true;
    # magos.stylix.polarity = lib.mkDefault "dark";
      environment.systemPackages = with pkgs; [
        wezterm
      ];
  };

flake.homeManagerModules.default = {config, lib, pkgs, ... }:
    let
      inherit (lib) mkDefault;
    in
  {
      imports = [
        # self.homeManagerModules.palette

        inputs.walker.homeManagerModules.default
        self.homeModules.ghostty 
        self.homeModules.starship


        self.homeManagerModules.walker
        self.homeManagerModules.hyprlock

      self.homeManagerModules.stylix
      ];

        nix.settings = {
            extra-substituters = ["https://walker.cachix.org" "https://walker-git.cachix.org"];
            extra-trusted-public-keys = ["walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM=" "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="];
        };

      magos.hm.core.ghostty.enable = mkDefault true;
      magos.hm.core.starship.enable = mkDefault true;
      magos.hm.stylix.enable = lib.mkDefault true;
      magos.hm.core.walker.enable = mkDefault true;
  };
}
