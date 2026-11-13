# Per-session Claude Code accounts: `claude-as <account>` starts a session as
# one subscription, and everything that session starts (Agent-tool subagents,
# nested `claude`) stays on it. See _claude-as.sh for how accounts resolve --
# Omarchy's registry on nixarchy, a standalone one everywhere else.
#
# The same module serves NixOS and nix-darwin: account homes and logins are
# runtime state the script creates itself, so nothing needs home-manager.
#
#   imports = [inputs.magos.nixosModules.claude-accounts];   # or darwinModules
#   magos.claudeAccounts = {
#     enable = true;
#     accounts = {
#       main.label = "Personal";
#       devzero.label = "DevZero";
#     };
#   };
#
# Accounts are signed in at runtime (`claude-as add <name>`); `accounts` only
# names them for the picker and, on Linux, gives each a launcher entry.
{...}: let
  mkClaudeAs = {
    pkgs,
    labels ? {},
  }:
    pkgs.writeShellApplication {
      name = "claude-as";
      # `claude` itself is deliberately not here: it must come from the user's
      # PATH, which on nixarchy is Omarchy's dispatch wrapper.
      runtimeInputs = with pkgs; [coreutils gawk jq gum];
      text =
        builtins.replaceStrings ["@labels@"]
        ["${pkgs.writeText "claude-as-labels.json" (builtins.toJSON labels)}"]
        (builtins.readFile ./_claude-as.sh);
      meta.description = "Start Claude Code as a chosen subscription account";
    };

  mkModule = {isDarwin}: {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.magos.claudeAccounts;
    claude-as = mkClaudeAs {
      inherit pkgs;
      labels = lib.mapAttrs (_: a: a.label) cfg.accounts;
    };

    launchers = lib.mapAttrsToList (id: a:
      pkgs.makeDesktopItem {
        name = "claude-${id}";
        desktopName = "Claude (${a.label})";
        comment = "Claude Code as the ${a.label} account";
        exec = "${cfg.terminal} ${lib.getExe claude-as} ${id}";
        icon = "utilities-terminal";
        categories = ["Development"];
      })
    cfg.accounts;
  in {
    options.magos.claudeAccounts = {
      enable = lib.mkEnableOption "claude-as, per-session Claude Code accounts";

      accounts = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
          options.label = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Name shown in the picker and the launcher entry.";
          };
        }));
        default = {};
        example = lib.literalExpression ''
          {
            main.label = "Personal";
            work.label = "Work";
          }
        '';
        description = ''
          Accounts to name. The id is what `claude-as <id>` takes: `main` is
          the primary account, any other is one added with `claude-as add`
          (or Omarchy's agents panel). Signing in stays a runtime step.
        '';
      };

      terminal = lib.mkOption {
        type = lib.types.str;
        # A store path, so it works on desktops that don't ship it (niri).
        default = lib.getExe pkgs.xdg-terminal-exec;
        defaultText = lib.literalExpression "lib.getExe pkgs.xdg-terminal-exec";
        description = "Command prefix the Linux launcher entries run claude-as in.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        default = claude-as;
        description = "The configured claude-as, labels included.";
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages =
        [claude-as]
        ++ lib.optionals (!isDarwin) launchers;
    };
  };
in {
  flake.nixosModules.claude-accounts = mkModule {isDarwin = false;};
  flake.darwinModules.claude-accounts = mkModule {isDarwin = true;};

  perSystem = {pkgs, ...}: {
    packages.claude-as = mkClaudeAs {inherit pkgs;};
  };
}
