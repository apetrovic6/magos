{
  self,
  inputs,
  ...
}: let
  c = self.lib.colors.everforest-dark-soft;

  # Pi themes are flat JSON: `vars` names colors, `colors` points UI roles at
  # those names (or at a literal hex). Structure copied from the bundled
  # theme/dark.json, repalletted from base16.
  everforest = {
    name = "everforest";
    vars = {
      bg = "#${c.base00}";
      bgAlt = "#${c.base01}";
      sel = "#${c.base02}";
      dim = "#${c.base03}";
      muted = "#${c.base04}";
      text = "#${c.base05}";
      red = "#${c.base08}";
      orange = "#${c.base09}";
      yellow = "#${c.base0A}";
      green = "#${c.base0B}";
      aqua = "#${c.base0C}";
      blue = "#${c.base0D}";
      purple = "#${c.base0E}";
    };
    colors = {
      accent = "aqua";
      border = "sel";
      borderAccent = "aqua";
      borderMuted = "bgAlt";
      success = "green";
      error = "red";
      warning = "yellow";
      muted = "muted";
      dim = "dim";
      text = "text";
      thinkingText = "dim";

      selectedBg = "sel";
      scrollbarTrack = "bgAlt";
      scrollbarThumb = "dim";
      searchMatchBg = "sel";
      searchMatchText = "text";
      userMessageBg = "bgAlt";
      userMessageText = "text";
      customMessageBg = "bgAlt";
      customMessageText = "text";
      customMessageLabel = "purple";
      toolPendingBg = "bgAlt";
      toolSuccessBg = "bgAlt";
      toolErrorBg = "bgAlt";
      toolTitle = "text";
      toolOutput = "muted";

      mdHeading = "yellow";
      mdLink = "blue";
      mdLinkUrl = "dim";
      mdCode = "aqua";
      mdCodeBlock = "green";
      mdCodeBlockBorder = "dim";
      mdQuote = "muted";
      mdQuoteBorder = "dim";
      mdHr = "dim";
      mdListBullet = "aqua";

      toolDiffAdded = "green";
      toolDiffRemoved = "red";
      toolDiffContext = "muted";

      syntaxComment = "dim";
      syntaxKeyword = "purple";
      syntaxFunction = "blue";
      syntaxVariable = "text";
      syntaxString = "green";
      syntaxNumber = "purple";
      syntaxType = "yellow";
      syntaxOperator = "orange";
      syntaxPunctuation = "muted";

      thinkingOff = "dim";
      thinkingMinimal = "muted";
      thinkingLow = "blue";
      thinkingMedium = "aqua";
      thinkingHigh = "green";
      thinkingXhigh = "yellow";
      thinkingMax = "purple";

      bashMode = "green";
    };
    export = {
      pageBg = "#${c.base00}";
      cardBg = "#${c.base01}";
      infoBg = "#${c.base02}";
    };
  };

  # ── Provider registry ────────────────────────────────────────────────
  #
  # These are all BUILT-IN pi providers — pi already knows their base URL,
  # API type, and model catalog. We only need to supply the API key via
  # the environment variable. Do NOT define custom models.json entries for
  # built-in providers; that shadows pi's catalog and forces you to repeat
  # baseUrl/api/models manually.
  #
  # Each entry:
  #   envVar:   the environment variable pi reads for this provider's key
  #   patterns: pi provider IDs to whitelist in `enabledModels`. One env var
  #             can unlock SEVERAL pi providers — e.g. QWEN_TOKEN_PLAN_API_KEY
  #             unlocks both `qwen-token-plan` and `qwen-token-plan-individual`.
  #             These must be pi's real provider IDs, not arbitrary names.
  #             Discover them with: `pi --list-models` (after setting the key).
  #
  # `patterns` matters because `enabledModels` is a WHITELIST that filters
  # the /model picker and Ctrl+P cycling. Without it, pi lists every
  # provider it can resolve ambient credentials for (Amazon Bedrock via
  # AWS_PROFILE, Vertex via gcloud, etc.) even when you never use them.
  #
  # To add a built-in provider:
  #   1. Add an entry here with `envVar` + `patterns`
  #   2. That's it — the option and wrapper sourcing derive automatically.
  providers = {
    qwen = {
      envVar = "QWEN_TOKEN_PLAN_API_KEY";
      patterns = ["qwen-token-plan/*" "qwen-token-plan-individual/*"];
    };
    anthropic = {
      envVar = "ANTHROPIC_API_KEY";
      patterns = ["anthropic/*"];
    };
    openai = {
      envVar = "OPENAI_API_KEY";
      patterns = ["openai/*"];
    };
  };

  # Custom (non-built-in) providers that need a full models.json entry.
  # Example:
  #   myPrivateLlm = {
  #     baseUrl = "http://llm.internal:8000/v1";
  #     api = "openai-completions";
  #     apiKey = "\${MY_LLM_API_KEY}";
  #     models = [ { id = "my-model"; ... } ];
  #   };
  customProviderModels = {};

  # ── Ambient cloud credentials ───────────────────────────────────────
  #
  # pi's /model picker shows every model "whose provider has usable
  # authentication". For cloud providers that includes AMBIENT credentials
  # picked up from the environment — so merely having AWS_PROFILE exported
  # (or an IAM key pair, or AWS_BEARER_TOKEN_BEDROCK) makes every Amazon
  # Bedrock model appear, even if you never use Bedrock. Same for Vertex via
  # gcloud ADC and Azure via AZURE_OPENAI_*.
  #
  # `enabledModels` does NOT help here: it only scopes startup selection and
  # Ctrl+P cycling, not the picker (verified empirically — `--list-models`
  # returns identical output with and without it).
  #
  # The only way to drop these from the picker is to stop pi from resolving
  # the ambient credential, i.e. unset the variables below. Opt in per
  # provider via `blockAmbientCredentials`.
  #
  # TRADEOFF: unsetting applies to pi's whole process tree, so pi's `bash`
  # tool (and terraform / aws / gcloud / kubectl run through it) loses these
  # credentials too. Only enable for providers you genuinely never call.
  ambientCredentials = {
    amazon-bedrock = [
      "AWS_PROFILE"
      "AWS_ACCESS_KEY_ID"
      "AWS_SECRET_ACCESS_KEY"
      "AWS_SESSION_TOKEN"
      "AWS_BEARER_TOKEN_BEDROCK"
      "AWS_CONTAINER_CREDENTIALS_FULL_URI"
      "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"
      "AWS_WEB_IDENTITY_TOKEN_FILE"
    ];
    google-vertex-ai = [
      "GOOGLE_CLOUD_API_KEY"
      "GOOGLE_APPLICATION_CREDENTIALS"
      "GOOGLE_CLOUD_PROJECT"
      "GCLOUD_PROJECT"
      "GOOGLE_CLOUD_LOCATION"
    ];
    azure-openai = [
      "AZURE_OPENAI_API_KEY"
      "AZURE_OPENAI_BASE_URL"
      "AZURE_OPENAI_RESOURCE_NAME"
    ];
    cloudflare-workers-ai = [
      "CLOUDFLARE_API_KEY"
      "CLOUDFLARE_ACCOUNT_ID"
    ];
  };
in {
  # ── NixOS module ─────────────────────────────────────────────────────
  #
  # Usage in omnissiah (e.g. stc/workstation.nix or a machine config):
  #
  #   imports = [ self.inputs.magos.nixosModules.pi ];
  #
  #   magos.agents.pi = {
  #     enable = true;
  #     apiKeys.qwen = config.clan.core.vars.generators.pi-api-keys.files."qwen-api-key".path;
  #   };
  #
  # This module builds a SINGLE wrapper directly around the unwrapped
  # upstream pi binary (exposed via `passthru.unwrapped`), performing all
  # setup in one `--run` block in order:
  #
  #   1. export API keys from the configured secret files
  #   2. source ~/.config/pi/secrets.env (manual override)
  #   3. symlink generated settings.json / models.json / mcp.json
  #   4. patch `enabledModels` into settings.json with jq
  #
  # Single-layer wrapping matters: nesting `wrapProgram` over a file that is
  # already a wrapper script makes makeWrapper emit a collision-renamed
  # `.pi-wrapped_` and silently DROP the outer --run payload.
  #
  # No overlay needed — the module owns the whole lifecycle.
  flake.nixosModules.pi = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.magos.agents.pi;

    # Filter enabled keys — only non-null values produce wrapper lines.
    enabledKeys = lib.filterAttrs (_: v: v != null) cfg.apiKeys;

    # Build the secret-sourcing shell snippet from enabled keys.
    sourceSnippet = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: path: let
          envVar = providers.${name}.envVar;
        in ''[ -r "${toString path}" ] && export ${envVar}="$(< "${toString path}")"''
      )
      enabledKeys
    );

    # enabledModels: a WHITELIST that filters pi's /model picker and Ctrl+P
    # cycling. Derived from which apiKeys.* are configured; override the
    # option to customise.
    #
    # llama-swap always qualifies (dummy "local" key baked into models.json).
    # Built-in providers are added only when their apiKey path is set, so an
    # unconfigured provider never triggers a "No models match" warning.
    enabledModels =
      if cfg.enabledModels != null then
        cfg.enabledModels
      else
        ["llama-swap/*"]
        ++ builtins.concatMap (name: providers.${name}.patterns) (builtins.attrNames enabledKeys);

    enabledModelsJson = builtins.toJSON enabledModels;

    # The whitelist is passed to jq via a store FILE, never as an inline
    # literal. The whole --run payload is single-quoted, so embedding a
    # single-quoted JSON string inside it closes the outer quote early and
    # makeWrapper silently discards the ENTIRE payload (the wrapper builds
    # fine but contains no --run block). `$(< file)` avoids nested quoting.
    enabledModelsFile = pkgs.writeText "pi-enabled-models.json" enabledModelsJson;

    # The base package exposes its unwrapped upstream binary and config file
    # paths via passthru, so this module can build ONE wrapper instead of
    # nesting a second wrapProgram on top of the base wrapper.
    #
    # Why this matters: `symlinkJoin { paths = [cfg.package]; }` makes
    # $out/bin/pi a symlink to a file that is ALREADY a wrapper script.
    # Running wrapProgram over that produces makeWrapper's collision-renamed
    # `.pi-wrapped_` inner script and silently DROPS the outer --run payload
    # — which is why PI_ENABLED_MODELS was never exported and the jq patch
    # never fired. Wrapping the unwrapped binary avoids the nesting entirely.
    base = cfg.package;
    unwrappedPi = base.passthru.unwrapped or base;
    configFiles = base.passthru.configFiles or null;

    # Config symlink setup — only when the base package exposes its files.
    configSetupSnippet =
      if configFiles == null then
        ""
      else ''
        d="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
        mkdir -p "$d"
        ln -sfn ${configFiles.settings} "$d/settings.json"
        ln -sfn ${configFiles.models} "$d/models.json"
        ln -sfn ${configFiles.mcp} "$d/mcp.json"
      '';

    # Unset ambient cloud credentials for the providers listed in
    # blockAmbientCredentials, so pi stops treating them as authenticated
    # and drops their models from the /model picker.
    blockSnippet = lib.concatStringsSep "\n" (
      builtins.concatMap (
        provider: map (v: "unset ${v} 2>/dev/null || true") ambientCredentials.${provider}
      )
      cfg.blockAmbientCredentials
    );

    wrappedPi = pkgs.symlinkJoin {
      name = "pi-magos";
      paths = [unwrappedPi];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/pi --run '
          # 1. Drop ambient cloud credentials for blocked providers so they
          #    do not clutter the /model picker.
          ${blockSnippet}

          # 2. Export API keys from the configured secret files.
          ${sourceSnippet}

          # 3. Manual override: ~/.config/pi/secrets.env (KEY=value per line).
          _pi_manual="$HOME/.config/pi/secrets.env"
          if [ -f "$_pi_manual" ]; then
            set -a; . "$_pi_manual"; set +a
          fi

          # 4. Link generated config into the (writable) agent dir.
          ${configSetupSnippet}

          # 5. Patch enabledModels (scopes startup selection + Ctrl+P cycling;
          #    it does NOT filter the /model picker). Runs AFTER the symlink
          #    above so settings.json exists; mv replaces the symlink with a
          #    real file.
          d="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
          if [ -f "$d/settings.json" ]; then
            ${pkgs.jq}/bin/jq --argjson em "$(< ${enabledModelsFile})" \
              ".enabledModels = \$em" \
              "$d/settings.json" > "$d/settings.json.tmp" \
              && mv "$d/settings.json.tmp" "$d/settings.json"
          fi
        '
      '';
    };
  in {
    options.magos.agents.pi = {
      enable = lib.mkEnableOption "pi coding agent with declarative API key injection";

      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.pi;
        defaultText = lib.literalExpression "self.packages.\${system}.pi";
        description = ''
          Base pi package to wrap. Includes config symlinks, themes, models,
          and extensions. The module wraps this with secret sourcing and
          adds it to environment.systemPackages when `enable` is true.
          Override only if you need a custom pi build.
        '';
      };

      enabledModels = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        example = ["llama-swap/*" "qwen-token-plan/*"];
        description = ''
          Whitelist of model patterns shown in `/model` and used for Ctrl+P
          cycling. When `null` (the default) it is derived automatically:
          `llama-swap/*` plus the real pi provider IDs of every configured
          `apiKeys.*` entry.

          Set this to override the derived list. Patterns use pi's `--models`
          format: exact IDs, fuzzy matches, or `provider/*` globs. Listing a
          provider with no resolvable credentials produces a
          "No models match pattern" warning.
        '';
      };

      blockAmbientCredentials = lib.mkOption {
        type = lib.types.listOf (lib.types.enum (builtins.attrNames ambientCredentials));
        default = [];
        example = ["amazon-bedrock" "google-vertex-ai"];
        description = ''
          Cloud providers whose ambient credentials should be unset before pi
          starts, so their models disappear from the `/model` picker.

          pi treats a provider as authenticated when it can resolve ambient
          cloud credentials — e.g. merely having `AWS_PROFILE` exported makes
          every Amazon Bedrock model appear. `enabledModels` cannot suppress
          this (it only scopes startup selection and Ctrl+P cycling).

          WARNING: this unsets the variables for pi's whole process tree, so
          pi's `bash` tool — and `terraform` / `aws` / `gcloud` / `kubectl`
          run through it — loses those credentials too. Only list providers
          you never call from pi.

          Available: ${lib.concatStringsSep ", " (builtins.attrNames ambientCredentials)}.
        '';
      };

      apiKeys = lib.mapAttrs (name: providerDef:
        lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
          default = null;
          example = "/run/secrets/pi-api-keys/qwen-api-key";
          description = ''
            Path to a file containing the ${name} API key. Read at runtime
            and exported as `$${providerDef.envVar}`, which pi (and omp)
            pick up from the environment. For built-in providers, pi already
            knows the base URL, API type, and model catalog — only the key
            is needed.

            Typically pointed at a sops-nix secret path from
            `clan.core.vars.generators`, but any readable file works.
          '';
        }
      ) providers;
    };

    config = lib.mkIf cfg.enable {
      # The module owns installation — no overlay needed.
      environment.systemPackages = [wrappedPi];
    };
  };

  # ── Base package: config symlinks, models, themes ────────────────────
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    piPkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

    # Same llama-swap endpoint opencode.nix talks to. IDs must match
    # llama-swap's model names exactly, and contextWindow must stay in sync
    # with each model's ctxSize in machines/phalanx/llama-swap.nix
    # (omnissiah) -- pi has no metadata for a custom endpoint either.
    #
    # Only CUSTOM (non-built-in) providers belong here. Built-in providers
    # (qwen, anthropic, openai, etc.) already ship in pi's catalog — adding
    # them here would shadow it and force us to repeat baseUrl/api/models.
    models = {
      providers =
        {
          llama-swap = {
            baseUrl = "http://127.0.0.1:8000/v1";
            api = "openai-completions";
            # llama-swap ignores the value, but pi hides models from /model until
            # it can resolve *some* credential for the provider.
            apiKey = "local";
            models = [
              {
                id = "qwen36-35b-q4";
                name = "Qwen3.6-35B-A3B IQ4_XS (local)";
                contextWindow = 131072;
                maxTokens = 8192;
                reasoning = true;
              }
              {
                id = "coder-30b";
                name = "Qwen3-Coder-30B-A3B (local)";
                contextWindow = 32768;
                maxTokens = 8192;
              }
              {
                id = "qwen38-flash-q3";
                name = "Qwen3.8-Flash-Next IQ3_XXS (local, RAM-offloaded)";
                contextWindow = 131072;
                maxTokens = 8192;
                reasoning = true;
              }
            ];
          };
        }
        //
        # Custom (non-built-in) providers from customProviderModels.
        customProviderModels;
    };

    # `pi install` cannot work here -- it only knows how to append to
    # settings.json, which is a read-only store symlink, so it reports success
    # and writes nothing. Extensions are vendored as derivations instead and
    # listed below; pi resolves absolute paths in `extensions` directly.
    #
    # An extension importing only the packages pi supplies to extensions
    # (@earendil-works/pi-*, typebox) needs no node_modules and vendors as a
    # plain copy. One with its own npm dependencies needs those resolved into
    # a nearby node_modules -- buildNpmEnvironment territory, not this helper.
    mkPiExtension = {
      name,
      src,
      # Subdirectory of src holding the entry point, if not the root.
      path ? ".",
    }:
      pkgs.runCommand "pi-ext-${name}" {} ''
        mkdir -p $out
        cp -r ${src}/${path}/. $out/
      '';

    # Vendored third-party packages: full package dirs whose own package.json
    # manifest tells pi which resources to load.
    webAccess = import ./_packages/web-access.nix {inherit pkgs;};
    mcpAdapter = import ./_packages/mcp-adapter.nix {inherit pkgs;};
    babysitter = import ./_packages/babysitter.nix {inherit pkgs;};

    # Extensions written in this repo. Top-level .ts files are discovered
    # individually; a subdirectory needs an index.ts.
    magosExtensions = mkPiExtension {
      name = "magos";
      src = ./_extensions;
    };

    # MCP servers for pi-mcp-adapter, mirroring the mcp block in
    # opencode.nix. Pi has no native MCP; the adapter supplies it.
    #
    # This lands at <agent dir>/mcp.json, which the adapter ranks above the
    # shared ~/.config/mcp/mcp.json but below a project .mcp.json and
    # .pi/mcp.json -- so per-project servers still override these, and
    # `/mcp disable`, which writes .pi/mcp.json inside the project, keeps
    # working against a read-only file here.
    #
    # `url` covers both of these (StreamableHTTP, falling back to SSE).
    # Stdio servers take `command`/`args` instead. For an authenticated
    # endpoint prefer `bearerTokenEnv` over `bearerToken`: everything in this
    # attrset lands in the world-readable nix store.
    mcp = {
      mcpServers = {
        kaneo.url = "https://kaneo.ugalabugala.org/api/mcp";
        devenv.url = "http://localhost:9090";
      };
    };

    settings = {
      defaultProvider = "llama-swap";
      defaultModel = "qwen38-flash-q3";
      theme = "everforest";
      # Resource paths may be absolute, so the theme dir needs no symlink.
      themes = ["${themesDir}"];
      extensions = ["${magosExtensions}"];
      packages = [
        "${webAccess}"
        "${mcpAdapter}"
        "${babysitter}"
      ];
      quietStartup = true;
      enableInstallTelemetry = false;
      # enabledModels is NOT set here — it's injected at runtime by the
      # base wrapper when PI_ENABLED_MODELS is set by the module wrapper.
    };

    themesDir = pkgs.runCommand "pi-themes" {} ''
      mkdir -p $out
      cp ${pkgs.writeText "everforest.json" (builtins.toJSON everforest)} $out/everforest.json
    '';

    settingsFile = pkgs.writeText "settings.json" (builtins.toJSON settings);
    modelsFile = pkgs.writeText "models.json" (builtins.toJSON models);
    mcpFile = pkgs.writeText "mcp.json" (builtins.toJSON mcp);
  in {
    # Base wrapper: creates config symlinks for standalone use (e.g. `nix run`,
    # or machines that don't import the NixOS module).
    #
    # passthru exposes the unwrapped upstream binary and the generated config
    # files so the NixOS module can build a SINGLE wrapper around them rather
    # than nesting a second wrapProgram (which silently drops --run payloads).
    packages.pi = pkgs.symlinkJoin {
      name = "pi";
      paths = [piPkg];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/pi \
          --run 'd="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"; mkdir -p "$d" && ln -sfn ${settingsFile} "$d/settings.json" && ln -sfn ${modelsFile} "$d/models.json" && ln -sfn ${mcpFile} "$d/mcp.json"'
      '';
      passthru = {
        unwrapped = piPkg;
        configFiles = {
          settings = settingsFile;
          models = modelsFile;
          mcp = mcpFile;
        };
      };
    };
  };
}
