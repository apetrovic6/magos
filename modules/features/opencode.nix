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
      # wrapper defaults to pkgs.opencode, built against a bun that breaks it.
      package = inputs.nixpkgs-opencode.legacyPackages.${pkgs.system}.opencode;

      settings = {
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
        };
        model = "llama-swap/qwen36-35b-q4";

        provider = {
          llama-swap = {
            npm = "@ai-sdk/openai-compatible";
            name = "Local (llama-swap)";
            options.baseURL = "http://127.0.0.1:8000/v1";
            models = {
              # IDs must match llama-swap's model names exactly -- that string is
              # what selects which model it loads. Keep `limit.context` in sync
              # with each model's ctxSize in machines/phalanx/llama-swap.nix
              # (omnissiah): opencode has no metadata for a custom provider, so
              # without it it will happily overrun the server's window.
              "coder-30b" = {
                name = "Qwen3-Coder-30B-A3B (local)";
                limit = {
                  context = 32768;
                  output = 8192;
                };
              };

              # Reasoning model, unlike coder-30b: it emits a separate
              # `reasoning_content` field and spends tokens thinking before it
              # answers or calls a tool. Those tokens count against the output
              # budget -- a short max_tokens returns empty content and
              # finish_reason "length" because it never finished thinking. The
              # budget below is raised accordingly. Tool calling verified
              # working against llama-swap.
              "qwen36-35b-q4" = {
                name = "Qwen3.6-35B-A3B IQ4_XS (local)";
                limit = {
                  context = 65536;
                  output = 8192;
                };
              };

              # Same weights as -q4 above, lower precision, fits entirely in
              # VRAM. Reasoning model too, so the same raised output budget.
              "qwen36-35b-q3" = {
                name = "Qwen3.6-35B-A3B IQ3_XXS (local)";
                limit = {
                  context = 65536;
                  output = 8192;
                };
              };

              # Dense 24B, not a reasoning model -- no thinking tokens to pay
              # for, so the standard output budget is enough. Expect it to be
              # markedly slower than the A3B models: it activates all 24B per
              # token against their ~3B.
              "devstral-24b" = {
                name = "Devstral Small 2 24B (local)";
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
