{
  pkgs,
  terminalPkg,
}: let
  lib = pkgs.lib;
  debug = import ./debug-launch.nix {inherit pkgs terminalPkg;};
in {
  # Packages needed for keybind commands
  extraPackages = with pkgs; [
    lazygit
    yazi
  ];

  keys.normal = {
    space.B = {
      c = ":buffer-close";
      C = ":buffer-close!";
    };
    # vista (in-buffer markdown rendering; on by default, see init.scm).
    # Bound here rather than from
    # init.scm: same effect, and this file is where the rest of the keybinds
    # live. The cost is that which-key shows "Undocumented command" for them
    # instead of the plugin's own @doc text.
    space.m = {
      m = ":vista-toggle";
      r = ":vista-render";
    };
    # Added into helix's own sticky debug submenu (space G), which keeps its
    # built-in keys -- keymap nodes merge rather than replace. `l` there is the
    # stock launcher that prompts for every parameter; this is the no-prompt
    # version: the binary comes from whichever buffer you are in, the tty from a
    # debug console window that is opened once and reused.
    #
    # One command, not a list: in a command *sequence* `:debug-start` runs
    # without error and without effect (the same command bound on its own, or
    # typed, works -- measured both ways), so the whole launch has to fit in a
    # single binding.
    #
    # `%{buffer_name}` nests inside `%sh{...}` because the parser consumes it as
    # one expansion token. A literal brace does not nest: a `${VAR:-x}` in there
    # ends the `%sh{` at its own `}` and silently truncates the command, which is
    # why neither script takes a path argument from here.
    space.G.d = ":debug-start \"binary (tty)\" %sh{${lib.getExe debug.resolveBinary} %{buffer_name}} %sh{${lib.getExe debug.ensureConsole}}";
    # inline-values.hx: toggle debugger values drawn inline while stopped
    # (fn add(x: f32 = 5, ...)). On by default; this is for getting the raw
    # source back or re-enabling after :inline-values-disable. Uppercase V
    # because the submenu's v is the built-in dap_variables picker, which
    # stays useful exactly while this plugin renders. Bound in nix like the
    # vista toggles, so which-key shows "Undocumented command" rather than
    # the plugin's @doc.
    space.G.V = ":inline-values-toggle";
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
