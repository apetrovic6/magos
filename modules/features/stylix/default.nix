

{ inputs,self, ... }:{
flake.nixosModules.stylix = {config, lib, pkgs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix
    self.nixosModules.core.stylix
  ];

      #  magos.core.stylix.enable = lib.mkDefault true;
};

  flake.homeManagerModules.stylix = {config, lib, pkgs, ... }: {
    imports = [
      inputs.stylix.homeModules.stylix     # NOTE: homeModules per Stylix docs
    ];

    magos.hm.core.stylix.enable = lib.mkDefault true;
  };
}
