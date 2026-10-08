# Omarchy as a desktop, nothing else -- the magos/niri arrangement applied to
# Omarchy 4.x.
#
# Pluggable like modules/features/niri.nix: it adds a session beside whatever
# else a machine runs and owns nothing outside it. Options live under
# `magos.omarchy`.
#
# ## What this is and is not
#
# It consumes nixarchy's *package* -- 1924 lines of de-Arch-ification over 444
# upstream shell scripts, 56 substituteInPlace calls, and an 87-entry runtime
# dependency list derived by grepping every one of them -- and imports none of
# its modules. That package is the port, and it is maintained upstream; a bump
# is a source bump. What nixarchy layers *on top* of it is an opinionated
# machine (36-app Install menu, local AI, fleet management, auto-update,
# MicroVMs, its own greeter, shell and editor integration, its own sops-nix),
# and this file reimplements only the fraction of that which the desktop
# actually needs.
#
# The consequences, which are the whole point:
#   - no second sops-nix, so nothing collides with clan's
#   - no auto-update, because clan is the updater
#   - one Hyprland, from this system's nixpkgs, so the glibc-vs-mesa crash the
#     nixarchy wrapper works around with mkForce cannot occur here
#   - nothing is written into $HOME: bindings are baked into the package, which
#     means no activation seed and no files to keep out of the way
#
# ## The coupling to be careful about
#
# The package is deliberately NOT self-contained. Its own installPhase explains
# that bin/ is a symlink farm rather than wrapProgram'd, because `bin/omarchy`
# finds its subcommands by grepping siblings for `# omarchy:summary=` metadata
# and a generated wrapper has no such comment. So the 87 runtime dependencies
# have to be on the session PATH or a large share of those 444 scripts fail at
# runtime. systemPackages below is load-bearing, not a convenience.
{self, ...}: {
  flake.nixosModules.omarchy = {
    options,
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.magos.omarchy;

    # The fcitx5 unit below names config.i18n.inputMethod.package directly, so
    # it may only be defined when that package is actually fcitx5.
    usingFcitx5 = config.i18n.inputMethod.enable && config.i18n.inputMethod.type == "fcitx5";

    # Built from THIS system's pkgs through nixarchy's overlay, rather than
    # taken from its flake's own `packages`, so the machine's nixpkgs config
    # and overlays apply. Same expression nixarchy's own module defaults to.
    baseOmarchy = (pkgs.extend self.inputs.nixarchy.overlays.default).omarchy;

    # ---- declarative keybindings -------------------------------------------
    #
    # Lua string literal. JSON's escaping rules for quote, backslash, newline
    # and tab are Lua's own, so toJSON is a correct quoter for any chord or
    # shell command -- which a hand-rolled "\"${s}\"" is not.
    lua = builtins.toJSON;

    # o.bind(keys, description, dispatcher) and hl.unbind(keys): upstream's
    # signatures, default/hypr/helpers.lua:92 and Hyprland's Lua API.
    renderBind = keys: b:
      lib.optionalString b.replace "hl.unbind(${lua keys})\n"
      + "o.bind(${lua keys}, ${
        if b.description == null
        then "nil"
        else lua b.description
      }, ${lua b.command})";

    # hl.gesture(spec) -- Hyprland 0.56's own API, per its shipped stub
    # share/hypr/stubs/hl.meta.lua:832. Omarchy ships the same call commented
    # out in config/hypr/input.lua, so this turns on what is already there
    # rather than inventing a mechanism.
    renderGesture = g:
      "hl.gesture({ fingers = ${toString g.fingers}, direction = ${lua g.direction}, action = ${lua g.action}"
      + lib.optionalString (g.mods != null) ", mods = ${lua g.mods}"
      + " })";

    gesturesLua = lib.concatMapStringsSep "\n" renderGesture cfg.gestures;

    bindingsLua = pkgs.writeText "magos-omarchy-bindings.lua" ''
      -- Generated from magos.omarchy.bindings, .plugins and .gestures. Part of
      -- the Omarchy tree in the Nix store; no copy of this in $HOME to drift.
      --
      -- Required from the end of config/hypr/hyprland.lua, so it runs after
      -- default.hypr.omarchy: an unbind here beats an Omarchy default.
      -- `omarchy menu keybindings --print` lists what is currently bound.

      ${lib.concatMapStringsSep "\n" (k: "hl.unbind(${lua k})") cfg.bindings.unbind}

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderBind cfg.bindings.bind)}

      ${pluginBindingsLua}

      ${gesturesLua}

      ${cfg.bindings.extraLua}
    '';

    anyBindings =
      cfg.bindings.bind
      != {}
      || cfg.bindings.unbind != []
      || cfg.bindings.extraLua != ""
      || pluginBindingsLua != ""
      || cfg.gestures != [];

    # bootstrap.lua puts $OMARCHY_PATH/?.lua on Lua's package.path, so a
    # directory added to the tree is requireable, and appending the require to
    # the entry point the session names with --config is enough to load it.
    # overrideAttrs rather than a runCommand copy: passthru.runtimeDeps has to
    # survive, and systemPackages below reads it.
    omarchy = baseOmarchy.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        # The store fallback for the five modules the entry point requires.
        #
        # config/hypr/hyprland.lua does require("hypr.monitors"), ("hypr.input"),
        # ("hypr.bindings"), ("hypr.looknfeel") and ("hypr.autostart"), and
        # bootstrap.lua's package.path is
        #   $HOME/.local/state/?.lua; $HOME/.config/?.lua; $OMARCHY_PATH/?.lua
        # The tree keeps those files under config/hypr/, NOT hypr/, so
        # $OMARCHY_PATH resolves none of them: upstream relies entirely on its
        # home-manager seed having copied config/ into ~/.config first, and
        # without that seed the first require aborts the whole config -- a
        # session that dies on login rather than one that looks unthemed.
        #
        # Mirroring them to hypr/ makes the desktop work against an empty $HOME,
        # which is what lets this module skip the seed. The override semantics
        # are preserved rather than lost: ~/.config/hypr/<f>.lua is SECOND on
        # package.path and this is third, so a hand-written file still wins.
        + ''
          mkdir -p $out/share/omarchy/hypr
          cp $out/share/omarchy/config/hypr/*.lua $out/share/omarchy/hypr/
        ''
        # The Herdr plugin, installed as FIRST-PARTY.
        #
        # Shell plugins, installed as FIRST-PARTY so they are enabled with no
        # state in $HOME -- see the enabledPlugins binding above for why that
        # directory and not ~/.config/omarchy/plugins.
        + lib.optionalString (enabledPlugins != {}) ''
          install -d $out/share/omarchy/shell/plugins
        ''
        + lib.concatStrings (lib.mapAttrsToList (name: p: ''
            cp -r ${pluginDrv name p} $out/share/omarchy/shell/plugins/${name}
            chmod -R u+w $out/share/omarchy/shell/plugins/${name}
          '')
          enabledPlugins)
        # ... and their widgets placed in the bar.
        #
        # Being enabled and being IN THE BAR are different questions in
        # Omarchy: isEnabled() decides whether the component loads at all (so
        # a menu binding works regardless), while inBar() is purely "does
        # shell.json's bar.layout mention this id". A bar widget therefore
        # needs a layout entry even when it is first-party and enabled.
        #
        # Patched into the tree's config/omarchy/shell.json, which the shell
        # falls back to while the user has no ~/.config/omarchy/shell.json --
        # so this is the default bar, not an override. Once something writes a
        # user shell.json (changing any bar setting from the UI does), that
        # file wins and these entries stop applying; menu bindings are
        # unaffected either way.
        #
        # Guarded and idempotent: fails the build if the layout is gone after
        # an Omarchy bump, and will not add a second copy of an id.
        + lib.optionalString (barPlugins != {}) ''
          shell_json=$out/share/omarchy/config/omarchy/shell.json
          test -f "$shell_json"
          ${lib.getExe pkgs.jq} -e '.bar.layout | type == "object"' "$shell_json" >/dev/null
          ${lib.concatStrings (lib.mapAttrsToList (_: p: ''
              ${lib.getExe pkgs.jq} --arg id ${lib.escapeShellArg (pluginId p)} --arg sec ${lib.escapeShellArg (pluginSection p)} '
                .bar.layout[$sec] //= []
                | if (.bar.layout[$sec] | map(.id) | index($id)) then .
                  else .bar.layout[$sec] = ([{id: $id}] + .bar.layout[$sec])
                  end
              ' "$shell_json" > "$shell_json.new"
              mv "$shell_json.new" "$shell_json"
            '')
            barPlugins)}
        ''
        # Screensaver off at the SOURCE, not just at the trigger.
        #
        # Three things reach it -- the shell's idle service at 150s, the menu's
        # "Screensaver" entry, and omarchy-branding-screensaver -- and the
        # last two pass `force`, which is DEFINED as "ignore the
        # screensaver-off toggle". So the toggle the session launcher writes
        # stops the idle path only; replacing the script is what stops the
        # menu entry erroring as well.
        #
        # bin/ is a symlink farm into share/omarchy/bin/, so the real file is
        # the one rewritten here and the bin/ symlink follows. The `test`
        # guard is deliberate: an Omarchy bump that renames or drops this
        # script should fail the build rather than quietly re-enable it.
        + lib.optionalString (!cfg.screensaver) ''
          test -f $out/share/omarchy/bin/omarchy-launch-screensaver
          cat > $out/share/omarchy/bin/omarchy-launch-screensaver <<'MAGOS_NO_SCREENSAVER'
          #!${pkgs.runtimeShell}
          # omarchy:summary=Screensaver (disabled by magos.omarchy.screensaver)
          exit 0
          MAGOS_NO_SCREENSAVER
          chmod +x $out/share/omarchy/bin/omarchy-launch-screensaver
        ''
        + lib.optionalString anyBindings ''
          install -Dm644 ${bindingsLua} $out/share/omarchy/magos/bindings.lua
          cat >> $out/share/omarchy/config/hypr/hyprland.lua <<'MAGOS_BINDINGS'

          -- Added by magos.omarchy.bindings.
          require("magos.bindings")
          MAGOS_BINDINGS
        '';
    });

    # ---- shell plugins -----------------------------------------------------
    #
    # Omarchy finds third-party plugins only under ~/.config/omarchy/plugins
    # (PluginRegistry.pluginsDir, a hardcoded $HOME path), and enabling one
    # there means mutating shell.json. The FIRST-PARTY directory is
    # $OMARCHY_PATH/shell/plugins, which this module owns -- and
    # PluginRegistry.isEnabled() short-circuits on
    #   if (manifest.__isFirstParty) return true
    # so a plugin installed there is enabled with no state in $HOME and
    # nothing to run once. Upstream's `git clone` into the user directory plus
    # `omarchy plugin enable` is the same result by the imperative route.
    enabledPlugins = lib.filterAttrs (_: p: p.enable) cfg.plugins;

    # Only the ones that actually ship a bar widget and want to be placed.
    barPlugins = lib.filterAttrs (_: p: p.bar && pluginIsBarWidget p) enabledPlugins;

    # Read at EVALUATION time. `src` is a flake input -- a plain source path,
    # not a derivation -- so this is a readFile and not IFD. The id, kinds and
    # bar section therefore come from the plugin's own manifest instead of
    # being restated in Nix and left to drift when it is bumped.
    manifestOf = p: builtins.fromJSON (builtins.readFile "${p.src}/manifest.json");
    pluginId = p: (manifestOf p).id;
    pluginIsBarWidget = p: lib.elem "bar-widget" ((manifestOf p).kinds or []);
    pluginSection = p: (manifestOf p).barWidget.defaultSection or "center";

    pluginDrv = name: p:
      pkgs.runCommand "omarchy-plugin-${name}" {} ''
        cp -r ${p.src} $out
        chmod -R u+w $out

        # Repository scaffolding is not runtime, and one part of it is
        # actively harmful: the first-party scan is
        #   find <dir> -mindepth 2 -maxdepth 3 \( -name manifest.json -o -name '*.manifest.json' \)
        # so a fixture manifest under tests/ registers as a SECOND plugin.
        # Unquoted on purpose so the entries may be globs.
        ${lib.concatMapStringsSep "\n" (d: "rm -rf $out/${d}") p.prune}

        ${p.postInstall}

        # That scan reaches two levels into a plugin directory, so assert that
        # exactly one manifest is visible to it. A plugin that legitimately
        # ships a nested manifest fails the build here instead of silently
        # registering twice.
        found=$(find $out -maxdepth 2 \( -name manifest.json -o -name '*.manifest.json' \) | wc -l)
        if [ "$found" != "1" ]; then
          echo "omarchy plugin ${name}: expected 1 manifest visible to the scan, found $found:" >&2
          find $out -maxdepth 2 \( -name manifest.json -o -name '*.manifest.json' \) >&2
          exit 1
        fi
      '';

    # Hyprland-level binding per plugin, toggling its menu. A plugin's own
    # keys are handled inside its menu while that holds the keyboard, and are
    # deliberately NOT global bindings.
    pluginBindingsLua = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        _: p: let
          label =
            if p.description != null
            then p.description
            else (manifestOf p).name;
        in ''o.bind(${lua p.binding}, ${lua label}, ${lua "omarchy-shell shell toggle ${pluginId p} '{}'"})''
      )
      (lib.filterAttrs (_: p: p.binding != null) enabledPlugins)
    );

    # Omarchy's foot settings, as a directory to put on XDG_CONFIG_DIRS.
    #
    # foot searches $XDG_CONFIG_HOME/foot/foot.ini and then
    # $XDG_CONFIG_DIRS/foot/foot.ini (foot.ini(5)), so this is how Omarchy's
    # own config reaches it without a copy in $HOME. The file it points at is
    # the one upstream's home-manager seed would have installed: JetBrainsMono
    # 9, 14x14 pad, 10k scrollback, its key-bindings, and -- the part that
    # matters -- `include=~/.local/state/omarchy/current/theme/foot.ini`,
    # which is where omarchy-theme-set renders the palette.
    #
    # A copy rather than a symlink into the tree: foot resolves `include`
    # relative to nothing (the path is absolute or ~/), so the file's own
    # location does not matter, and a plain file keeps this directory from
    # exposing the rest of config/ to every other XDG application.
    footConfigDir = pkgs.runCommand "omarchy-foot-xdg-config" {} ''
      install -Dm644 ${tree}/config/foot/foot.ini $out/foot/foot.ini
    '';

    # The wallpaper's extension, kept so the symlink below is named something
    # ImageMagick and the shell will both recognise.
    wallpaperExt =
      if cfg.wallpaper == null
      then ""
      else lib.last (lib.splitString "." (builtins.baseNameOf cfg.wallpaper));

    # Upstream's runtimeDeps carries a plain `foot`, and naming a wrapped or
    # themed build in `terminal.package` has to REPLACE it rather than sit
    # beside it: two derivations with the same pname both shipping bin/foot in
    # one profile is a collision, and whichever won $PATH would decide which
    # config you actually got. Dropped by pname so this holds for any terminal,
    # and a no-op when the option names the same build upstream already ships.
    terminalPname =
      if cfg.terminal.package == null
      then null
      else cfg.terminal.package.pname or null;

    # nixarchy's OWN pinned Hyprland rides along inside
    # passthru.runtimeDeps -- 0.56.0 built against its flake's nixpkgs, so a
    # different glibc from this system's mesa. It must not come back in through
    # this list: not in systemPackages, where two builds of the compositor in
    # one profile collide, and not on the session launcher's PATH either, where
    # `hyprctl` would then resolve to a version that is not the one running.
    # programs.hyprland below owns the compositor, alone.
    #
    # Filtering here rather than at each use keeps the two in agreement and
    # drops the unused build out of the closure entirely.
    runtimeDeps =
      builtins.filter
      (
        d:
          !(lib.hasPrefix "hyprland-" (d.name or ""))
          && !(terminalPname != null && (d.pname or "") == terminalPname)
      )
      cfg.package.passthru.runtimeDeps;

    # From the OPTION, not the let-binding above, so overriding `package` moves
    # OMARCHY_PATH with it instead of leaving it pointed at the default tree.
    tree = "${cfg.package}/share/omarchy";

    # ---- the session -------------------------------------------------------
    #
    # Omarchy's desktop IS its Hyprland config, and that config lives in the
    # store. Naming it with --config is what lets this coexist with niri
    # instead of replacing it: nothing in ~/.config/hypr is required or touched,
    # so the niri session stays exactly as it is.
    sessionLauncher = pkgs.writeShellScript "omarchy-session" ''
      export OMARCHY_PATH=${tree}

      ${lib.optionalString cfg.terminal.omarchyFootConfig ''
        # Omarchy's foot.ini, session-scoped.
        #
        # Exported here rather than through environment.sessionVariables or
        # environment.etc."xdg/foot/foot.ini", both of which are MACHINE-wide:
        # a niri or GNOME session on the same machine would otherwise pick up
        # Omarchy's foot config too, and a user who never logs into Omarchy
        # would inherit an include pointing into a theme directory that their
        # home does not have -- which breaks foot outright (see the floor
        # below). Scoping it to this session keeps the blast radius at zero.
        #
        # /etc/xdg has to be named explicitly: it is the DEFAULT of an unset
        # XDG_CONFIG_DIRS, not an implicit suffix, so assigning the variable
        # without it would drop it -- and xdg-terminals.list, which this same
        # module writes to /etc/xdg to decide what SUPER+RETURN opens, is read
        # through exactly that path.
        export XDG_CONFIG_DIRS=${footConfigDir}:''${XDG_CONFIG_DIRS:-/etc/xdg}
      ''}

      ${lib.optionalString (!cfg.screensaver) ''
        # Omarchy's own screensaver-off switch, so its state agrees with the
        # neutralised script in the package: omarchy-debug-idle reports the
        # screensaver as disabled, and the menu's Toggles entry shows it
        # unchecked, instead of both claiming it is on while nothing happens.
        #
        # Rewritten every login rather than seeded once, so flipping it from
        # the menu does not quietly outlive the setting.
        mkdir -p "$HOME/.local/state/omarchy/toggles"
        : > "$HOME/.local/state/omarchy/toggles/screensaver-off"
      ''}

      # Wallpaper, before the theme is applied so it is already a candidate.
      #
      # omarchy-theme-set's choose_theme_background() globs BOTH
      #   ~/.config/omarchy/backgrounds/$THEME/   and   <current theme>/backgrounds/
      # sorts the combined list and takes [0] when nothing is linked yet. The
      # first path sorts before the second (".config" < ".local"), so dropping a
      # file there makes it the one chosen without patching any theme -- and it
      # keeps working across theme switches and across an Omarchy bump that
      # changes which art a theme ships.
      #
      # Re-linked on every login rather than seeded once, so changing the option
      # takes effect at the next login instead of needing the file removed.
      ${lib.optionalString (cfg.wallpaper != null) ''
        wp_dir="$HOME/.config/omarchy/backgrounds/${cfg.defaultTheme}"
        mkdir -p "$wp_dir"
        ln -sfn ${cfg.wallpaper} "$wp_dir/00-magos.${wallpaperExt}"
      ''}

      # First-login theme, applied BEFORE the compositor starts.
      #
      # Omarchy's omarchy.lua ends with
      # require_optional.module("omarchy.current.theme.hyprland"), resolved
      # through package.path's $HOME/.local/state/?.lua -- so the theme has to
      # be on disk by the time Hyprland reads its config. A unit ordered on
      # graphical-session.target is already too late: the session comes up with
      # no theme and no wallpaper until one is picked from the menu by hand,
      # which is exactly the symptom without this.
      #
      # Guarded on theme.name, the marker omarchy-theme-set itself writes, so
      # it runs once per home and never undoes a runtime theme switch.
      #
      # PATH rather than just the absolute path: omarchy-theme-set calls its
      # siblings (omarchy-theme-set-templates, omarchy-theme-color) by bare
      # name and has no `set -e`, so without them on PATH it exits 0 having
      # rendered no template at all -- a theme with no foot.ini or btop.theme.
      if [ ! -e "$HOME/.local/state/omarchy/current/theme.name" ]; then
        OMARCHY_THEME_HEADLESS=1 \
        PATH=${cfg.package}/bin:${lib.makeBinPath runtimeDeps}:$PATH \
          ${cfg.package}/bin/omarchy-theme-set ${lib.escapeShellArg cfg.defaultTheme} || true
      fi

      ${lib.optionalString cfg.terminal.omarchyFootConfig ''
        # The include inside that foot.ini names
        # ~/.local/state/omarchy/current/theme/foot.ini, rendered by
        # omarchy-theme-set-templates from default/themed/foot.ini.tpl.
        #
        # A MISSING include is fatal to foot rather than a warning -- it exits
        # 230 and no terminal opens at all -- so this guarantees the file is
        # there. The theme-set above writes it for any theme carrying a
        # colors.toml (every bundled one does, and omarchy-theme-set-templates
        # runs before the headless gate, so the first-login path covers it),
        # but a theme without one renders no templates and would otherwise
        # leave the machine with no working terminal.
        #
        # Deliberately transient: omarchy-theme-set rm -rf's this directory on
        # every switch, so this is a floor for the session, not state.
        theme_dir="$HOME/.local/state/omarchy/current/theme"
        mkdir -p "$theme_dir"
        [ -e "$theme_dir/foot.ini" ] || : > "$theme_dir/foot.ini"
      ''}

      exec ${lib.getExe pkgs.uwsm} start -N Omarchy -D Hyprland -- \
        ${config.programs.hyprland.package}/bin/start-hyprland -- \
        --config ${tree}/config/hypr/hyprland.lua
    '';

    # The basename has to match providedSessions or NixOS refuses it. Kept as
    # `omarchy` because greeters persist the last session by file id, so
    # renaming it would silently log you into something else once.
    sessionPackage =
      (pkgs.writeTextFile {
        name = "omarchy-wayland-session";
        destination = "/share/wayland-sessions/omarchy.desktop";
        text = ''
          [Desktop Entry]
          Name=Omarchy
          Comment=Omarchy, through Hyprland
          Exec=${sessionLauncher}
          Type=Application
          DesktopNames=Hyprland
        '';
      })
      .overrideAttrs (_: {
        passthru.providedSessions = ["omarchy"];
      });
  in {
    # Declares programs.nixarchyThemeEngine; its own config is gated on
    # `cfg.enable && options ? home-manager`, so importing it costs nothing
    # until themeEngine.enable is set -- and silently does nothing on a
    # machine that does not use home-manager as a NixOS module.
    imports = [self.inputs.nixarchy-omatheme.nixosModules.default];

    options.magos.omarchy = {
      enable = lib.mkEnableOption "the Omarchy desktop, as a session beside whatever else this machine runs";

      package = lib.mkOption {
        type = lib.types.package;
        default = omarchy;
        defaultText = lib.literalMD "nixarchy's vendored Omarchy tree, plus `bindings`";
        description = "The Omarchy tree that OMARCHY_PATH points at.";
      };

      fonts = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Register Omarchy's icon font and the families its fontconfig rules
          name. Without the icon font the menu button in the bar draws U+E900
          as tofu; without liberation_ttf the sans-serif/serif/system-ui
          aliases in 50-omarchy.conf resolve to nothing and fall through.
        '';
      };

      gtkThemeSupport = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          What `omarchy-theme-set-gnome` needs to not be a no-op: the gsettings
          schemas it writes, the GTK3 Adwaita-dark that gnome-themes-extra
          supplies, and the Yaru icon variants every theme's icons.theme names.
          On Arch these arrive as transitive dependencies of the base packages.
        '';
      };

      defaultTheme = lib.mkOption {
        type = lib.types.str;
        default = "tokyo-night";
        description = ''
          Theme applied on FIRST LOGIN only, by the session launcher, before
          Hyprland starts. Switchable at runtime afterwards from the menu
          (SUPER+SPACE) and never overwritten once set -- the launcher checks
          for ~/.local/state/omarchy/current/theme.name first.

          Names a directory under the tree's themes/, so `omarchy theme list`
          is the authority on what is valid.
        '';
      };

      wallpaper = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "../wallpapers/everforest/1.png";
        description = ''
          Wallpaper to use instead of whatever art the theme ships.

          Linked into ~/.config/omarchy/backgrounds/<defaultTheme>/ by the
          session launcher, which is the directory omarchy-theme-set searches
          FIRST -- so it becomes the background chosen on first login without
          patching a theme, and keeps working across an Omarchy bump that
          changes a theme's bundled art.

          Null leaves the theme's own backgrounds alone. Cycling to another
          background at runtime still works; this only decides the first one.
        '';
      };

      essentialApps = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Install mako, which the package does not carry and the desktop needs.

          Four Omarchy scripts drive notifications through it and it is what
          answers org.freedesktop.Notifications. Installing it is enough -- it
          ships a D-Bus activation file, so it starts on the first notification
          without a unit.

          Everything else Omarchy's default bindings reach for IS in
          passthru.runtimeDeps: chromium, nautilus, neovim, udiskie, quickshell,
          satty, hyprlock, xdg-terminal-exec. The terminal is the other gap and
          has its own option below, because which one is wanted is a real
          choice rather than a default to paper over.
        '';
      };

      plugins = lib.mkOption {
        default = {};
        description = ''
          Omarchy shell plugins, keyed by the directory name they are
          installed under. Each is a source tree following Omarchy's plugin
          contract: a manifest.json at the root naming the QML entry points.

          Installed into the tree's own first-party plugin directory, so they
          are enabled without `omarchy plugin enable` and without anything
          under ~/.config/omarchy/plugins. The id, the kinds and the bar
          section are read from each plugin's manifest rather than restated
          here.

          Installing a plugin does NOT install what it drives -- a plugin
          whose backend is missing shows an error when opened, exactly like
          Omarchy's own screensaver without its branding file.
        '';
        example = lib.literalExpression ''
          {
            herdr = {
              src = self.inputs.nixarchy-herdr;
              binding = "SUPER + ALT + H";
            };
          }
        '';
        type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Install this plugin. Listing it is normally enough; this is for turning one off without deleting its configuration.";
            };

            src = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = self.inputs."nixarchy-${name}" or null;
              defaultText = lib.literalExpression ''self.inputs."nixarchy-''${name}"'';
              description = ''
                Source tree of the plugin, with manifest.json at its root.
                Normally a `flake = false` input, so flake.lock is the pin and
                `nix flake update <input>` is the bump.

                Defaults to this flake's `nixarchy-<name>` input, so the
                plugins shipped here need only be named: `plugins.herdr = {}`
                finds `nixarchy-herdr`. Set it explicitly for anything else.
              '';
            };

            bar = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Place this plugin's widget in the DEFAULT bar layout, in the
                section its manifest names. Ignored for a plugin with no bar
                widget.

                The file patched is the shell.json inside the Omarchy tree,
                which is only the fallback used while there is no
                ~/.config/omarchy/shell.json. Changing any bar setting from
                the UI writes one, and from then on that file wins and this
                is just the initial state.
              '';
            };

            binding = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "SUPER + ALT + H";
              description = ''
                Chord toggling this plugin's menu, or null for none. Check
                `omarchy menu keybindings` before picking one: an Omarchy
                default silently wins unless the chord is also listed in
                `bindings.unbind`.
              '';
            };

            description = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Label for the binding in the keybindings menu. Defaults to the plugin's manifest name.";
            };

            prune = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [
                ".github"
                "tests"
                "spec"
                "plan"
                "intent"
                "docs"
                "dev"
                "flake.nix"
                "flake.lock"
                "devenv.nix"
                "devenv.lock"
                "devenv.yaml"
                "preview.png"
                "screenshot*.png"
                "image-*.png"
              ];
              description = ''
                Paths removed from the source before installing, relative to
                its root and glob-capable.

                Not only about closure size. The first-party scan matches
                `*.manifest.json` two levels deep, so a fixture manifest left
                under tests/ would register as a second plugin -- the build
                asserts exactly one survives.
              '';
            };

            postInstall = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = ''
                Shell run over the pruned copy in $out, for fixups a plugin
                written against a normal distribution needs on NixOS --
                typically patching a `#!/usr/bin/python3` shebang, which does
                not exist here, or pointing one at an interpreter carrying
                the modules it imports.
              '';
            };
          };
        }));
      };

      screensaver = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Omarchy's idle screensaver: `ttfx` effects over an ASCII banner,
          launched at 150s idle by the shell's idle service, and reachable
          from the menu.

          Defaults OFF here, unlike upstream, because it cannot work in this
          module: omarchy-screensaver runs
          `ttfx -i ~/.config/omarchy/branding/screensaver.txt`, a hardcoded
          $HOME path with no fallback and no XDG search, and that file is part
          of the home-manager seed this module deliberately does not do. The
          result is not a missing screensaver but an error dialog over the
          desktop every time the machine idles.

          Turning it on is only sensible if you also put a banner at
          ~/.config/omarchy/branding/screensaver.txt yourself -- the menu's
          Style > Screensaver > Restore Default writes one from
          $OMARCHY_PATH/logo.txt.

          Off does not affect idle LOCKING, which is a separate timer in the
          same service (300s by default) and still fires.
        '';
      };

      terminal = {
        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = pkgs.foot;
          defaultText = lib.literalExpression "pkgs.foot";
          description = ''
            The terminal to install, or null when something else on this machine
            already does. magos installs foot, and `pkgs.foot` is that same
            derivation, so the default deduplicates rather than colliding --
            but a wrapped or themed build from elsewhere is a DIFFERENT
            derivation and two of them in one profile is a build failure. Set
            null in that case and only name `desktopId`.
          '';
        };

        desktopId = lib.mkOption {
          type = lib.types.str;
          default = "foot.desktop";
          example = "alacritty.desktop";
          description = ''
            The desktop entry `xdg-terminal-exec` should pick, written to
            /etc/xdg/xdg-terminals.list.

            Without this file xdg-terminal-exec falls back to SCANNING desktop
            entries for the TerminalEmulator category and takes whichever it
            ranks first -- which is how SUPER+RETURN opened alacritty on a
            machine whose terminal is foot. Naming it makes the choice
            deterministic and declarative.

            Must be the entry's filename as installed in
            share/applications, not a package name.
          '';
        };

        omarchyFootConfig = lib.mkOption {
          type = lib.types.bool;
          default = cfg.terminal.package == null;
          defaultText = lib.literalExpression "terminal.package == null";
          description = ''
            Put Omarchy's own foot.ini on the session's XDG_CONFIG_DIRS, so
            Omarchy's foot is configured and themed without a copy in
            ~/.config/foot.

            This is the alternative to nixarchy's home-manager seed. Without
            it foot starts on foot's defaults -- no JetBrainsMono, no padding,
            no scrollback, and no theme, because the palette reaches foot
            through an `include` in Omarchy's config and nothing else.
            ~/.config/foot/foot.ini still overrides it, since XDG_CONFIG_HOME
            is searched first.

            Defaults off when `terminal.package` names a build of your own, on
            the assumption that it carries its own configuration -- a
            stylix-wrapped foot, say, which would otherwise be fighting this
            file over the same settings.

            Only affects the Omarchy session: the variable is exported by the
            session launcher, not machine-wide, so other sessions and other
            users are untouched.

            Does NOT make `omarchy-font-set` or `omarchy-display-text-size`
            work on foot. Both change the font by running `sed -i` over
            ~/.config/foot/foot.ini, guarded on that file existing, so with no
            seed they are silently no-ops for this terminal -- as they already
            were before this option. A store file cannot be edited in place;
            the only fix is a writable copy in $HOME, which is the seed this
            module exists to avoid. Everything read-only -- the palette, font
            family, padding, scrollback, key-bindings -- does work.
          '';
        };
      };

      themeEngine = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Omarchroma, the runtime theme engine, via nixarchy-omatheme.

            Retints GTK, Qt, terminals, shells, electron apps and neovim the
            MOMENT a theme is switched, rather than at the next rebuild. It
            does not replace omarchy-theme-set: it installs hooks into
            ~/.config/omarchy/hooks/theme-set.d/, which omarchy-theme-set
            runs through omarchy-hook, so theme selection still works exactly
            as before and this is the live-reload half.

            Stylix keeps its role. The engine's `stylix.mode` defaults to
            "auto", which uses Stylix when its NixOS module is imported --
            Stylix stays the declarative template, the engine owns the active
            palette. Worth knowing if both are driving the same application.

            Unlike the rest of this module it DOES write to $HOME, through
            home-manager: the theme hooks, shell integration, the neovim/vim
            bridges and -- unless `programs.nixarchyThemeEngine.managePlugin`
            is turned off -- its bar plugin under
            ~/.config/omarchy/plugins/. That is the engine's own design and
            is why it is off by default here.
          '';
        };

        user = lib.mkOption {
          type = lib.types.str;
          example = "alice";
          description = ''
            User whose graphical session owns the theme engine. No default:
            the upstream option defaults to its author's own username, which
            would silently configure a user that does not exist here.
          '';
        };
      };

      gestures = lib.mkOption {
        default = [];
        example = lib.literalExpression ''
          [
            {
              fingers = 4;
              direction = "horizontal";
              action = "workspace";
            }
          ]
        '';
        description = ''
          Touchpad gestures, as `hl.gesture` calls.

          Omarchy ships exactly these commented out in
          config/hypr/input.lua, so nothing here is invented -- the default
          is empty because upstream's is off, not because it is unsupported.

          An `action` that needs to be a Lua FUNCTION rather than a name --
          Omarchy's focus-movement example,
          `function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end` --
          does not fit this option's string type; put those in
          `bindings.extraLua`.
        '';
        type = lib.types.listOf (lib.types.submodule {
          options = {
            fingers = lib.mkOption {
              type = lib.types.ints.positive;
              default = 3;
              example = 4;
              description = ''
                Number of fingers. Hyprland takes a plain integer here
                (HL.GestureSpec in its own Lua stub), but libinput only
                reports 3- and 4-finger swipes on most touchpads, so those
                are the values worth using.
              '';
            };

            direction = lib.mkOption {
              type = lib.types.enum ["left" "right" "up" "down" "horizontal" "vertical"];
              example = "horizontal";
              description = ''
                Swipe direction. `horizontal` and `vertical` are the
                two-way forms -- what a workspace swipe normally wants.

                An enum rather than a free string deliberately: a typo would
                otherwise be a gesture that silently never fires, which is
                indistinguishable from a touchpad that is not reporting.
              '';
            };

            action = lib.mkOption {
              type = lib.types.str;
              example = "workspace";
              description = ''
                What the gesture does -- `workspace`, `move`, `resize`,
                `special`, `close`, `fullscreen`, `float`.
              '';
            };

            mods = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "SUPER";
              description = "Modifiers that must be held, or null for none.";
            };
          };
        });
      };

      bindings = {
        unbind = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["SUPER + SHIFT + B"];
          description = ''
            Chords to disable outright, as `hl.unbind` calls. To replace one
            rather than remove it use `bind` with `replace = true`.
          '';
        };

        bind = lib.mkOption {
          default = {};
          example = lib.literalExpression ''
            {
              "SUPER + SHIFT + R" = "alacritty -e ssh cerberus";
              "SUPER + SPACE" = {
                description = "Omarchy menu";
                command = "omarchy-menu toggle root";
                replace = true;
              };
            }
          '';
          description = ''
            Keybindings to add, keyed by the chord as Omarchy spells it. A bare
            string is the command with no menu description; the attribute form
            adds one and can replace a default.
          '';
          type = lib.types.attrsOf (lib.types.coercedTo lib.types.str (command: {inherit command;}) (lib.types.submodule {
            options = {
              command = lib.mkOption {
                type = lib.types.str;
                description = "Dispatcher or shell command to run.";
              };

              description = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Label shown by `omarchy menu keybindings`; null passes `nil`.";
              };

              replace = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Emit `hl.unbind` for this chord first. Required whenever
                  Omarchy already binds it, or the new binding is ignored.
                '';
              };
            };
          }));
        };

        extraLua = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = ''
            Lua appended verbatim -- `o.window(...)`, conditionals, submaps.

            `omarchy_default_bindings = false` does NOT work here: it is read by
            default.hypr.omarchy, which has already run by the time this file
            loads. It belongs at the top of config/hypr/hyprland.lua, which
            would need a second patch in the package override.
          '';
        };
      };
    };

    config = lib.mkIf cfg.enable {
      # Omarchy 4.x is written against Hyprland's Lua config API, added in
      # 0.55. Asserted rather than assumed because the failure is a Hyprland
      # that starts and then ignores the entire configuration.
      assertions = [
        {
          # src defaults to this flake's nixarchy-<name> input, so a plugin
          # named something else needs it spelled out. Caught here because the
          # alternative is a `readFile` on null deep inside the package build.
          assertion = lib.all (p: p.src != null) (lib.attrValues enabledPlugins);
          message = let
            missing = lib.attrNames (lib.filterAttrs (_: p: p.src == null) enabledPlugins);
          in ''
            magos.omarchy.plugins has no `src` for: ${lib.concatStringsSep ", " missing}.

            It defaults to this flake's `nixarchy-<name>` input, and there is
            no input of that name for these. Set `src` to the plugin's source
            tree (a directory with manifest.json at its root).
          '';
        }
        {
          assertion = !cfg.themeEngine.enable || options ? home-manager;
          message = ''
            magos.omarchy.themeEngine needs home-manager as a NixOS module:
            nixarchy-omatheme installs its theme hooks, shell integration and
            bar plugin through home-manager.users.<user>, and its own config
            block is gated on `options ? home-manager`, so without it the
            option would evaluate cleanly and do nothing at all.
          '';
        }
        {
          assertion = lib.versionAtLeast config.programs.hyprland.package.version "0.55";
          message = ''
            magos.omarchy needs Hyprland >= 0.55 for the Lua config API that
            Omarchy 4.x is written against; this system has
            ${config.programs.hyprland.package.version}.
          '';
        }
      ];

      programs.hyprland = {
        # Not mkDefault: Omarchy *is* Hyprland, so enabling this while
        # disabling that is a contradiction rather than a preference.
        enable = true;

        # From this system's nixpkgs, deliberately. nixarchy pins its own
        # hyprland flake input, which carries its own nixpkgs, and the result
        # is a Hyprland on a different glibc from mesa: aquamarine dlopen()s
        # the GBM backend out of /run/opengl-driver, libgallium resolves
        # libm.so.6 against the already-loaded 2.42, and the session SIGABRTs
        # a second in -- which reads as "crashes back to the greeter".
        # One nixpkgs, no mismatch, no mkForce anywhere.
        package = lib.mkDefault pkgs.hyprland;
        portalPackage = lib.mkDefault pkgs.xdg-desktop-portal-hyprland;

        # The session launcher starts everything through uwsm.
        withUWSM = true;
      };

      environment.sessionVariables = {
        # The single indirection point: bin/, shell/, themes/, the Hyprland Lua
        # defaults and the menu defaults are all resolved relative to this.
        OMARCHY_PATH = tree;

        # omarchy-capture-screenshot defaults to tensaku-edit, an Arch package
        # not in nixpkgs, which left the Edit action on every screenshot
        # notification doing nothing. satty-edit is the wrapper the package
        # puts around satty.
        OMARCHY_SCREENSHOT_EDITOR = lib.mkDefault "satty-edit";
      };

      environment.systemPackages =
        [cfg.package]
        # Load-bearing, per the header: the scripts are unwrapped by design, so
        # their dependencies must be on the session PATH.
        ++ runtimeDeps
        # sessionPackages alone does not populate
        # /run/current-system/sw/share/wayland-sessions, which is where greetd
        # greeters actually look.
        ++ [sessionPackage]
        ++ lib.optionals cfg.gtkThemeSupport (with pkgs; [
          glib
          gsettings-desktop-schemas
          gnome-themes-extra
          yaru-theme
          adwaita-icon-theme
        ])
        ++ lib.optionals cfg.essentialApps [pkgs.mako]
        ++ lib.optional (cfg.terminal.package != null) cfg.terminal.package;

      services.displayManager.sessionPackages = [sessionPackage];
      # SUPER+RETURN. xdg-terminal-exec reads xdg-terminals.list from
      # $XDG_CONFIG_HOME and then XDG_CONFIG_DIRS (/etc/xdg by default), and
      # only if it finds none does it SCAN desktop entries for the
      # TerminalEmulator category and take whichever it ranks first. Naming the
      # entry makes the choice deterministic -- without it a machine that has
      # both alacritty and foot installed gets whichever the scan prefers.
      environment.etc."xdg/xdg-terminals.list".text = "${cfg.terminal.desktopId}\n";

      # Screen locking. `omarchy-system-lock` calls `omarchy-shell lock lock`,
      # and the QuickShell lock screen authenticates through PAM by SERVICE
      # NAME -- `omarchy-lock-password`. With no such service there is nothing
      # in /etc/pam.d to answer it, so the menu entry runs, nothing locks, and
      # no error surfaces anywhere the user sees.
      #
      # The fingerprint service is separate and only defined when fprintd is
      # actually on: lib.optionalAttrs rather than lib.mkIf, because mkIf on an
      # attrsOf entry still defines the service, and a pam_unix stack behind a
      # name the lock screen treats as "fingerprint" waits forever for a
      # password prompt it never renders.
      security.pam.services =
        {
          omarchy-lock-password = {};
        }
        // lib.optionalAttrs config.services.fprintd.enable {
          omarchy-lock-fingerprint.unixAuth = false;
        };

      # Screen recording, which the package alone cannot do.
      #
      # gpu-screen-recorder is already in passthru.runtimeDeps, so the binary
      # is on PATH -- but gsr-kms-server has to open the DRM device, which
      # needs cap_sys_admin, and on NixOS that comes only from this module's
      # setcap wrapper. Without it the capture backend dies before it starts
      # ("kms server died or never started, exit code: 127") and there is no
      # fallback: gpu-screen-recorder then tries pkexec, which wants a setuid
      # helper NixOS' polkit does not ship. Screenshots go through grim/satty
      # and were never affected.
      #
      # The package in runtimeDeps is not a second copy to worry about:
      # gpu-screen-recorder's own wrapper puts security.wrapperDir
      # (/run/wrappers/bin) ahead of its $out/bin, so the privileged binary
      # wins. ui.enable stays off -- that is GSR's own overlay, and Omarchy
      # drives recording from its own bindings.
      programs.gpu-screen-recorder.enable = lib.mkDefault true;

      # The runtime theme engine. Only the two facts this module knows are
      # set; everything else (stylix.mode, per-application targets,
      # managePlugin) stays on the engine's own defaults and is set directly
      # on programs.nixarchyThemeEngine by whoever wants to change it.
      programs.nixarchyThemeEngine = lib.mkIf cfg.themeEngine.enable {
        enable = true;
        inherit (cfg.themeEngine) user;
      };

      # Lock on suspend. Without this the machine suspends unlocked and wakes
      # straight to the desktop -- the lock screen is never triggered at all,
      # which is not obvious because locking from the menu works fine.
      #
      # omarchy-system-sleep-monitor watches logind for the sleep signal and
      # calls its companion omarchy-system-sleep-lock, which it resolves through
      # $OMARCHY_PATH rather than through PATH -- hence the environment below.
      #
      # ConditionEnvironment=WAYLAND_DISPLAY rather than upstream's
      # ConditionEnvironment=OMARCHY_PATH: the store path is known at build time
      # and passed in directly, so what is worth gating on is whether there is a
      # graphical session to lock.
      systemd.user.services =
        {
          omarchy-sleep-lock = {
            description = "Lock Omarchy before suspend";
            after = ["dbus.socket"];
            requires = ["dbus.socket"];
            partOf = ["graphical-session.target"];
            wantedBy = ["graphical-session.target"];
            path = ["/run/current-system/sw"];
            unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
            environment.OMARCHY_PATH = tree;
            serviceConfig = {
              Type = "simple";
              ExecStart = "${cfg.package}/bin/omarchy-system-sleep-monitor";
              Restart = "always";
              RestartSec = 2;
            };
          };

          # The conditional units further down use optionalAttrs rather than
          # mkIf: mkIf on an attrsOf entry still DEFINES the unit, which for
          # bt-agent would pull bluez-tools into the closure of a machine with
          # no Bluetooth, and for fcitx5 would name a binary not installed.
          # Announce process crashes and offer a diagnosis. The toggle is
          # checked by the unit rather than by `systemctl --user disable`,
          # which has nothing to remove when the unit is declared in the
          # store -- so switching it off has to survive a login some other
          # way, and upstream chose this file.
          omarchy-crash-watch = {
            description = "Announce process crashes and offer an AI diagnosis";
            after = ["graphical-session.target"];
            partOf = ["graphical-session.target"];
            wantedBy = ["graphical-session.target"];
            path = ["/run/current-system/sw"];
            unitConfig = {
              ConditionEnvironment = "WAYLAND_DISPLAY";
              ConditionPathExists = "!%h/.local/state/omarchy/toggles/crash-capture-off";
            };
            serviceConfig = {
              Type = "simple";
              ExecStart = "${cfg.package}/bin/omarchy-crash-watch";
              Restart = "always";
              RestartSec = 5;
            };
          };

          # Undo the internal-monitor-disable toggle when no external display
          # is attached. Ordered BEFORE graphical-session-pre.target because
          # the toggle is read while Hyprland starts: run it later and the
          # session has already come up with the laptop panel off. This is
          # what stops "disable the internal display, undock, reboot" being
          # a machine with no output and no way back.
          omarchy-recover-internal-monitor = {
            description = "Recover the internal monitor when no external display is connected";
            before = ["graphical-session-pre.target"];
            wantedBy = ["graphical-session-pre.target"];
            path = ["/run/current-system/sw"];
            unitConfig.ConditionPathExists = "%h/.local/state/omarchy/toggles/hypr/internal-monitor-disable.lua";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${cfg.package}/bin/omarchy-hw-recover-internal-monitor";
            };
          };
        }
        // lib.optionalAttrs config.hardware.bluetooth.enable {
          # Auto-accept Bluetooth pairing. bt-agent lives in bluez-tools, not
          # bluez, and is NOT in passthru.runtimeDeps -- nothing in the
          # package's bin/ calls it, so the dependency scan never saw it.
          #
          # ExecCondition rather than a hard dependency so a machine whose
          # adapter is absent or disabled skips the unit cleanly instead of
          # entering a restart loop.
          bt-agent = {
            description = "Bluetooth pairing agent (auto-accept)";
            documentation = ["man:bt-agent(1)"];
            unitConfig.ConditionPathIsDirectory = "/sys/class/bluetooth";
            after = ["dbus.socket"];
            requires = ["dbus.socket"];
            wantedBy = ["graphical-session.target"];
            serviceConfig = {
              Type = "simple";
              ExecCondition = "${config.systemd.package}/bin/systemctl is-active --quiet bluetooth.service";
              ExecStart = "${pkgs.bluez-tools}/bin/bt-agent --capability=NoInputNoOutput";
              Restart = "always";
              RestartSec = 2;
            };
          };
        }
        // lib.optionalAttrs cfg.gtkThemeSupport {
          # The half the headless first-run theme cannot do.
          # omarchy-theme-set-gnome and omarchy-cursor-set shell out to
          # gsettings, which needs a running session bus, so GTK apps and the
          # cursor stay on the previous theme until this runs. A system-level
          # user unit rather than a home-manager one, so this module stays the
          # only thing involved.
          omarchy-theme-gnome = {
            description = "Apply the current Omarchy theme's light/dark mode to GTK";
            after = ["graphical-session.target"];
            partOf = ["graphical-session.target"];
            wantedBy = ["graphical-session.target"];
            environment.OMARCHY_PATH = tree;
            # A user unit does not inherit the login PATH, and both scripts
            # call siblings by bare name.
            path = [cfg.package pkgs.glib pkgs.coreutils];
            serviceConfig.Type = "oneshot";
            script = ''
              omarchy-theme-set-gnome || true
              omarchy-cursor-set || true
            '';
          };
        }
        // lib.optionalAttrs usingFcitx5 {
          # What turns the CapsLock compose sequences in ~/.XCompose into
          # text. ConditionEnvironment, not just After=: an `omarchy update`
          # over SSH has a live user manager and no compositor, and an fcitx5
          # started there owns the bus name with no WAYLAND_DISPLAY -- the
          # later graphical login then finds the unit active and never starts
          # a working one.
          omarchy-fcitx5 = {
            description = "Fcitx5 input method (XCompose sequences)";
            after = ["graphical-session.target"];
            partOf = ["graphical-session.target"];
            wantedBy = ["graphical-session.target"];
            unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
            serviceConfig = {
              Type = "simple";
              # notificationitem duplicates the tray entry Omarchy draws itself.
              ExecStart = "${config.i18n.inputMethod.package}/bin/fcitx5 --disable notificationitem";
              # always, not on-failure: fcitx5 exits 0 when another instance
              # owns its bus name, and a clean exit still leaves no input method.
              Restart = "always";
              RestartSec = 2;
            };
          };
        };

      # The half the headless first-run theme cannot do.
      # The half the headless first-run theme cannot do. omarchy-theme-set-gnome
      # and omarchy-cursor-set shell out to gsettings, which needs a running
      # session bus, so GTK apps and the cursor stay on the previous theme until
      # this runs. A system-level user unit rather than a home-manager one, so
      # this module stays the only thing involved.
      # omarchy-theme-set-gnome writes through `gsettings set
      # org.gnome.desktop.interface`, which answers "No schemas installed"
      # unless the schema directory is on XDG_DATA_DIRS -- every one of those
      # writes was otherwise a silent no-op, so a dark theme left GTK apps and
      # Chromium in light mode.
      environment.sessionVariables.XDG_DATA_DIRS = lib.mkIf cfg.gtkThemeSupport [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      ];

      # Read from the vendored upstream SOURCE rather than the built package:
      # builtins.readFile on a derivation path forces that build during
      # evaluation.
      fonts.fontconfig.localConf = lib.mkIf cfg.fonts (lib.mkDefault (
        builtins.readFile "${self.inputs.nixarchy.inputs.omarchy}/default/fontconfig/conf.avail/50-omarchy.conf"
      ));

      fonts.packages = lib.mkIf cfg.fonts (
        # The icon font travels inside the package, at
        # share/fonts/truetype/omarchy.ttf.
        [cfg.package]
        ++ (with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
          nerd-fonts.jetbrains-mono
          font-awesome
          liberation_ttf
        ])
      );

      # A portal is registered, not merely installed, so it belongs here rather
      # than in the package's runtime dependencies. The Hyprland portal comes
      # from programs.hyprland.portalPackage above.
      xdg.portal = {
        enable = lib.mkDefault true;
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
      };
    };
  };
}
