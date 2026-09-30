{
  description = "Magos DE";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    # Pins the whole opencode build, and with it bun -- bun is the actual
    # culprit, not opencode. Every prompt dies with
    #   TypeError: undefined is not an object (evaluating 'a.name')
    #     at SystemPrompt.environment
    # reproducible with OPENCODE_CONFIG={} in an empty directory, no MCP,
    # plugins or project config needed.
    #
    # The 2026-09-17 flake update (nixpkgs 8ce4ef6c -> b1b87598) moved two
    # things at once: opencode 1.18.29 -> 1.18.30 AND bun 1.3.13 -> 1.4.2.
    # Measured:
    #   opencode 1.18.29 + bun 1.3.13  works
    #   opencode 1.18.30 + bun 1.4.2   fails
    #   opencode 1.18.29 + bun 1.4.2   fails   <- source constant, bun alone
    # So bun 1.4.2 is sufficient to break it. NOT tested: 1.18.30 + bun 1.3.13,
    # so bun is not proven necessary. opencode is built with `bun build
    # --compile`, so the runtime is baked in and the nixpkgs pin covers both.
    # Retest against a newer bun before dropping this.
    nixpkgs-opencode.url = "github:nixos/nixpkgs/8ce4ef6cb6f871616146b9fe26d2a5ae594e94fe";

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

    # numtide/nix-ai-tools, renamed. The bare .../llm-agents (no .nix) 404s.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Developed out of tree at ~/clan/connect.hx. Published at
    # github:apetrovic6/connect.hx, but deliberately still a path: input so
    # local edits can be tested without pushing -- nix pins a path: input by
    # narHash, so a change there needs `nix flake update connect-hx` here
    # before a rebuild picks it up. Switch the url when that stops being
    # convenient. The follows keep its helixPlugins scope identical to the one
    # above, so run-command is not built twice.
    connect-hx = {
      # url = "path:/home/apetrovic/clan/connect.hx";
      url = "github:apetrovic6/connect.hx";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.helix-plugins.follows = "helix-plugins";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";

    tree-sitter-rstml = {
      url = "github:rayliwell/tree-sitter-rstml/v2.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Oh My Pi — enhanced fork of Pi with 31 built-in tools, LSP, subagents, etc.
    # Used as a wrapper (not the home module) — see modules/features/omp/default.nix
    oh-my-pi = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
