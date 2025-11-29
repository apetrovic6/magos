{inputs, ...}: {
  flake.homeModules.waybar = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) types mkOption mkEnableOption;
    cfg = config.magos.hm.core.waybar;
  in {
    imports = [./settings.nix];

    options.magos.hm.core.waybar = {
      enable = mkEnableOption "Enable Waybar";
    };

    config = lib.mkIf cfg.enable {
      programs.waybar = {
        enable = cfg.enable;
        systemd = {
          enable = true;
          target = "hyprland-session.target";
        };

        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 15;
            modules-left = ["hyprland/workspaces" "cava"];
            modules-center = ["clock"];
            modules-right = ["pulseaudio" "network" "bluetooth" "battery" "hyprland/language"];

            "hyprland/workspaces" = {
              on-click = "activate";
              format = "{icon}";
              format-icons = {
                default = "";
                persistent = "";
                active = "";
              };
              persistent-workspaces = {
                "1" = [];
                "2" = [];
                "3" = [];
                "4" = [];
                "5" = [];
              };
            };

            "hyprland/language" = {
              "format" = "{short}";
            };

            clock = {
              format = "{:L%A %H:%M}";
              format-alt = "{:L%d %B W%V %Y}";
              tooltip = false;
            };

            network = {
              format-icons = ["󰤯" "󰤟" "󰤢" "󰤢" "󰤥" "󰤨"];
              format = "{icon}";
              format-wifi = "{icon}";
              format-ethernet = "󰀂";
              format-disconnected = "󰤮";
              tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
              tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
              tooltip-format-disconnected = "Disconnected";
              interval = 3;
              spacing = 1;
              on-click = "ghostty -e impala";
            };

            battery = {
              format = "{capacity}% {icon}";
              format-discharging = "{icon}";
              format-charging = "{icon}";
              format-plugged = "";
              format-icons = {
                charging = ["󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅"];
                default = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
              };

              format-full = "󰂅";
              tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
              tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
              interval = 5;
              on-click = "omarchy-menu power";
              states = {
                warning = 20;
                critical = 10;
              };
            };

            bluetooth = {
              format = "";
              format-disabled = "󰂲";
              format-connected = "";
              tooltip-format = "Devices connected: {num_connections}";
              on-click = "ghostty -e bluetui";
            };

            pulseaudio = {
              format = "{icon}";
              on-click = "xdg-terminal-exec --app-id=com.omarchy.Wiremix -e wiremix";
              on-click-right = "pamixer -t";
              tooltip-format = "Playing at {volume}%";
              scroll-step = 5;
              format-muted = " ";
              format-icons = {
                default = ["" "" ""];
              };
            };

            cava = {
              # cava_config = "$XDG_CONFIG_HOME/cava/cava.conf";
              framerate = 60;
              # autosens = 1;
              sensitivity = 50;
              bars = 10;
              lower_cutoff_freq = 50;
              higher_cutoff_freq = 10000;
              hide_on_silence = true;
              # format_silent = "quiet";
              sleep_timer = 5;
              method = "pulse";
              source = "auto";
              stereo = true;
              reverse = false;
              bar_delimiter = 0;
              monstercat = false;
              waves = true;
              noise_reduction = 1;
              input_delay = 2;
              format-icons = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
              actions = {
                on-click-right = "mode";
              };
            };
          };
        };

        style = let
          colors = config.lib.stylix.colors;
        in
          /*
          css
          */
          ''                     /* === Stylix Base16 → Material-ish roles ===========================
                        * surface        = base00
                        * surface-alt    = base01
                        * selection      = base02
                        * on-surface     = base05
                        * on-surface-alt = base04
                        * primary        = base0D
                        * warning        = base0A
                        * urgent         = base09
                        * error          = base08
                        * success        = base0B
                        * outline        = base03
                        * =============================================================== */

                       * {
                         border: none;
                         border-radius: 0;
                         font-family: "${config.stylix.fonts.monospace.name}", monospace;
                         font-size: ${toString (config.stylix.fonts.sizes.desktop - 5)}pt;
                         min-height: 0;
                       }

                       window#waybar {
                         background: transparent;          /* let compositor / bar bg show */
                         padding-top: 15px;
                         color: #${colors.base05};         /* on-surface */
                       }

                       /* ===== Pill containers for all modules ===== */

                       #workspaces,
                       #cava,
                       #clock,
                       #pulseaudio,
                       #pulseaudio-slider,
                       #network,
                       #bluetooth,
                       #battery,
                       #language {
                         padding: 3px 10px;
                         margin: 0px 10px;
                         background: #${colors.base01};        /* surface-alt */
                         border-radius: 999px;                 /* pill shape */
                         border: 1px solid #${colors.base03};  /* outline */

                         /* make inner content not drift with weird defaults */
                         /* these are GtkBox-like containers */
                       }

                       /* small tweak so leftmost pill doesnt hug the edge */
                       #workspaces {
                         margin-left: 10px;
                       }


            /* ===== Workspaces (hyprland/workspaces) ===== */

                       #workspaces button {
                         padding: 0 0;
                         margin: 2px 2px;
                         background: transparent;
                         color: #${colors.base05}; /* on-surface */
                         border-radius: 999px;
                       }

                       #workspaces button:hover {
                         color: #${colors.base02};  /* selection */
                       }

                       #workspaces button.active {
                       }

                       #workspaces button.urgent {
                         background: #${colors.base09};  /* urgent */
                         color: #${colors.base00};
                       }

                       /* ===== Pulseaudio icon ===== */

                       #pulseaudio {
                         padding: 3px 14px 3px 5px;
                       }

                       #network {
                          padding: 3px 12px 3px 9px;
                       }

                       /* ===== Battery states ===== */

                       #battery.charging,
                       #battery.plugged {
                         color: #${colors.base0B}; /* success */
                       }

                       #battery.warning {
                         color: #${colors.base0A}; /* warning */
                       }

                       #battery.critical {
                         color: #${colors.base08}; /* error */
                       }

                       /* ===== Network ===== */

                       #network.disconnected {
                         color: #${colors.base08}; /* error */
                       }

                       /* ===== Bluetooth ===== */

                       #bluetooth.disabled {
                         color: #${colors.base04}; /* softer on-surface-alt */
                       }

                       /* ===== Keyboard layout (hyprland/language) ===== */

                       #language {
                       }'';
      };
    };
  };
}
