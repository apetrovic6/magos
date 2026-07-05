{
  editor = {
    bufferline = "multiple";
    color-modes = true;
    auto-pairs = false;
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
