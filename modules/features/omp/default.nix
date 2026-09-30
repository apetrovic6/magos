{
  self,
  inputs,
  ...
}: let
  c = self.lib.colors.everforest-dark-soft;

  # OMP uses YAML config files instead of Pi's JSON.
  # Main config goes in ~/.omp/agent/config.yml
  ompConfig = {
    startup = {
      quiet = true;
      enableTelemetry = false;
    };

    # Use Everforest via the built-in theme name or hex palette.
    # OMP supports custom themes via ~/.omp/themes/ or the `theme` field.
    # We'll use a flat hex mapping approach since OMP reads theme vars.
    theme = {
      dark = "everforest";
      light = "light";
    };

    # Default model role routing
    modelRoles.default = "llama-swap/qwen36-35b-q4";

    # enabledModels is NOT set here — it's injected at runtime by the
    # base wrapper when OMP_ENABLED_MODELS is set by the module wrapper.
  };

  # MCP servers — same as opencode.nix and pi/default.nix
  ompMcp = {
    mcpServers = {
      kaneo.url = "https://kaneo.ugalabugala.org/api/mcp";
      devenv.url = "http://localhost:9090";
    };
  };

  # Everforest theme as a flat TOML/JSON OMP can consume.
  # OMP themes are stored in ~/.omp/themes/<name>/theme.json or similar.
  # We'll create a theme dir with a flat vars+colors structure (like Pi).
  everforestOmpTheme = {
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
    };
  };

  # Provider registry shared with the pi module. OMP reads the same
  # magos.agents.pi.apiKeys options to source secrets, so this map must
  # stay in sync with pi/default.nix.
  #
  # These are all BUILT-IN providers — just env var names + real pi provider
  # IDs for the enabledModels whitelist. See pi/default.nix for the full
  # explanation of why `patterns` uses pi's provider IDs rather than the
  # option names.
  #
  # TODO: extract into a shared module if other agents need the same keys.
  sharedProviders = {
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

  # Ambient cloud credentials that make pi/omp treat a provider as
  # authenticated. Duplicated from pi/default.nix (see the note there for why
  # unsetting is the only way to drop these from the /model picker).
  #
  # TODO: extract sharedProviders + ambientCredentials into one shared module.
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
  # OMP piggybacks on pi's apiKeys options since they share the same
  # environment variables. When pi's module sets apiKeys.qwen, omp
  # automatically picks up the same key.
  #
  # Usage:
  #
  #   imports = [
  #     self.inputs.magos.nixosModules.pi
  #     self.inputs.magos.nixosModules.omp
  #   ];
  #
  #   magos.agents.pi = {
  #     enable = true;
  #     apiKeys.qwen = config.clan.core.vars.generators.pi-api-keys.files."qwen-api-key".path;
  #   };
  #   magos.agents.omp.enable = true;   # picks up the same keys
  #
  # The module owns installation — no overlay needed.
  flake.nixosModules.omp = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.magos.agents.omp;
    piCfg = config.magos.agents.pi;

    # Reuse pi's apiKeys for secret sourcing.
    enabledKeys = lib.filterAttrs (_: v: v != null) piCfg.apiKeys;

    sourceSnippet = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: path: let
          envVar = sharedProviders.${name}.envVar;
        in ''[ -r "${toString path}" ] && export ${envVar}="$(< "${toString path}")"''
      )
      enabledKeys
    );

    enabledModelsJson = builtins.toJSON (
      ["llama-swap/*"]
      ++ builtins.concatMap (name: sharedProviders.${name}.patterns) (builtins.attrNames enabledKeys)
    );

    # Passed to jq via a store FILE, never an inline literal — the --run
    # payload is single-quoted, so a nested single-quoted JSON string closes
    # the outer quote and makeWrapper silently drops the whole payload.
    enabledModelsFile = pkgs.writeText "omp-enabled-models.json" enabledModelsJson;

    # Build ONE wrapper around the unwrapped upstream omp binary. See the pi
    # module for why nesting wrapProgram over an existing wrapper silently
    # drops the outer --run payload.
    base = cfg.package;
    unwrappedOmp = base.passthru.unwrapped or base;
    configFiles = base.passthru.configFiles or null;
    themesDir = base.passthru.themesDir or null;

    configSetupSnippet =
      if configFiles == null then
        ""
      else ''
        mkdir -p "$HOME/.omp/agent" "$HOME/.omp/themes/everforest"
        rm -f "$HOME/.omp/agent/config.yml" "$HOME/.omp/agent/models.json" "$HOME/.omp/agent/mcp.json" "$HOME/.omp/themes/everforest/theme.json"
        cp ${configFiles.config} "$HOME/.omp/agent/config.yml"
        cp ${configFiles.models} "$HOME/.omp/agent/models.json"
        cp ${configFiles.mcp} "$HOME/.omp/agent/mcp.json"
        cp ${themesDir}/everforest/theme.json "$HOME/.omp/themes/everforest/theme.json"
      '';

    blockSnippet = lib.concatStringsSep "\n" (
      builtins.concatMap (
        provider: map (v: "unset ${v} 2>/dev/null || true") ambientCredentials.${provider}
      )
      piCfg.blockAmbientCredentials
    );

    wrappedOmp = pkgs.symlinkJoin {
      name = "omp-magos";
      paths = [unwrappedOmp];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/omp --run '
          # 1. Drop ambient cloud credentials for blocked providers.
          ${blockSnippet}

          # 2. Export API keys from the configured secret files.
          ${sourceSnippet}

          # 3. Manual override.
          _pi_manual="$HOME/.config/pi/secrets.env"
          if [ -f "$_pi_manual" ]; then
            set -a; . "$_pi_manual"; set +a
          fi

          # 4. Copy generated config into ~/.omp (real files, so SQLite can
          #    create agent.db next to them).
          ${configSetupSnippet}

          # 5. Patch enabledModels into config.yml (JSON despite extension).
          _config="$HOME/.omp/agent/config.yml"
          if [ -f "$_config" ]; then
            ${pkgs.jq}/bin/jq --argjson em "$(< ${enabledModelsFile})" \
              ".enabledModels = \$em" \
              "$_config" > "$_config.tmp" \
              && mv "$_config.tmp" "$_config"
          fi
        '
      '';
    };
  in {
    options.magos.agents.omp = {
      enable = lib.mkEnableOption "OMP (Oh My Pi) coding agent";

      package = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.omp;
        defaultText = lib.literalExpression "self.packages.\${system}.omp";
        description = "Base OMP package to wrap with secret sourcing.";
      };
    };

    config = lib.mkIf cfg.enable {
      # The module owns installation — no overlay needed.
      environment.systemPackages = [wrappedOmp];
    };
  };

  # ── Base package: config, models, themes ─────────────────────────────
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    ompPkg = inputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.omp;

    # OMP models: only custom (non-built-in) providers. Built-in providers
    # (qwen, anthropic, openai) ship in OMP's catalog — adding them here
    # would shadow it and force us to repeat baseUrl/api/models.
    ompModels = {
      providers = {
        llama-swap = {
          baseUrl = "http://127.0.0.1:8000/v1";
          api = "openai-completions";
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
      };
    };

    # Serialize configs to derivations
    ompConfigFile = pkgs.writeText "omp-config.yml" (builtins.toJSON ompConfig);
    ompModelsFile = pkgs.writeText "omp-models.json" (builtins.toJSON ompModels);
    ompMcpFile = pkgs.writeText "omp-mcp.json" (builtins.toJSON ompMcp);
    ompThemeFile = pkgs.writeText "everforest.json" (builtins.toJSON everforestOmpTheme);

    # Theme dir: ~/.omp/themes/everforest/theme.json
    ompThemesDir = pkgs.symlinkJoin {
      name = "omp-themes";
      paths = [];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        mkdir -p $out/everforest
        cp ${ompThemeFile} $out/everforest/theme.json
      '';
    };
  in {
    # Base wrapper: copies config files for standalone use (e.g. `nix run`,
    # or machines that don't import the NixOS module).
    #
    # passthru exposes the unwrapped binary, config files and theme dir so the
    # NixOS module can build a SINGLE wrapper rather than nesting wrapProgram.
    packages.omp = pkgs.symlinkJoin {
      name = "omp";
      paths = [ompPkg];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/omp \
          --run '
            mkdir -p "$HOME/.omp/agent" "$HOME/.omp/themes/everforest"
            rm -f "$HOME/.omp/agent/config.yml" "$HOME/.omp/agent/models.json" "$HOME/.omp/agent/mcp.json" "$HOME/.omp/themes/everforest/theme.json"
            cp ${ompConfigFile} "$HOME/.omp/agent/config.yml"
            cp ${ompModelsFile} "$HOME/.omp/agent/models.json"
            cp ${ompMcpFile} "$HOME/.omp/agent/mcp.json"
            cp ${ompThemesDir}/everforest/theme.json "$HOME/.omp/themes/everforest/theme.json"
          '
      '';
      passthru = {
        unwrapped = ompPkg;
        themesDir = ompThemesDir;
        configFiles = {
          config = ompConfigFile;
          models = ompModelsFile;
          mcp = ompMcpFile;
        };
      };
    };
  };
}
