{pkgs}: let
  lib = pkgs.lib;
in {
  # Packages needed for keybind commands
  extraPackages = with pkgs; [
    lazygit
    yazi
  ];

  keys.normal = {
    # Hyphens, not underscores: the typable commands are buffer-close and
    # buffer-close!. `:buffer_close` is the STATIC command spelling and is not
    # a typable command at all -- and an unknown `:name` does not fail at
    # startup, because MappableCommand::from_str falls back to a placeholder
    # command. It looks bound, shows "Undocumented plugin command" in the
    # popup, and only errors when the key is pressed.
    #
    # Kept here rather than in a steel keymap: these are NATIVE commands, and
    # binding them from steel does not improve their description. The fork's
    # from_str builds a typable command's doc as `:name args` and
    # keymap-update-documentation! only finds docs for commands defined in
    # steel, so either way the row reads `:buffer-close` rather than "Close
    # the current buffer." (Verified: it does.)
    space.B = {
      c = ":buffer-close";
      C = ":buffer-close!";
    };
    C-o = [
      ":new"
      ":insert-output env XDG_CONFIG_HOME=$HOME/.config ${lib.getExe pkgs.lazygit}"
      ":buffer-close!"
      ":redraw"
    ];
    "C-y" = [
      ":sh rm -f /tmp/unique-file"
      ":insert-output ${lib.getExe pkgs.yazi} %{buffer_name} --chooser-file=/tmp/unique-file"
      ":insert-output echo \"\\x1b[?1049h\\x1b[?2004h\" > /dev/tty"
      ":open %sh{cat /tmp/unique-file}"
      ":redraw"
    ];
  };
}
