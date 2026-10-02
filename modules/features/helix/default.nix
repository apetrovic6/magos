{
  self,
  inputs,
  lib,
  ...
}: let
  defaultTheme = "everforest_dark";

  mkEditorSettings = terminalPkg: import ./_config/editor.nix {inherit lib terminalPkg;};
  languages = import ./_config/languages.nix;
  mkKeybinds = pkgs: terminalPkg: import ./_config/keybinds.nix {inherit pkgs terminalPkg;};

  # Steel cogs to install. Dependencies are pulled in automatically, so listing
  # `oil` is enough to also get `notify`.
  selectPlugins = system: p: [
    p.oil
    # Developed out of tree, so it comes from a flake input rather than the
    # helixPlugins set -- but it carries the same cogName/pluginDependencies
    # passthru, so pluginClosure walks it exactly like a packaged cog.
    inputs.connect-hx.packages.${system}.default
    # Debugger values inline while stopped (fn add(x: f32 = 5, ...)). Also
    # developed out of tree at ~/clan/inline-values.hx; needs the DAP Steel
    # API from _config/steel-inlay-hints patch 0007, so drop it together
    # with that patch if it is ever dropped.
    inputs.inline-values-hx.packages.${system}.default
    # Packaged with meta.license = unfree, but upstream ships LICENSE-MIT and the
    # Cargo manifest agrees. Correcting it here keeps this one plugin from
    # forcing nixpkgs.config.allowUnfree across the whole configuration.
    (p.helix-file-watcher.overrideAttrs (old: {
      meta = old.meta // {license = lib.licenses.mit;};
    }))

    p.scooter
    p.scopeline

    # In-editor markdown rendering (render-markdown.nvim style): headings, list
    # bullets, checkbox glyphs, quote bars and code-block backgrounds are drawn
    # as decorations over the buffer; the line under the cursor stays raw.
    # Needs the decoration APIs in _config/steel-inlay-hints, see below.
    p.vista
    # vista's own dependency (declared in its cog.scm, but helix-plugins-nix
    # does not mirror that into pluginDependencies, so the closure walk above
    # cannot pull it in -- it has to be listed explicitly).
    p.glyph
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
    # The terminal editor.terminal spawns for a debuggee, threaded through to
    # _config/editor.nix. Same wrapped foot niri spawns; plain `foot` is not on
    # PATH, so this cannot be a bare name.
    terminalPkg,
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
      # tree-sitter-perl's src/tsp_unicode.h does `#include "bsearch.c"`, and
      # that file defines its own `void *bsearch(...)`. glibc 2.42+ makes
      # `bsearch` a type-generic `_Generic` macro under C23, and gcc 16 defaults
      # to -std=gnu23, so the macro rewrites the definition's own declarator and
      # the grammar dies with "expected identifier or '(' before '_Generic'".
      # helix's grammars.nix passes no -std at all, so pinning this one grammar
      # back to gnu17 is the whole fix -- no other grammar redefines a libc
      # symbol.
      #
      # grammarOverlays is grammars.nix's own extension point (it `extend`s a
      # makeExtensible of name -> derivation), so this needs no fork of the
      # helix-w-plugins input. It has to be `.override`, not `.overrideAttrs`:
      # the grammars are a separate derivation that default.nix pulls in via
      # callPackage, so grammarOverlays is a function argument, not an attr on
      # helix itself.
      #
      # This sits in the overlay rather than on `patchedHelix` so that every
      # helix in the closure picks it up. The wrapper and the plugin flakes each
      # reach for `pkgs.helix` on their own, and fixing only the patched attr
      # left those other instances still building the broken grammar.
      (_final: prev: {
        helix = prev.helix.override {
          grammarOverlays = [
            (_gFinal: gPrev: {
              perl = gPrev.perl.overrideAttrs (o: {
                FLAGS = o.FLAGS ++ ["-std=gnu17"];
              });
            })
          ];
        };
      })
    ];

    plugins = pluginClosure (selectPlugins pkgs.stdenv.hostPlatform.system hxPkgs.helixPlugins);
    nativePlugins = builtins.filter (drv: (drv.native or null) != null) plugins;

    # The steel-event-system branch only exposes unstyled `add-inlay-hint`.
    # vista draws styled text, backgrounds and concealing overlays, so the five
    # commits behind `Ra77a3l3-jar/helix@steel-inlay-hints` are vendored in
    # under _config/steel-inlay-hints and applied here rather than switching the
    # `helix-w-plugins` input to that fork -- it is 14 commits behind this lock.
    # A sixth patch (0006) is ours, not upstream: the API those five add makes a
    # document with N plugin overlays cost O(N^2), which measured ~1.7s of CPU per
    # keystroke on a table-heavy plan document (~28k overlays). Both are described
    # in _config/steel-inlay-hints/README.md.
    # Cargo.lock is untouched, so the cargo deps stay in the store and only the
    # helix crates rebuild.
    patchedHelix = hxPkgs.helix.overrideAttrs (prev: {
      # `steel` is NOT a default feature of helix-term any more: upstream moved
      # it out in df595c7 ("fix making steel default"), leaving
      # `default = ["git"] # Add steel here for development`. The fork's
      # derivation passes no features, so the default is what it gets, and
      # without this line the whole plugin system silently disappears -- helix
      # builds and runs, every cog and every API these patches add is simply
      # absent, and the first sign is `no such command` at a keybinding.
      #
      # It has to be `cargoBuildFeatures`, not `buildFeatures`: buildRustPackage
      # consumes `buildFeatures` as a function argument and turns it into this,
      # so overrideAttrs setting the former lands an env var that cargo-build-hook
      # never reads -- the build succeeds and steel is still missing.
      cargoBuildFeatures = (prev.cargoBuildFeatures or []) ++ ["steel"];

      patches =
        (prev.patches or [])
        ++ [
          ./_config/steel-inlay-hints/0001-add-styled-inlay-hint-storage-and-rendering.patch
          ./_config/steel-inlay-hints/0002-add-steel-api-for-styled-inlay-hints.patch
          ./_config/steel-inlay-hints/0003-add-cursor-before-inlay-hints-anchored-at-a-line-end.patch
          ./_config/steel-inlay-hints/0004-add-line-placement-for-styled-inlay-hints.patch
          ./_config/steel-inlay-hints/0005-add-steel-overlay-highlight-and-background-api.patch
          # ours, not upstream: makes the decoration APIs above linear instead
          # of quadratic, see _config/steel-inlay-hints/README.md
          ./_config/steel-inlay-hints/0006-local-scale-plugin-decorations-linearly.patch
          # ours, not upstream: reads the stopped debug frame and its variables
          # from Steel, see _config/steel-inlay-hints/README.md
          ./_config/steel-inlay-hints/0007-add-steel-api-for-dap-frame-scopes-and-variables.patch
          ./_config/steel-inlay-hints/0008-disconnect-the-debug-adapter-when-terminate-is-unsup.patch
        ];
    });

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

    # tree-sitter-rstml: external grammar for Leptos .rshtml / .rs.html files.
    # Uses the tree-sitter-rstml flake which provides pre-built grammars
    # via nixpkgs' tree-sitter.buildGrammar with correct API versioning.
    rstmlRuntime = pkgs.runCommand "helix-runtime-rstml" {} ''
      mkdir -p $out/grammars $out/queries/rstml
      cp ${inputs.tree-sitter-rstml.packages.${pkgs.system}.tree-sitter-grammars.rstml}/parser $out/grammars/rstml.so
      cp ${inputs.tree-sitter-rstml.packages.${pkgs.system}.tree-sitter-grammars.rstml}/queries/*.scm $out/queries/rstml/
    '';

    # Injection queries, shaped to be another runtime dir rather than something
    # dropped next to config.toml. helix only looks for queries under
    # <runtime>/queries/<lang>/, and its config-relative runtime dir is
    # config_dir()/runtime -- NOT config_dir() itself, so a copy into
    # hx-config/helix/queries is never read.
    #
    # queries/rust/injections.scm is assembled rather than stored: helix takes
    # the first runtime dir that has a given query file and does not merge
    # across dirs (read_query -> load_runtime_file builds one path), so adding
    # the `view!` rule means shipping the stock rules with it or silently
    # dropping rustdoc, format_args!, sqlx, regex, json, html! and slint!.
    # Concatenating them from HELIX_DEFAULT_RUNTIME -- the runtime of the very
    # helix being wrapped -- means a bump brings its own rules along and there
    # is no vendored copy to fall out of date.
    customQueries = pkgs.runCommand "helix-custom-queries" {} ''
      mkdir -p $out/queries/rust
      cp -r ${./_config/queries}/. $out/queries
      # patchedHelix, not hxPkgs.helix: same runtime at the same rev, but it
      # keeps the *wrapped* helix as the only helix in the closure. Referring to
      # the unpatched attr here builds a second, ~4 minute copy of the editor.
      cat ${patchedHelix.HELIX_DEFAULT_RUNTIME}/queries/rust/injections.scm \
          ${./_config/rust-view-injection.scm} \
        > $out/queries/rust/injections.scm
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
      # defaults to hxPkgs.helix (the steel fork straight from the overlay)
      package = patchedHelix;
      settings =
        (mkEditorSettings terminalPkg)
        // {
          theme = theme;
          keys = (mkKeybinds pkgs terminalPkg).keys;
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
      # buf backs connect.hx's schema-aware executor. Appended to PATH by the
      # wrapper, so a project dev shell's own buf still wins -- this is a floor,
      # not an override.
      # grpcurl backs connect.hx's request scaffolding: it reads reflection and
      # prints a protojson skeleton for a message, which buf build cannot do.
      # codelldb backs the rust debugger in _config/languages.nix. `.adapter` is
      # the standalone build of the vscode extension's adapter -- it puts
      # `bin/codelldb` on PATH and, next to the real binary, the
      # `codelldb-launch` helper the adapter shells out to for runInTerminal
      # (it resolves that by looking beside its own argv[0], so the two have to
      # stay in the same store path).
      runtimePkgs = with pkgs; [alejandra tailwindcss-language-server steel-language-server buf grpcurl vscode-extensions.vadimcn.vscode-lldb.adapter];

      # The wrapper already pins XDG_CONFIG_HOME to its generated config, so
      # helix would look for init.scm next to config.toml. Point it at our own
      # store dir instead rather than teaching the wrapper to emit .scm files.
      # This one can stay read-only: helix writes here only to create helix.scm
      # and init.scm when they are missing, and we ship both.
      env.HELIX_STEEL_CONFIG = "${steelConfig}";

      # Additive: ranked above the runtime baked into the binary, not instead
      # of it. See httpRuntime / rstmlRuntime above. helix searches every
      # runtime dir in priority order, so we chain them with a join.
      env.HELIX_RUNTIME = "${pkgs.symlinkJoin {
        name = "helix-runtime-custom";
        paths = [httpRuntime rstmlRuntime customQueries];
      }}";
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
      };
    };
  };

  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages.helix = makeHelixPackage {
      inherit pkgs;
      terminalPkg = self'.packages.foot;
    };
  };
}
