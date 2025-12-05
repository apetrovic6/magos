{inputs, ...}: {
  # Export a Home-Manager module
  flake.homeModules.stylix = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) mkIf mkOption mkEnableOption types optionalAttrs;
    cfg = config.magos.hm.stylix;
  in {
    options.magos.hm.stylix = {
      enable = mkEnableOption "Enable Stylix for this Home profile";

      image = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional wallpaper path for Stylix.";
      };

      polarity = mkOption {
        type = types.enum ["light" "dark"];
        default = "dark";
        description = "Theme polarity.";
      };

      targets.firefox.profileNames = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of profile names to apply stylest to. Works with Firefox and it's supported forks.";
      };

      opacity = {
        terminal = lib.mkOption {
          type = lib.types.float;
          default = 0.75;
          description = "Opacity of the terminal (0.0–1.0).";
        };
        desktop = lib.mkOption {
          type = lib.types.float;
          default = 0.5;
          description = "Opacity of the desktop (0.0–1.0).";
        };
        popups = lib.mkOption {
          type = lib.types.float;
          default = 0.5;
          description = "Opacity of popups (0.0–1.0).";
        };
        applications = lib.mkOption {
          type = lib.types.float;
          default = 0.8;
          description = "Opacity of applications (0.0–1.0).";
        };
      };
      # optional safety: ensure values are in [0,1]
      assertions = [
        {
          assertion = cfg.opacity.terminal >= 0.0 && cfg.opacity.terminal <= 1.0;
          message = "magos.stylix.opacity.terminal must be between 0 and 1.";
        }
        {
          assertion = cfg.opacity.desktop >= 0.0 && cfg.opacity.desktop <= 1.0;
          message = "magos.stylix.opacity.desktop must be between 0 and 1.";
        }
        {
          assertion = cfg.opacity.popups >= 0.0 && cfg.opacity.popups <= 1.0;
          message = "magos.stylix.opacity.popups must be between 0 and 1.";
        }
        {
          assertion = cfg.opacity.applications >= 0.0 && cfg.opacity.applications <= 1.0;
          message = "magos.stylix.opacity.applications must be between 0 and 1.";
        }
      ];
    };

    config = mkIf cfg.enable {
      stylix =
        {
          enable = true;
          autoEnable = true;

          polarity = cfg.polarity;

          opacity = cfg.opacity;

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
            ghostty.enable = true;

            helix.enable = true;

            gtk = {
              enable = true;
              flatpakSupport.enable = true;
            };

            zellij.enable = true;
            tmux.enable = true;

            lazygit.enable = true;
            vim.enable = true;
            qt.enable = true;
            qutebrowser.enable = true;
            starship.enable = true;
            swaync.enable = false;
            zathura.enable = true;
            obsidian.enable = true;
            fzf.enable = true;

            nvf = {
              enable = true;
            };
            neovim = {
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
              # font = "monospace";
              addCss = false;
            };
          };
        }
        // optionalAttrs (cfg.image != null) {image = cfg.image;};
    };
  };
}
