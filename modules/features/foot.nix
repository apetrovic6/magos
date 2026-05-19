{
  self,
  inputs,
  ...
}: let
  c = self.lib.colors.everforest-dark-soft;
in {
  flake.nixosModules.foot = {pkgs, ...}: {
    programs.foot = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.foot;
      enableBashIntegration = true;
      enableZshIntegration = true;
      xdg.serverAutostart = true;
      settings = {
        cursor = {
          style = "beam";
          blink = "no";
        };
        mouse = {
          hide-when-typing = "yes";
          alternate-scroll-mode = "yes";
        };
      };
    };
  };

  perSystem = {pkgs, ...}: {
    packages.foot = inputs.wrapper-modules.wrappers.foot.wrap {
      inherit pkgs;

      settings = {
        main.initial-color-theme = "dark";
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
          foreground = c.base05;
          background = c.base00;
          regular0 = c.base00;
          regular1 = c.base08;
          regular2 = c.base0B;
          regular3 = c.base0A;
          regular4 = c.base0D;
          regular5 = c.base0E;
          regular6 = c.base0C;
          regular7 = c.base05;
          bright0 = c.base03;
          bright1 = c.base08;
          bright2 = c.base0B;
          bright3 = c.base0A;
          bright4 = c.base0D;
          bright5 = c.base0E;
          bright6 = c.base0C;
          bright7 = c.base07;
          "16" = c.base09;
          "17" = c.base0F;
          "18" = c.base01;
          "19" = c.base02;
          "20" = c.base04;
          "21" = c.base06;
        };
      };
    };
  };
}
