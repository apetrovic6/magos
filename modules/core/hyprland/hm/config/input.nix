{...}: {
  flake.homeModules.hyprland-input = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkOption types;
  in {
    options.magos.hyprland.input = {
      kbLayouts = mkOption {
        type = types.listOf types.str;
        default = ["us"];
        example = "[ \"us\" \"es\" ]";
        description = "A list of keyboard layouts that will be used";
      };

      kbVariants = mkOption {
        # Optional: parallel list of variants, or [] to omit
        type = types.listOf types.str;
        default = [];
        description = "Optional variants list matching kbLayouts length.";
      };

      kbOptions = mkOption {
        type = types.str;
        default = "grp:alt_shift_toggle";
        description = "XKB options (comma-separated).";
      };
    };

    config = {
      wayland.windowManager.hyprland.settings = {
        input = {
          kb_layout = lib.concatStringsSep "," config.magos.hyprland.input.kbLayouts;

          kb_variant =
            lib.optionalString
            (config.magos.hyprland.input.kbVariants != [])
            (lib.concatStringsSep "," config.magos.hyprland.input.kbVariants);

          kb_model = "";
          kb_options = config.magos.hyprland.input.kbOptions;
          kb_rules = "";

          follow_mouse = 1;
          sensitivity = 0;

          touchpad.natural_scroll = false;
        };

        cursor = {
          hide_on_key_press = true;
          no_warps = true;
          hide_on_touch = true;
        };
      };
    };
  };
}
