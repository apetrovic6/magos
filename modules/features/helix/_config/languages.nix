{
  language = [
    {
      name = "nix";
      language-servers = ["nixd"];
      # `-` is load-bearing: it puts alejandra in stdin->stdout mode, which is
      # the contract Helix expects (buffer in, replacement buffer out).
      #
      # An include PATH here instead -- `args = ["."]` -- is a different mode
      # entirely: alejandra ignores stdin, rewrites every .nix file under the cwd
      # in place, and prints a `Formatted: <path>` line per changed file to
      # stdout. Helix then takes that as the new buffer, so saving any .nix file
      # replaces it with the name of some *other* file. It destroyed a 190-line
      # file that way.
      #
      # `-q` silences the informational chatter (it goes to stderr, so stdout is
      # clean either way, but alejandra itself suggests it).
      formatter = {
        command = "alejandra";
        args = ["-q" "-"];
      };
      auto-format = true;
    }
    {
      name = "yaml";
      file-types = ["yaml" "yml"];
      language-servers = ["yaml-language-server"];
    }
    {
      name = "rust";
      file-types = ["rs"];
      language-servers = ["rust-analyzer" "tailwindcss-language-server"];
    }
  ];

  language-server.yaml-language-server = {
    command = "yaml-language-server";
    args = ["--stdio"];
    config.yaml = {
      validate = true;
      hover = true;
      completion = true;
      format.enable = true;
      schemas = {
        kubernetes = [
          "*deployment*.yaml"
          "*service*.yaml"
          "*.y{a,}ml"
          "*configmap*.yaml"
          "*secret*.yaml"
          "*pod*.yaml"
          "*namespace*.yaml"
          "*ingress*.yaml"
        ];
        "https://raw.githubusercontent.com/SchemaStore/schemastore/master/src/schemas/json/kustomization.json" = [
          "*kustomization.yaml"
          "*kustomize.yaml"
        ];
        "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" = [
          "*workflow*.yaml"
          "*template*.yaml"
        ];
      };
    };
  };

  # https://book.leptos.dev/getting_started/leptos_dx.html
  language-server.rust-analyzer = {
    config = {
      check.command = "clippy";

      # Leptos generates the body of `#[server]` twice — once for the server,
      # once as the client-side stub — behind cfgs rust-analyzer cannot see. It
      # expands the macro anyway and then reports errors in code that never
      # compiles in that configuration. Skipping the expansion is cheaper than
      # reading around the noise.
      #
      # `"component"` can be added to this list for the same reason and Leptos
      # documents it as an option, but it is deliberately left out: ignoring it
      # also throws away the generated props struct, and with it completion and
      # type information for every component's props — which is most of what
      # rust-analyzer is useful for in a Leptos view.
      #
      # Scoped to `leptos_macro`, so this is inert in a non-Leptos project.
      procMacro.ignored.leptos_macro = ["server"];

      # Leptos steers compilation with `csr` / `ssr` / `hydrate` feature flags,
      # and rust-analyzer otherwise only sees the default set — so in an SSR
      # project half the code reads as dead or missing.
      #
      # Unlike the setting above this one is NOT scoped to Leptos: it applies to
      # every Rust project. That is fine where features are additive, but a crate
      # with mutually exclusive features will fail to analyse with all of them
      # on at once. If that ever bites, drop this line and put it in that
      # project's own `.helix/languages.toml` instead — Helix merges a
      # per-project file over this one.
      cargo.allFeatures = true;
    };
  };

  # Tailwind completion inside Rust, for Leptos `view!` blocks.
  #
  # Attached to every Rust file rather than one project: with no CSS entry point
  # importing tailwindcss anywhere above the file, the server finds no config and
  # stays silent, so a non-Tailwind project pays only the process. Tailwind v4
  # has no JS config file — the server looks for `@import "tailwindcss"` in a
  # .css file instead (in the fishing repo that is apps/web/styles/tailwind.css),
  # and `experimental.configFile` is the escape hatch when the search fails.
  language-server.tailwindcss-language-server = {
    command = "tailwindcss-language-server";
    args = ["--stdio"];

    config = {
      # Makes the server read .rs as HTML, which is what gets completion and
      # hover working inside a plain `class="..."` attribute in a `view!`.
      # Everything else below is for the class names that are NOT in an
      # attribute, which a regex has to dig out by hand.
      userLanguages.rust = "html";

      # Each entry is [outer, inner]: the first regex finds the construct, the
      # second pulls class names out of the string literals inside it. Covering,
      # in order: Leptos's conditional-class tuple `class=("md:ml-auto", flag)`,
      # `tw_merge!` calls, and the `clx!` component definitions leptos_ui
      # generates from.
      #
      # Note what is NOT here and cannot be: `class:md:ml-auto=flag`. That class
      # name is part of the attribute *name*, not a string literal, so there is
      # nothing for a regex to capture — the tuple form above is the spelling
      # that gets tooling support.
      tailwindCSS.experimental.classRegex = [
        [''class=\(([^)]*)\)'' ''"([^"]*)"'']
        [''tw_merge!\(([^)]*)\)'' ''"([^"]*)"'']
        [''clx!\s*\{([^}]*)\}'' ''"([^"]*)"'']
      ];
    };
  };
}
