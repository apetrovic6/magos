{pkgs}: let
  lib = pkgs.lib;
in {
  # Packages needed for keybind commands
  extraPackages = with pkgs; [
    lazygit
    yazi
  ];

  keys.normal = {
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
