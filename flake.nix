{
  description = "Magos DE";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    hyprland.url = "github:hyprwm/Hyprland";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix-w-plugins = {
      url = "github:mattwparas/helix/steel-event-system";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix-plugins.url = "github:maxschipper/helix-plugins-nix";

    # Developed out of tree at ~/clan/connect.hx. Published at
    # github:apetrovic6/connect.hx, but deliberately still a path: input so
    # local edits can be tested without pushing -- nix pins a path: input by
    # narHash, so a change there needs `nix flake update connect-hx` here
    # before a rebuild picks it up. Switch the url when that stops being
    # convenient. The follows keep its helixPlugins scope identical to the one
    # above, so run-command is not built twice.
    connect-hx = {
      url = "path:/home/apetrovic/clan/connect.hx";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.helix-plugins.follows = "helix-plugins";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    import-tree,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        (import-tree ./modules)
        inputs.treefmt-nix.flakeModule
        inputs.home-manager.flakeModules.home-manager
      ];

      flake.nixosModules.default = {
        pkgs,
        lib,
        config,
        ...
      }: {
        imports = [
          self.nixosModules.stylix
        ];

        # magos.helix.theme = "everforest_dark";
        magos.stylix.enable = true;
      };

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        treefmt = {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true; # Nix formatter
          # add more: programs.prettier.enable = true; etc.
        };

        devShells.default = with pkgs; mkShell {packages = [nil nixd steel steel-language-server];};
      };

      # flake = {
      # The usual flake attributes can be defined here, including system-
      # agnostic ones like nixosModule and system-enumerating ones, although
      # those are more easily expressed in perSystem.
      #
      # };
      #
    };
}
