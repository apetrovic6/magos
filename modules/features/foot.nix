{
  self,
  inputs,
  ...
}:
let
  defaultTheme = self.lib.colors.everforest-dark-soft;

  makeFootPackage =
    {
      pkgs,
      colors,
    }:
    inputs.wrapper-modules.wrappers.foot.wrap {
      inherit pkgs;
      settings = {
        main = {
          initial-color-theme = "dark";
          pad = "8x8";
        };
        cursor = {
          style = "beam";
          blink = "no";
        };
        mouse = {
          hide-when-typing = "yes";
          alternate-scroll-mode = "yes";
        };
        colors-dark = {
          alpha = 0.8;
          foreground = colors.base05;
          background = colors.base00;
          regular0 = colors.base00;
          regular1 = colors.base08;
          regular2 = colors.base0B;
          regular3 = colors.base0A;
          regular4 = colors.base0D;
          regular5 = colors.base0E;
          regular6 = colors.base0C;
          regular7 = colors.base05;
          bright0 = colors.base03;
          bright1 = colors.base08;
          bright2 = colors.base0B;
          bright3 = colors.base0A;
          bright4 = colors.base0D;
          bright5 = colors.base0E;
          bright6 = colors.base0C;
          bright7 = colors.base07;
          "16" = colors.base09;
          "17" = colors.base0F;
          "18" = colors.base01;
          "19" = colors.base02;
          "20" = colors.base04;
          "21" = colors.base06;
        };
      };
    };
in
{
  flake.nixosModules.foot =
    {
      pkgs,
      config,
      ...
    }:
    let
      colors = config.lib.stylix.colors or defaultTheme;
    in
    {
      programs.foot = {
        enable = true;
        package = makeFootPackage { inherit pkgs colors; };
        enableBashIntegration = true;
        enableZshIntegration = true;
        xdg.serverAutostart = true;
      };
    };

  # foot is Wayland-only: nixpkgs refuses it on darwin, and flake-parts checks every
  # `packages` entry, so an unconditional one breaks evaluation of every darwin consumer of
  # this flake's packages (genetor pulls helix and herdr from here).
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        foot = makeFootPackage {
          inherit pkgs;
          colors = defaultTheme;
        };
      };
    };
}
