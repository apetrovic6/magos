{
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
    statusline = {
      left = ["mode" "spinner" "file-name"];
      right = ["diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type"];
      separator = "│";
    };
  };
}
