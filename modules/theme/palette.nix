
# modules/theme/palette-home.nix
{ ... }:
{
  flake.homeManagerModules.palette = { lib, config, ... }:
  let
    has = lib.hasAttrByPath [ "lib" "stylix" "colors" ] config;
    c = if has then config.lib.stylix.colors else {};
  in
  {
    options.magos.theme.palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = {};  # always exists; populated only when Stylix colors are present
      description = "Theme palette derived from Stylix (HM scope).";
    };

    config = lib.mkIf has {
      magos.theme.palette = {
        backgroundDefault = "#${c.base00}";
        backgroundAlpha50 = "alpha(#${c.base01}, 0.5)";
        background        = "#${c.base01}";
        foreground        = "#${c.base05}";
        textDefault       = "#${c.base05}";
        textAlternate     = "#${c.base04}";
        textPopup         = "#${c.base0A}";
        border            = "#${c.base0D}";
        warning           = "#${c.base0A}";
        urgent            = "#${c.base09}";
        error             = "#${c.base08}";
      };
    };
  };
}

