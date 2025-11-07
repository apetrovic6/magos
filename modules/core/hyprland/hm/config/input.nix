{...}: {
  flake.homeModules.hyprland-input = {
    config,
    lib,
    ...
  }: {
    # https://wiki.hyprland.org/Configuring/Variables/#input
    wayland.windowManager.hyprland.settings = {
      input = {
        kb_layout = "us,hr";
        kb_variant = "";
        kb_model = "";
        kb_options = "grp:alt_shift_toggle"; # Alt+Shift cycles layouts
        kb_rules = "";

        follow_mouse = 1;

        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

        touchpad = {natural_scroll = false;};
      };

      cursor = {
        hide_on_key_press = true;
        no_warps = true;
        hide_on_touch = true;
      };
    };
  };
}
