  {self, ...}: {
  flake.homeModules.features-hypridle = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault;
  in {
    imports = [
      self.homeManagerModules.hypridle
    ];

    magos.hm.core.hypridle.enable = mkDefault true;
  };
}
