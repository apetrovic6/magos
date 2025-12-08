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
          default = 0.6;
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

          # base16Scheme = {
          #
          # Everforest dark
          #   base00 = "2b3339"; # Default Background
          #   base01 = "323c41"; # Lighter Background (Used for status bars, line number and folding marks)
          #   base02 = "503946"; # Selection Background
          #   base03 = "868d80"; # Comments, Invisibles, Line Highlighting
          #   base04 = "d3c6aa"; # Dark Foreground (Used for status bars)
          #   base05 = "d3c6aa"; # Default Foreground, Caret, Delimiters, Operators
          #   base06 = "e9e8d2"; # Light Foreground (Not often used)
          #   base07 = "fff9e8"; # Light Background (Not often used)
          #   base08 = "7fbbb3"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
          #   base09 = "d699b6"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
          #   base0A = "83c092"; # Classes, Markup Bold, Search Text Background
          #   base0B = "dbbc7f"; # Strings, Inherited Class, Markup Code, Diff Inserted
          #   base0C = "e69875"; # Support, Regular Expressions, Escape Characters, Markup Quotes
          #   base0D = "a7c080"; # Functions, Methods, Attribute IDs, Headings
          #   base0E = "e67e80"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
          #   base0F = "d699b6"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>

          # Catppuccin frappe
          #   base00 = "303446"; # base
          #   base01 = "292c3c"; # mantle
          #   base02 = "414559"; # surface0
          #   base03 = "51576d"; # surface1
          #   base04 = "626880"; # surface2
          #   base05 = "c6d0f5"; # text
          #   base06 = "f2d5cf"; # rosewater
          #   base07 = "babbf1"; # lavender
          #   base08 = "e78284"; # red
          #   base09 = "ef9f76"; # peach
          #   base0A = "e5c890"; # yellow
          #   base0B = "a6d189"; # green
          #   base0C = "81c8be"; # teal
          #   base0D = "8caaee"; # blue
          #   base0E = "ca9ee6"; # mauve
          #   base0F = "eebebe"; # flamingo
          # };

          polarity = cfg.polarity;

          # base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";

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
