# The FULL nixarchy desktop: nixarchy's own NixOS and home-manager modules,
# as upstream ships them. Install/Remove/Update menus, the app selection in
# ~/.config/nixarchy/apps.nix, nixarchy-apply, preinstalls, default plugins,
# omatheme, Hyprforge -- all of it.
#
# The opposite of modules/features/omarchy.nix, which takes only nixarchy's
# package and rebuilds the session by hand. The two are alternatives: never
# import both on one machine (each registers an `omarchy` wayland session and
# sets programs.hyprland).
#
# ## What the consumer has to do, because magos cannot
#
# nixarchy's modules/nixos.nix imports home-manager, nix-flatpak and sops-nix
# itself. The module system dedupes imports by store path, so each one must be
# the SAME store path the consuming flake already imports, or every option they
# declare is declared twice and the machine stops evaluating. magos cannot see
# the consumer's inputs, so the follows live in the consumer's flake.nix:
#
#     magos.inputs.nixarchy.inputs = {
#       home-manager.follows = "home-manager";
#       nix-flatpak.follows = "nix-flatpak";
#       sops-nix.follows = "clan-core/sops-nix";
#     };
#
# ## What this module adds on top
#
# Only the three things nixarchy's doctor tells a machine like ours to set,
# plus wiring the home-manager half for one user:
#   - displayManager off by default: the machine keeps its own greeter
#   - one Hyprland, from this system's nixpkgs. nixarchy's `hyprland` input
#     brings its own nixpkgs, so Hyprland lands on an older glibc than mesa and
#     the session SIGABRTs a second in.
#   - autoUpdate stays off (its default): clan is the updater
{ self, ... }: {
  flake.nixosModules.nixarchy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.magos.nixarchy;
    in
    {
      imports = [
        self.inputs.nixarchy.nixosModules.nixarchy

        # Declare apps and services here instead of through the Install menu.
        # These are nixarchy's own options -- the menu only ever uncomments
        # lines that set them -- so an alias gives the same per-app types and
        # `settings`, with no file in $HOME and nothing to copy into the flake:
        #   magos.nixarchy.apps.zen.enable = true;
        #   magos.nixarchy.services.syncthing.enable = true;
        (lib.mkAliasOptionModule
          [ "magos" "nixarchy" "apps" ]
          [ "programs" "nixarchy" "apps" ]
        )
        (lib.mkAliasOptionModule
          [ "magos" "nixarchy" "services" ]
          [ "programs" "nixarchy" "services" ]
        )
      ];

      options.magos.nixarchy = {
        enable = lib.mkEnableOption "the full nixarchy (Omarchy) desktop";

        user = lib.mkOption {
          type = lib.types.str;
          example = "alice";
          description = ''
            The user who logs into the Omarchy session. Gets nixarchy's
            home-manager module, the `input` group, and omatheme.
          '';
        };

        home = lib.mkOption {
          type = lib.types.deferredModule;
          default = { };
          description = ''
            Extra home-manager configuration for `user`, merged next to
            nixarchy's home module -- `programs.nixarchy.defaultTheme`,
            `.defaultPlugins` and friends.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        programs.nixarchy = {
          enable = true;
          inherit (cfg) user;
          displayManager = lib.mkDefault false;
        };

        programs.hyprland = {
          package = lib.mkForce pkgs.hyprland;
          portalPackage = lib.mkForce pkgs.xdg-desktop-portal-hyprland;
        };

        home-manager.users.${cfg.user} = {
          imports = [
            self.inputs.nixarchy.homeManagerModules.nixarchy
            cfg.home
          ];
          programs.nixarchy.enable = true;
        };
      };
    };
}
