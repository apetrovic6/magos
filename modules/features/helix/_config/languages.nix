{
  language = [
    {
      # .connect is our own extension for connect.hx; .http is the
      # vscode-restclient convention the format extends.
      name = "http";
      scope = "source.http";
      file-types = ["http" "connect"];
      comment-token = "#";
      injection-regex = "http";
      indent = {
        tab-width = 2;
        unit = "  ";
      };
    }
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
      # Replaces the lldb-dap block helix ships for rust. lldb-dap shows
      # String/Vec/Option as raw internals unless `initCommands` imports
      # rustc's lldb_lookup.py, and that path lives in a toolchain sysroot we
      # have no global copy of -- rustc comes from per-project dev shells, so
      # there is no one value to hardcode here. codelldb runs the lookup itself
      # against the workspace toolchain.
      debugger = {
        name = "codelldb";
        # codelldb speaks DAP over a socket, not stdio: helix picks a free port
        # and substitutes it into port-arg.
        transport = "tcp";
        command = "codelldb";
        port-arg = "--port {}";

        # Every template below sets terminal = "console", and must. Anything
        # else (including codelldb's default `integrated`) makes it issue a DAP
        # runInTerminal request, and helix cannot answer one during a launch: on
        # the `initialized` event it awaits configuration_done() inside the event
        # handler (helix-view/src/handlers/dap.rs:389), so its event loop is
        # blocked exactly when the reverse request arrives -- while codelldb
        # cannot answer configurationDone until launch finishes, which is what it
        # wants the terminal for. Nothing breaks the cycle until codelldb's
        # hardcoded 10s terminal timeout, and by then the terminal helix finally
        # spawns connects to a dropped listener and dies with
        # "Error: Os { code: 111, ConnectionRefused }". Confirmed from a helix
        # DAP log: request queued at T+0.0s, handled at T+10.1s.
        #
        # That is why editor.terminal in editor.nix is currently unused: it is
        # correct, but no request reaches it in time.
        templates = [
          {
            # First in the list because it is preselected in the picker, and it
            # is the one to reach for: a debuggee that draws (a TUI) or reads
            # stdin needs a real tty, and console mode gives it the adapter's
            # inherited fds, i.e. helix's own terminal -- it will draw over the
            # editor. This borrows a terminal you already have open, which is the
            # only way to get a tty given the deadlock described above.
            #
            # Usage: open a spare terminal (Super+Return) and run
            #   tty; sleep infinity
            # The `sleep` matters -- a shell sitting at its prompt would eat the
            # keystrokes meant for the debuggee. `tty` prints e.g. /dev/pts/7;
            # that is what the second prompt wants. ^C there when you are done.
            #
            # The redirect goes through LLDB's own settings, not codelldb's
            # `stdio` attribute: configure_stdio in codelldb (1.12.2 and master
            # alike) applies its file actions only inside
            # `if let Some(terminal) = &self.debuggee_terminal`, so with
            # terminal = "console" it silently ignores `stdio` and the debuggee
            # inherits the adapter's fds. preRunCommands run after codelldb
            # builds the launch info and it re-reads it afterwards, so LLDB's
            # target.{input,output,error}-path win.
            #
            # {1} is helix substituting the second completion answer
            # (map_value in helix-term/src/commands/dap.rs).
            name = "binary (tty)";
            request = "launch";
            completion = [
              {
                name = "binary";
                completion = "filename";
              }
              {
                # Shows as a `tty: ` prompt with an empty line -- helix does not
                # prefill `default`, it only substitutes it when you submit
                # nothing (debug_parameter_prompt in
                # helix-term/src/commands/dap.rs), so a default here would just
                # be a wrong answer waiting to be accepted. No completer either:
                # the completers are filename/directory only.
                name = "tty";
              }
            ];
            args = {
              program = "{0}";
              preRunCommands = [
                "settings set target.input-path {1}"
                "settings set target.output-path {1}"
                "settings set target.error-path {1}"
              ];
              sourceLanguages = ["rust"];
              initCommands = [
                ''script import os, sys, shutil, subprocess; _rc = shutil.which("rustc"); _sr = subprocess.run([_rc, "--print", "sysroot"], capture_output=True, text=True).stdout.strip() if _rc else ""; _etc = os.path.join(_sr, "lib/rustlib/etc") if _sr else ""; _lookup = os.path.join(_etc, "lldb_lookup.py") if _etc else ""; sys.path.insert(0, _etc) if _etc else None; lldb.debugger.HandleCommand("command script import " + _lookup) if _lookup and os.path.exists(_lookup) else None''
              ];
              terminal = "console";
            };
          }
          {
            name = "binary";
            request = "launch";
            completion = [
              {
                name = "binary";
                completion = "filename";
              }
            ];
            args = {
              program = "{0}";
              # What makes codelldb look for the toolchain's visualizers at all.
              sourceLanguages = ["rust"];
              # ...but its own lookup fails here ("Could not find LLDB data
              # formatters in your Rust toolchain"): it wants
              # $sysroot/lib/rustlib/etc/lldb_commands, and nixpkgs' rustc ships
              # the etc/ directory without that file. codelldb 1.12.3 imports
              # the visualizer anyway (vadimcn/codelldb#1395); nixpkgs is on
              # 1.12.2, so do the import by hand.
              #
              # lldb_lookup.py self-registers the whole Rust category from
              # __lldb_init_module, so importing it is enough -- lldb_commands
              # would add nothing. The sysroot is resolved at session start
              # rather than baked in, because rustc comes from whichever dev
              # shell helix was launched in. No rustc on PATH means no import
              # and raw internals in the variables popup, not a failed launch.
              #
              # Verified: without this s: String reads `{...}`, with it `"hello"`.
              initCommands = [
                ''script import os, sys, shutil, subprocess; _rc = shutil.which("rustc"); _sr = subprocess.run([_rc, "--print", "sysroot"], capture_output=True, text=True).stdout.strip() if _rc else ""; _etc = os.path.join(_sr, "lib/rustlib/etc") if _sr else ""; _lookup = os.path.join(_etc, "lldb_lookup.py") if _etc else ""; sys.path.insert(0, _etc) if _etc else None; lldb.debugger.HandleCommand("command script import " + _lookup) if _lookup and os.path.exists(_lookup) else None''
              ];
              # Mandatory; see the comment above `templates`. Note what console
              # mode does NOT do here: it does not capture the debuggee's output.
              # codelldb only installs file actions when it has a terminal, so
              # the debuggee inherits the adapter's fds -- which are helix's --
              # and anything it prints lands on top of the editor. Use this only
              # for a binary you know stays quiet; otherwise take "binary (tty)".
              terminal = "console";
            };
          }
        ];
      };
    }
    {
      # Helix already ships a `scheme` language (tree-sitter grammar, file-types
      # ss/scm/sld) but attaches no language server to it. The .scm files in this
      # repo are Steel, so point it at Steel's server.
      name = "scheme";
      language-servers = ["steel-language-server"];
    }
    {
      # No `grammar`: Helix 25.07 ships no Cedar tree-sitter grammar, so this
      # buys file-type detection and the language server, not highlighting.
      # Cedar files render as plain text with LSP diagnostics over them.
      name = "cedar";
      scope = "source.cedar";
      # `.cedarschema` too: the schema is what makes the server's validation
      # worth having, and it speaks both.
      file-types = ["cedar" "cedarschema"];
      language-servers = ["cedar-language-server"];
      # `//`, not `#` — from Cedar's own lexer:
      #     r"//[^\n\r]*[\n\r]*" => { },  // Skip `// comments`
      # A `#` would insert something its parser rejects.
      comment-token = "//";
      indent = {
        tab-width = 2;
        unit = "  ";
      };
    }
    {
      # Injection-only: reached from the `view!` rule in
      # _config/queries/rust/injections.scm, never by filename. `.rs` stays the
      # `rust` language, with rust-analyzer and the stock Rust grammar intact --
      # this grammar could not stand in for it anyway, its root rule is
      # `choice($.delim_nodes, repeat1($._node_except_block))`, i.e. markup only.
      #
      # `injection-regex` is what `(#set! injection.language "rstml")` actually
      # matches on; the `name` is not consulted.
      name = "rstml";
      scope = "source.rstml";
      file-types = [];
      injection-regex = "rstml";
      grammar = "rstml";
      indent = {
        tab-width = 4;
        unit = "    ";
      };
    }
  ];

  # No args: the server speaks LSP over plain stdio. It has no configurable
  # options either -- its only knob is STEEL_LSP_HOME, which overrides the
  # $STEEL_HOME/lsp directory it reads helix's generated builtin stubs from.
  language-server.steel-language-server.command = "steel-language-server";

  # Plain stdio, no args — verified by handing it an LSP `initialize` and
  # getting a correctly framed reply.
  #
  # A bare command name rather than `${pkgs.cedar}/bin/...` on purpose. The
  # wrapper appends its own tools to PATH (`wrapperSuffixEnv PATH`) and leaves
  # the inherited PATH ahead of them, so this resolves to whatever the current
  # project provides. `cedar` is therefore NOT in `runtimePkgs`: it lives in the
  # devenv of projects that use it, and Helix has to be launched from inside
  # that shell. Started from a plain terminal the server is simply not found —
  # Helix logs it to ~/.cache/helix/helix.log and opens the file anyway.
  language-server.cedar-language-server.command = "cedar-language-server";

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
      procMacro.ignored.leptos_macro = [];

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
