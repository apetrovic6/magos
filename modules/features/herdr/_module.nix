# A nix-wrapper-modules wrapper module for herdr (https://herdr.dev), a terminal
# workspace manager for AI coding agents. Upstream ships no module for it, so
# this follows the same shape as the bundled ones and is self-contained enough
# to submit to nix-wrapper-modules as-is.
{
  config,
  lib,
  wlib,
  pkgs,
  ...
}: let
  tomlFmtType = wlib.types.structuredValueWith {
    nullable = false;
    typeName = "TOML";
  };

  hasConfig = config.settings != {} || config.extraSettings != "";

  relPath = "${config.binName}-config/config.toml";
in {
  imports = [wlib.modules.default];

  options = {
    settings = lib.mkOption {
      type = tomlFmtType;
      default = {};
      example = {
        theme.name = "terminal";
        ui.agent_panel_sort = "priority";
      };
      description = ''
        Contents of herdr's `config.toml`.

        `herdr --default-config` prints the annotated upstream default, and
        `herdr config check` validates the result.
      '';
    };

    extraSettings = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Raw TOML appended verbatim after {option}`settings`, for keys the
        structured type cannot express.
      '';
    };
  };

  config = {
    package = lib.mkDefault pkgs.herdr;

    # herdr resolves its runtime state (herdr.sock, herdr-client.sock, the logs,
    # session.json, .plugins.lock) from ~/.config/herdr independently of
    # HERDR_CONFIG_PATH, so pointing the config file at a read-only store path
    # is safe -- it never tries to write next to it.
    constructFiles.config = lib.mkIf hasConfig {
      inherit relPath;
      content = builtins.toJSON config.settings;
      builder = ''
        ${pkgs.remarshal}/bin/json2toml "$1" "$2" && cat "$extraSettingsPath" >> "$2"
      '';
    };

    drv.extraSettings = config.extraSettings;
    drv.passAsFile = ["extraSettings"];

    # envDefault rather than env, so `HERDR_CONFIG_PATH=... herdr` still wins
    # when you want to test a config without rebuilding.
    envDefault.HERDR_CONFIG_PATH =
      lib.mkIf hasConfig "${placeholder config.outputName}/${relPath}";

    # runtimePkgs *suffixes* PATH. That matters more here than for a normal
    # wrapper: every pane herdr spawns inherits this environment, so a prefixed
    # entry would shadow whatever a direnv/devenv shell puts in front of it.
    runtimePkgs = [pkgs.git];

    passthru = lib.optionalAttrs hasConfig {
      generatedConfig = "${config.wrapper.${config.outputName}}/${relPath}";
    };
  };
}
