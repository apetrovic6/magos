# Every herdr keybinding, at its upstream default (`herdr --default-config`).
#
# Wired into `settings.keys` with `lib.mkDefault` applied per leaf, so a single
# binding can be overridden downstream without `lib.mkForce`:
#
#   self.packages.x86_64-linux.herdr.wrap { settings.keys.detach = "prefix+d"; }
#
# An empty string means "unbound" -- herdr parses "" as no binding, which is
# how the optional actions below ship.
#
# Syntax: "prefix+n" requires the prefix key first; "ctrl+alt+n" is a direct
# terminal-mode chord. ctrl+letter, function keys, and explicit modified chords
# are the most reliable; alt+..., cmd/super, and punctuation-with-modifiers
# depend on the host terminal.
{
  # Prefix key to enter prefix mode.
  prefix = "ctrl+b";

  # Session
  help = "prefix+?";
  settings = "prefix+s";
  detach = "prefix+q";
  reload_config = "prefix+shift+r";
  open_notification_target = "prefix+o";
  toggle_sidebar = "prefix+b";

  # Workspaces
  workspace_picker = "prefix+w";
  goto = "prefix+g";
  new_workspace = "prefix+shift+n";
  rename_workspace = "prefix+shift+w";
  close_workspace = "prefix+shift+d";
  previous_workspace = "prefix+shift+up";
  next_workspace = "prefix+shift+down";
  switch_workspace = "prefix+shift+1..9"; # indexed, e.g. "prefix+shift+1..9"

  # Worktrees
  new_worktree = "prefix+shift+g";
  open_worktree = "";
  remove_worktree = ""; # opens a confirmation

  # Agents
  previous_agent = "";
  next_agent = "";
  focus_agent = ""; # indexed, e.g. "prefix+alt+1..9"

  # Tabs
  new_tab = "prefix+c";
  rename_tab = "prefix+shift+t";
  previous_tab = "prefix+p";
  next_tab = "prefix+n";
  move_tab_previous = ""; # e.g. "alt+shift+left"
  move_tab_next = ""; # e.g. "alt+shift+right"
  switch_tab = "prefix+1..9";
  close_tab = "prefix+shift+x";

  # Panes
  rename_pane = "prefix+shift+p";
  edit_scrollback = "prefix+e";
  focus_pane_left = "prefix+h";
  focus_pane_down = "prefix+j";
  focus_pane_up = "prefix+k";
  focus_pane_right = "prefix+l";
  cycle_pane_next = "prefix+tab";
  cycle_pane_previous = "prefix+shift+tab";
  last_pane = ""; # e.g. "prefix+tab" for global back-and-forth
  split_vertical = "prefix+v";
  split_horizontal = "prefix+minus";
  close_pane = "prefix+x";
  zoom = "prefix+z";
  resize_mode = "prefix+r";
  resize_pane_left = ""; # e.g. "ctrl+shift+alt+left", resizes without entering resize mode
  resize_pane_down = "";
  resize_pane_up = "";
  resize_pane_right = "";

  # Navigate-mode movement. Local shortcuts that win while navigate mode is
  # open, independent of focus_pane_*. Never include prefix+, esc, enter, tab,
  # or 1..9 here.
  navigate_workspace_up = "up";
  navigate_workspace_down = "down";
  navigate_pane_left = "h";
  navigate_pane_down = "j";
  navigate_pane_up = "k";
  navigate_pane_right = "l";

  # Only active under `herdr --remote`; empty disables raw-key image paste.
  remote_image_paste = "ctrl+v";
  # Custom commands, emitted as TOML [[keys.command]] entries. `type` is one of
  # "shell" (detached, background), "pane" (temporary pane, closed on exit), or
  # "popup" (session-modal terminal, leaves the tab layout alone). Popup width
  # and height take terminal cells or percentages.
  #
  # This is a list, so overriding it downstream replaces it wholesale.
  #
  # command = [
  #   {
  #     key = "prefix+alt+g";
  #     type = "popup";
  #     command = "lazygit";
  #     width = "80%";
  #     height = "80%";
  #   }
  # ];
  #
  # `[keys.indexed]` (tabs/workspaces/agents) is also still parsed, but upstream
  # deprecates it in favour of switch_tab, switch_workspace, and focus_agent, so
  # it is deliberately not part of this skeleton.
}
