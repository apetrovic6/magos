{self, ...}: {
  flake.homeModules.features-hyprlock = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.homeModules.hyprlock
    ];

    magos.hm.hyprlock.enable = lib.mkDefault true;
  };
}
