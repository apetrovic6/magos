{
  self,
  lib,
  inputs,
  ...
}: let
  # Underscore-prefixed so `import-tree` skips it: this is a nix-wrapper-modules
  # module, not a flake-parts one.
  herdrModule = import ./_module.nix;

  # Mirrors what used to live in ~/.config/herdr/config.toml, plus the full
  # keybinding skeleton.
  baseSettings = {
    keys = import ./_config/keys.nix;

    # The first-run notification setup saves its answer by writing this key
    # back into config.toml, which is a read-only store path here, so it
    # fails ("read-only file system") and re-runs on every start.
    onboarding = false;

    ui.agent_panel_sort = "priority";

    theme = {
      name = "terminal";
      auto_switch = false;
    };
  };

  # mkDefault every leaf rather than whole sections, so overriding one setting
  # downstream does not have to restate (or mkForce) its siblings:
  #
  #   self.packages.x86_64-linux.herdr.wrap {
  #     settings.keys.detach = "prefix+d";
  #   }
  #
  # Lists (e.g. keys.command) are leaves here, so overriding one replaces it
  # wholesale rather than appending.
  settings = lib.mapAttrsRecursive (_: lib.mkDefault) baseSettings;

  makeHerdrPackage = {pkgs}:
    inputs.wrapper-modules.lib.evalPackage {
      inherit pkgs settings;
      imports = [herdrModule];
    };

  # Matches what `herdr integration install claude` writes into settings.json.
  # The matcher is herdr's SESSION_START_MATCHER (src/integration/
  # claude_settings.rs): Claude's documented SessionStart sources.
  claudeSessionStartMatcher = "^(startup|resume|clear|compact|fork)$";

  # The per-agent lifecycle integrations `herdr integration install <agent>`
  # would write, taken from the source of the same herdr build that runs the
  # server, so the two cannot drift. They are installed declaratively instead
  # (pi and omp in their own modules, Claude by homeModules.herdr below)
  # because the imperative installer edits files Nix owns: pi's settings.json
  # is a read-only store symlink, and omp's wrapper rewrites its agent dir on
  # every launch.
  #
  # `herdr integration status` still reports pi and Claude "not installed": it
  # only looks for its own copies at the default paths.
  makeIntegrations = {pkgs}: let
    assets = "${pkgs.herdr.src}/src/integration/assets";

    # The hook bails out silently (exit 0) when python3 is not on PATH, and
    # it is not on this system's PATH, so a bare copy registers fine and then
    # never reports anything.
    claudeHook = pkgs.writeShellScript "herdr-claude-agent-state" ''
      export PATH=${pkgs.python3}/bin:$PATH
      exec ${pkgs.bash}/bin/sh ${assets}/claude/herdr-agent-state.sh "$@"
    '';

    claudeHooks = builtins.toJSON {
      hooks.SessionStart = [
        {
          matcher = claudeSessionStartMatcher;
          hooks = [
            {
              type = "command";
              command = "${claudeHook} session";
              timeout = 10;
            }
          ];
        }
      ];
    };

    claudePluginManifest = builtins.toJSON {
      name = "herdr-integration";
      description = "Reports Claude Code session state to herdr";
      version = pkgs.herdr.version;
    };
  in
    pkgs.runCommand "herdr-integrations-${pkgs.herdr.version}" {} ''
      install -Dm644 ${assets}/pi/herdr-agent-state.ts $out/pi/herdr-agent-state.ts
      install -Dm644 ${assets}/omp/herdr-agent-state.ts $out/omp/herdr-agent-state.ts

      # A Claude Code plugin rather than an entry in settings.json: Claude
      # rewrites that file itself, and a declared `hooks.SessionStart` would
      # replace the whole array, other tools' hooks included.
      install -Dm644 ${pkgs.writeText "plugin.json" claudePluginManifest} \
        $out/claude-plugin/.claude-plugin/plugin.json
      install -Dm644 ${pkgs.writeText "hooks.json" claudeHooks} \
        $out/claude-plugin/hooks/hooks.json
    '';
in {
  # Exported so the module itself is reusable (and upstreamable) independently
  # of the settings baked in above.
  flake.wrapperModules.herdr = herdrModule;

  # Claude Code's herdr integration. pi and omp pick theirs up in their own
  # modules (magos.agents.pi / magos.agents.omp), since those wrappers own the
  # agent dirs the extensions go in.
  #
  #   imports = [inputs.magos.homeModules.herdr];
  #   magos.herdr.claude.enable = true;
  flake.homeModules.herdr = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.magos.herdr.claude.enable = lib.mkEnableOption ''
      herdr's Claude Code integration, as a Claude Code plugin. Requires
      `programs.claude-code.enable`. Replaces `herdr integration install
      claude`: after switching, run `herdr integration uninstall claude` once
      so the old settings.json entry does not report every session twice
    '';

    config = lib.mkIf config.magos.herdr.claude.enable {
      programs.claude-code.plugins.herdr-integration = "${
        self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-integrations
      }/claude-plugin";
    };
  };

  perSystem = {pkgs, ...}: {
    packages.herdr = makeHerdrPackage {inherit pkgs;};
    packages.herdr-integrations = makeIntegrations {inherit pkgs;};
  };
}
