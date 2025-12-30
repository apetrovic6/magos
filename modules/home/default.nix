{self, ...}: {
  flake.nixosModules.default = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.nixosModules.hyprland
      self.nixosModules.feature-stylix
      # add more modules here later (networking, hyprland, etc.)
    ];

    networking.wireless.enable =  lib.mkForce false;
    networking.wireless.iwd.enable = true;

    # Optional soft defaults (easy to override without mkForce)
    # magos.stylix.polarity = lib.mkDefault "dark";
    environment.systemPackages = with pkgs; [impala];
  };

  flake.homeManagerModules.default = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault;
  in {
    imports = [
      self.homeModules.ghostty

      self.homeManagerModules.hyprland

      self.homeModules.features-walker
      self.homeModules.noctalia
      self.homeModules.waybar
      self.homeModules.swaync
      self.homeModules.swayosd

      self.homeModules.features-hyprlock
      self.homeModules.features-hypridle
      self.homeModules.features-stylix
      self.homeManagerModules.hyprpanel
    ];

    magos.hm.core.swayosd.enable = lib.mkDefault true;
    magos.hm.core.swaync.enable = lib.mkDefault true;
    magos.hm.core.waybar.enable = lib.mkDefault true;
    magos.hm.hyprlock.enable = lib.mkDefault true;
    magos.hm.noctalia.enable = mkDefault false;
    magos.hm.core.hyprland.enable = mkDefault true;
    magos.hm.core.hyprpanel.enable = mkDefault false;
    magos.hm.core.ghostty.enable = mkDefault true;
  };
}
