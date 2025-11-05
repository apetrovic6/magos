{ inputs, ... }:{
flake.homeModules.stylix = {config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkEnableOption;
  cfg = config.magos.hm.core.stylix;
   c = config.lib.stylix.colors;
in
{
options.magos.hm.core.stylix.palette = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    readOnly = true;
    default = {
      backgroundDefault = "#${c.base00}";
      backgroundAlpha50 = "alpha(#${c.base01}, 0.5)";
      background        = "#${c.base01}";
      foreground        = "#${c.base05}";

      textDefault    = "#${c.base05}";
      textAlternate  = "#${c.base04}";
      textPopup      = "#${c.base0A}";

      border = "#${c.base0D}";

      warning = "#${c.base0A}";
      urgent = "#${c.base09}";
      error = "#${c.base08}";
    };
    description = "Hyperium DE palette derived from Stylix.";
  };


  options.magos.hm.core.stylix = {
      enable = mkEnableOption "Enable and setup stylix";

      image = mkOption {
      type = types.path;
      description = "Path to the wallpaper image to use.";
    };


    polarity = mkOption {
      type = types.enum [ "light" "dark" ];
      default = "dark";
      description = "Polarity of the theme.";
    };
  };

    config = lib.mkIf cfg.enable {
  

        stylix = {
          enable = true;
    autoEnable = true;
    image = cfg.image;
    polarity = cfg.polarity;

    opacity = {
      terminal = 0.8;
      desktop = 0.5;
      popups = 0.5;
      applications = 0.5;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "jetbrains-mono";
      };

      sizes = {
        applications = 10;
        terminal = 10;
        desktop = 10;
        popups = 10;
      };
    };

    targets = {
      hyprpanel.enable = true;

      gtk = {
        enable = true;
        flatpakSupport.enable = true;
      };

      zellij.enable = true;
      tmux.enable = true;

    ghostty = {
      enable = true;
    };

    yazi.enable = true;
    bat.enable = true;
    cava.enable = true;
    btop.enable = true;
    vesktop.enable = true;  
    lazygit.enable = true;
    vim.enable = true;
    qt.enable = true;
    qutebrowser.enable = true;
    starship.enable = true;
    swaync.enable = true;
    zathura.enable = true;
    obsidian.enable = true;
    fzf.enable = true;


    nvf = {
        enable = true;
      };

    hyprland = {
      enable = true;
    };

    hyprlock = {
      enable = true;
      useWallpaper = false;
    };

      firefox = {
        enable = true;
        colorTheme.enable = true;
        profileNames = [ "apetrovic" ];
      };

      librewolf = {
        enable = true;
        colorTheme.enable = true;
        profileNames = [ "apetrovic" ];
      };


    waybar = {
      enable = true;
      font = "monospace";
      addCss = false;
    };
    };

    };
  };
};
}
