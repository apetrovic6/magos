{self, ...}: {
  flake.nixosModules.desktop = {pkgs, ...}: {
    imports = [
      self.nixosModules.niri
      self.nixosModules.stylix
    ];
  };
}
