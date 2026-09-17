{
  self,
  inputs,
  lib,
  ...
}: let
  defaultTheme = "everforest_dark";

  editorSettings = import ./_config/editor.nix;
  languages = import ./_config/languages.nix;
  makeKeybinds = pkgs: import ./_config/keybinds.nix {inherit pkgs;};

  # Steel cogs to install. Dependencies are pulled in automatically, so listing
  # `oil` is enough to also get `notify`.
  selectPlugins = system: p: [
    p.oil
    # Developed out of tree, so it comes from a flake input rather than the
    # helixPlugins set -- but it carries the same cogName/pluginDependencies
    # passthru, so pluginClosure walks it exactly like a packaged cog.
    inputs.connect-hx.packages.${system}.default
    # Packaged with meta.license = unfree, but upstream ships LICENSE-MIT and the
    # Cargo manifest agrees. Correcting it here keeps this one plugin from
    # forcing nixpkgs.config.allowUnfree across the whole configuration.
    (p.helix-file-watcher.overrideAttrs (old: {
      meta = old.meta // {license = lib.licenses.mit;};
    }))

    p.scooter
    p.scopeline
  ];

  # Each plugin may declare `pluginDependencies`; walk the closure so a cog
  # never ends up in STEEL_HOME without the cogs it requires.
  pluginClosure = plugins: let
    toNode = p: {
      key = p.cogName;
      val = p;
    };
  in
    map (node: node.val) (builtins.genericClosure {
      startSet = map toNode plugins;
      operator = node: map toNode (node.val.pluginDependencies or []);
    });

  makeHelixPackage = {
    pkgs,
    theme ? defaultTheme,
  }: let
    hxPkgs = pkgs.appendOverlays [
      # The steel plugin fork ships an overlay whose only attr is `helix`;
      # the wrapper defaults its base package to `pkgs.helix`, so extending
      # pkgs here is what swaps upstream helix for the plugin build.
      inputs.helix-w-plugins.overlays.default
      # Adds `helixPlugins`. Only the cog packages are used from this flake --
      # its NixOS/home-manager modules default to pkgs.steelix, which would
      # pull in a second helix build instead of the one above.
      inputs.helix-plugins.overlays.default
    ];

    plugins = pluginClosure (selectPlugins pkgs.stdenv.hostPlatform.system hxPkgs.helixPlugins);
    nativePlugins = builtins.filter (drv: (drv.native or null) != null) plugins;

    # steel resolves `(require "oil/oil.scm")` against $STEEL_HOME/cogs and
    # loads `#%require-dylib` libraries out of $STEEL_HOME/native.
    #
    # This cannot be handed to helix as a store path: on every startup helix
    # writes its own builtin cogs into $STEEL_HOME/cogs/helix (generate_module
    # in helix-term/src/commands/engine/steel/mod.rs, which unwraps the write),
    # so a read-only STEEL_HOME panics the editor before it draws a frame. It
    # gets seeded into a writable cache dir at launch instead, see below.
    steelHome = pkgs.linkFarm "helix-steel-home" (
      map (drv: {
        name = "cogs/${drv.cogName}";
        path = drv;
      })
      plugins
      ++ lib.optional (nativePlugins != []) {
        name = "native";
        path = pkgs.symlinkJoin {
          name = "helix-steel-native";
          paths = map (drv: drv.native) nativePlugins;
        };
      }
    );

    # These must be REAL files, not a linkFarm of symlinks. Steel resolves a
    # relative `(require "plugins/oil.scm")` against the directory of the
    # requiring file after following symlinks, so a symlinked init.scm
    # resolves against /nix/store and the require silently falls through to
    # $STEEL_HOME/cogs, where it is not found.
    #
    # helix.scm has to exist even though we keep it empty: when it is missing
    # helix prints "Unable to find the `helix.scm` file, creating...." to
    # stdout on every launch, which scribbles over the TUI.

    # Helix ships no `http` grammar, so .http/.connect files would otherwise
    # have no highlighting at all. This is an ADDITIVE runtime dir, not a
    # replacement: helix searches every runtime dir in priority order and takes
    # the first file that exists (find_runtime_file, helix-loader/src/lib.rs),
    # with HELIX_RUNTIME ranked above the HELIX_DEFAULT_RUNTIME baked into the
    # binary at build time. So holding only the one grammar here leaves the
    # stock runtime -- themes, tutor, every other grammar -- reachable.
    #
    # The grammar derivation names the shared object `parser`; helix dlopens
    # `grammars/<name>.so` where <name> is the language's grammar field, which
    # defaults to the language name.
    httpRuntime = let
      grammar = pkgs.tree-sitter-grammars.tree-sitter-http;
    in
      pkgs.runCommand "helix-runtime-http" {} ''
        mkdir -p $out/grammars $out/queries/http
        cp ${grammar}/parser $out/grammars/http.so
        cp ${grammar}/queries/*.scm $out/queries/http/
        chmod -R u+w $out/queries

        # The queries ship for neovim, and `#offset!` is an nvim-only predicate.
        # Helix rejects the whole file over it -- "unknown predicate #offset!",
        # "Failed to compile highlights for 'http'" -- which loses every
        # injection, not just the one rule. Dropping those lines keeps the rest;
        # the cost is that an injected `> {% .. %}` script region includes its
        # own delimiters, since offsetting them away is exactly what the
        # predicate did.
        #
        # Only the predicate call is removed, not the line: the second one ends
        # with the rule's own closing parens, and deleting the line took those
        # with it -- leaving "invalid query syntax", which fails exactly as
        # loudly as the thing it was meant to fix.
        sed -i 's/(#offset![^)]*)//g' $out/queries/http/injections.scm
      '';

    steelConfig = pkgs.runCommand "helix-steel-config" {} ''
      mkdir -p $out/plugins
      touch $out/helix.scm
      cp ${./_config/init.scm} $out/init.scm
      cp -r ${./_config/plugins}/. $out/plugins/
    '';

    # Copy the cogs into a writable dir, keyed on the store path so a rebuild
    # re-seeds and a repeat launch does not. `cp -L` dereferences the linkFarm
    # symlinks and `--no-preserve=mode` plus the chmod makes the copies
    # writable, so nothing helix touches points back at the store.
    seedSteelHome = pkgs.writeShellScript "helix-seed-steel-home" ''
      if [ -z "''${STEEL_HOME:-}" ]; then
        STEEL_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}/helix-steel"
        export STEEL_HOME
        stamp="$STEEL_HOME/.nix-store-path"
        if [ "$(cat "$stamp" 2>/dev/null)" != "${steelHome}" ]; then
          rm -rf "$STEEL_HOME"
          mkdir -p "$STEEL_HOME"
          cp -RL --no-preserve=mode "${steelHome}/." "$STEEL_HOME/"
          chmod -R u+w "$STEEL_HOME"
          printf '%s' "${steelHome}" > "$stamp"
        fi
      fi
    '';
  in
    inputs.wrapper-modules.wrappers.helix.wrap {
      pkgs = hxPkgs;
      settings =
        editorSettings
        // {
          theme = theme;
          keys = (makeKeybinds pkgs).keys;
        };
      inherit languages;
      # languages.language = language.language;
      # languages.language-server = language.language-server;
      # Renamed from `extraPackages` upstream in nix-wrapper-modules#540
      # (2026-05-19). A pure rename for callers that only set it; the type also
      # widened to accept `{ data, prefix ? false, ... }` entries so an entry can
      # be prefixed rather than suffixed onto PATH.
      #
      # Not to be confused with `programs.helix.extraPackages`, which is the
      # home-manager/NixOS option and still spelled the old way — that is the
      # name in the commented-out block below.
      # steel-language-server backs the `scheme` entry in _config/languages.nix.
      # It resolves its own index out of $STEEL_HOME/lsp, which it inherits from
      # this wrapper -- see seedSteelHome above. Without STEEL_HOME set it panics
      # on startup ("Unable to find steel home location").
      runtimePkgs = with pkgs; [alejandra tailwindcss-language-server steel-language-server];

      # The wrapper already pins XDG_CONFIG_HOME to its generated config, so
      # helix would look for init.scm next to config.toml. Point it at our own
      # store dir instead rather than teaching the wrapper to emit .scm files.
      # This one can stay read-only: helix writes here only to create helix.scm
      # and init.scm when they are missing, and we ship both.
      env.HELIX_STEEL_CONFIG = "${steelConfig}";

      # Additive: ranked above the runtime baked into the binary, not instead
      # of it. See httpRuntime above.
      env.HELIX_RUNTIME = "${httpRuntime}";
      runShell = [". ${seedSteelHome}"];
    };
in {
  flake.nixosModules.helix = {
    pkgs,
    lib,
    config,
    ...
  }: {
    options.magos.helix.theme = lib.mkOption {
      type = lib.types.str;
      default = defaultTheme;
      description = "Helix colorscheme name.";
    };

    config = {
      programs.helix = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.helix;
        # settings =
        #   editorSettings
        #   // {
        #     theme = config.magos.helix.theme;
        #     keys = (makeKeybinds pkgs).keys;
        #   };
        # inherit languages;
        # runtimePackages = with pkgs; [alejandra];
      };
    };
  };

  perSystem = {pkgs, ...}: {
    packages.helix = makeHelixPackage {inherit pkgs;};
  };
}
