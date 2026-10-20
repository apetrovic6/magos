{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    # Nautili is an opencode fork, so the opencode wrapper drives it unchanged:
    # it still reads OPENCODE_CONFIG / OPENCODE_TUI_CONFIG (NT_* are aliases
    # for the OPENCODE_* names) and ships the same built-in themes.
    #
    # Unlike opencode, `nt` hands work to one shared background service
    # (`nt serve --service`, fixed port) and reuses any running one of the same
    # version. Config is loaded there, from the environment of whichever client
    # started it -- so a service started by an unwrapped `nt` or the desktop app
    # never sees these settings. `nt service restart` from this wrapper fixes it.
    packages.nautili = inputs.wrapper-modules.wrappers.opencode.wrap {
      inherit pkgs;

      package = inputs.nautili.packages.${pkgs.stdenv.hostPlatform.system}.nautili;

      settings = {
        # opencode.nix's servers, plus Atlassian.
        mcp = {
          kaneo = {
            type = "remote";
            url = "https://kaneo.ugalabugala.org/api/mcp";
            enabled = true;
          };

          devenv = {
            type = "remote";
            url = "http://localhost:9090";
            enabled = true;
          };

          # Jira and Confluence. Authenticates with OAuth, so nothing secret
          # lands in the store: run `nt mcp auth atlassian` once to sign in.
          atlassian = {
            type = "remote";
            url = "https://mcp.atlassian.com/v1/mcp";
            enabled = true;
          };
        };

        # No `provider` or `model`, unlike opencode.nix: release builds of
        # Nautili serve models only from the DevZero gateway and prune every
        # other config `provider` entry on load, so the llama-swap block would
        # silently do nothing here.
      };

      tui-settings = {
        theme = "everforest";
      };
    };
  };
}
