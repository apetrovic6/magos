{self, ...}: {
  flake.homeModules.hyprland-binds = {
    config,
    lib,
    ...
  }: {
    imports = [
      self.homeModules.hyprland-bindings
      self.homeModules.hyprland-tiling
      self.homeModules.hyprland-media
    ];
  };
}
