
# modules/features/stylix/default.nix (or wherever you keep it)
{ self, inputs, lib, ... }:
{
  # NixOS bundle
  flake.nixosModules.stylix = { ... }: {
    imports = [
      inputs.stylix.nixosModules.stylix
      self.nixosModules.core.stylix
    ];
    magos.core.stylix.enable = lib.mkDefault true;  # optional opinion
  };

  # Home bundle
  flake.homeManagerModules.stylix = { ... }: {
    imports = [
      inputs.stylix.homeModules.stylix
      self.homeModules.core.stylix
    ];
    # magos.hm.core.stylix.enable = lib.mkDefault true;  # optional
  };
}

