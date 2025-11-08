{self, ...}: {
  flake.nixosModules.feature-stylix = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.nixosModules.stylix
    ];

    magos.stylix.enable = lib.mkDefault true;
  };

  flake.homeModules.features-stylix = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.homeModules.stylix
    ];

    magos.hm.hyprlock.enable = lib.mkDefault true;
  };
}
