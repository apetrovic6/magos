
{ inputs, ... }:
{
  # Export a Home-Manager module
  flake.homeManagerModules.stylix = { lib, config, pkgs, ... }:
  let
    inherit (lib) mkIf mkOption mkEnableOption types optionalAttrs;
    cfg = config.magos.hm.stylix;
  in
  {
    options.magos.hm.stylix = {
      enable = mkEnableOption "Enable Stylix for this Home profile";

      image = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional wallpaper path for Stylix.";
      };

      polarity = mkOption {
        type = types.enum [ "light" "dark" ];
        default = "dark";
        description = "Theme polarity.";
      };

        targets.firefox.profileNames = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "List of profile names to apply stylest to. Works with Firefox and it's supported forks.";
        };

      # opacity.terminal = {
      #   type = types.float;
      #   default = 0.5;
      #   description = "Opacity of the terminal";
      #   };
    };

    config = mkIf cfg.enable {
      stylix = {
        enable   = true;
        autoEnable = true;
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
        profileNames = cfg.targets.firefox.profileNames;
      };

      librewolf = {
        enable = true;
        colorTheme.enable = true;
        profileNames = cfg.targets.firefox.profileNames;
      };


    waybar = {
      enable = true;
      font = "monospace";
      addCss = false;
    };
    };



      } // optionalAttrs (cfg.image != null) { image = cfg.image; };
    };
  };
}

