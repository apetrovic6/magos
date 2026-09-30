{
  lib,
  # The terminal a debug adapter's runInTerminal request is spawned in. Taken as
  # an argument rather than named on PATH because `foot` is not on PATH here --
  # the configuration installs a wrapped build of it (see modules/features/foot.nix),
  # which is also what niri spawns.
  terminalPkg,
}: {
  editor = {
    bufferline = "multiple";
    color-modes = true;
    auto-pairs = false;

    # Offer completions after one character rather than two, and without the
    # 250ms settle — 5 is the value Helix's own docs give for "instant".
    #
    # This is the reachable half of getting `<Rout` to suggest `<Router>`.
    # The rest is not a setting: inside a `view!` rust-analyzer is working on a
    # proc-macro token stream rather than Rust syntax, so what it offers there
    # is limited however eagerly it is asked. Closing the tag on accept is not
    # possible at all — helix#966 has been open since 2021, `auto-pairs` only
    # handles single characters, and 25.07 ships no plugin system.
    completion-trigger-len = 1;
    completion-timeout = 5;
    line-number = "relative";
    mouse = true;
    inline-diagnostics = {cursor-line = "hint";};
    cursorline = true;
    cursor-shape = {
      insert = "bar";
      normal = "block";
      select = "underline";
    };
    # NOTE: currently unreachable, kept because it is correct and one helix fix
    # away from working. Helix deadlocks its own event loop during a launch, so
    # a runInTerminal request is only handled ~10s late, after the adapter has
    # given up on it -- see the comment above `templates` in languages.nix, where
    # every rust template therefore sets terminal = "console".
    #
    # Where a debug adapter's runInTerminal request is sent. Helix only
    # autodetects tmux ($TMUX) and wezterm ($WEZTERM_UNIX_SOCKET); under foot it
    # finds nothing and reports "No external terminal defined", which is enough
    # to fail every codelldb launch -- codelldb asks for a terminal even on its
    # default `integrated` setting.
    #
    # Helix spawns `command args... <debuggee cmdline>`, and the two helix
    # versions in play disagree on the shape of that last part:
    #
    #   upstream 25.07.1  .arg(arguments.args.join(" "))  -> one shell string
    #   steel fork 09d67df .args(&arguments.args)         -> separate argv
    #
    # We run the fork, so the second one is live. foot execs argv directly and
    # cannot interpret a shell string either way, hence the `sh -c` hop, and the
    # script handles both: `sh -c SCRIPT A B C` binds A to $0 and leaves B C in
    # $@, so a non-empty $@ means the argv form (exec it as-is) and an empty one
    # means the joined form (eval $0 to re-split it). Getting this wrong is not
    # subtle -- eval'ing only $0 under the fork drops codelldb's
    # `--connect=<addr>` and its launcher exits with "Need an address to connect
    # to."
    #
    # The `read` is what keeps the window up: the adapter's terminal agent exits
    # with the debuggee, and without the pause foot closes over the last line of
    # output.
    terminal = {
      command = lib.getExe terminalPkg;
      args = [
        "sh"
        "-c"
        ''if [ "$#" -gt 0 ]; then "$0" "$@"; else eval "$0"; fi; printf '\n-- debuggee exited, press enter --'; read -r _''
      ];
    };

    statusline = {
      left = ["mode" "spinner" "file-name"];
      right = ["diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type"];
      separator = "│";
    };
  };
}
