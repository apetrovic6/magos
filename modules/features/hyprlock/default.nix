{
  inputs,
  self,
  ...
}: {
  flake.homeManagerModules.hyprlock = {
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
