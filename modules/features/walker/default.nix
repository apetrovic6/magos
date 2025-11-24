{self, ...}: {
  flake.homeModules.features-walker = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.homeManagerModules.walker
    ];

    magos.hm.core.walker.enable = lib.mkDefault true;
  };
}
