{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;

  # Use Stylix if present; otherwise a sane base16 fallback.
  c =
    config.lib.stylix.colors or {
      base00 = "1d1f21";
      base01 = "282a2e";
      base02 = "373b41";
      base03 = "969896";
      base04 = "b4b7b4";
      base05 = "c5c8c6";
      base06 = "e0e0e0";
      base07 = "ffffff";
      base08 = "cc6666";
      base09 = "de935f";
      base0A = "f0c674";
      base0B = "b5bd68";
      base0C = "8abeb7";
      base0D = "81a2be";
      base0E = "b294bb";
      base0F = "a3685a";
    };

  values = {
    backgroundDefault = "#${c.base00}";
    backgroundAlpha50 = "alpha(#${c.base01}, 0.5)";
    background = "#${c.base01}";
    foreground = "#${c.base05}";
    textDefault = "#${c.base05}";
    textAlternate = "#${c.base04}";
    textPopup = "#${c.base0A}";
    border = "#${c.base0D}";
    warning = "#${c.base0A}";
    urgent = "#${c.base09}";
    error = "#${c.base08}";
  };
in {
  options.magos.palette = mkOption {
    type = types.attrsOf types.str;
    readOnly = true;
    description = "Read-only palette derived from Stylix (or fallback).";
  };

  # Set the value (users can't override because the option is readOnly).
  config.magos.palette = values;
}
