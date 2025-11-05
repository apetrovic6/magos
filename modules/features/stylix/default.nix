

{ inputs, ... }:{
flake.nixosModules.stylix = {config, lib, pkgs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

      magos.core.stylix.enable = lib.mkDefault true;
};

  flake.homeManagerModules.stylix = {config, lib, pkgs, ... }: {
    magos.hm.stylix.enable = lib.mkDefault true;
  };
}
