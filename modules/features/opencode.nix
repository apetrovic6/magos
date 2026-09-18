{
  self,
  inputs,
  ...
}: let
  defaultTheme = self.lib.colors.everforest-dark-soft;
in {
  perSystem = {pkgs, ...}: {
    packages.opencode = inputs.wrapper-modules.wrappers.opencode.wrap {
      inherit pkgs;

      # Pinned: see the nixpkgs-opencode comment in flake.nix. Without this the
      # wrapper defaults to pkgs.opencode, which is 1.18.30 and broken.
      package = inputs.nixpkgs-opencode.legacyPackages.${pkgs.system}.opencode;

      settings = {
        mcp = {
          kaneo = {
            type = "remote";
            url = "https://kaneo.ugalabugala.org/api/mcp";
            enabled = true;
          };
        };
        model = "llama-swap/coder-30b";

        provider = {
          llama-swap = {
            npm = "@ai-sdk/openai-compatible";
            name = "Local (llama-swap)";
            options.baseURL = "http://127.0.0.1:8000/v1";
            models = {
              # IDs must match llama-swap's model names exactly -- that string is
              # what selects which model it loads.
              "coder-30b" = {
                name = "Qwen3-Coder-30B-A3B (local)";
                limit = {
                  context = 32768;
                  output = 8192;
                };
              };
              "qwen3-14b" = {
                name = "Qwen3 14B (local)";
                limit = {
                  context = 65536;
                  output = 8192;
                };
              };
            };
          };
        };
      };

      tui-settings = {
        theme = "everforest";
      };
    };
  };
}
