{inputs, ...}: {
  flake.homeModules.waybar = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) types mkOption mkEnableOption;
    transition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
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
            modules-left = ["custom/button" "hyprland/workspaces"];
            modules-center = ["clock"];
            modules-right = ["pulseaudio" "network" "bluetooth" "battery" "custom/notification" "hyprland/language"];

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

            "custom/button" = {
              format = "";
              tooltip = false;
            };

            "custom/notification" = {
              "tooltip" = true;
              "format" = "<span size='${toString config.stylix.fonts.sizes.desktop}pt'>{0} {icon}</span>";
              "format-icons" = {
                "notification" = "󱅫";
                "none" = "󰂜";
                "dnd-notification" = "󰂠";
                "dnd-none" = "󰪓";
                "inhibited-notification" = "󰂛";
                "inhibited-none" = "󰪑";
                "dnd-inhibited-notification" = "󰂛";
                "dnd-inhibited-none" = "󰪑";
              };
              "return-type" = "json";
              "exec-if" = "which swaync-client";
              "exec" = "swaync-client -swb";
              "on-click" = "swaync-client -t -sw";
              "on-click-right" = "swaync-client -d -sw";
              "escape" = true;
            };

            "hyprland/language" = {
              "format" = "{short}";
            };

            clock = {
              format = "{:%H:%M}";
              format-alt = "{:L%d %B W%V %Y}";
              tooltip = false;
            };

            network = {
              format-icons = ["󰤯" "󰤟" "󰤢" "󰤢" "󰤥" "󰤨"];
              format = "{icon}";
              format-wifi = "{essid}{icon}";
              format-ethernet = "󰀂  Wired";
              format-disconnected = "󰤮";
              tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
              tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
              tooltip-format-disconnected = "Disconnected";
              interval = 3;
              spacing = 1;
              on-click = "ghostty --class=ghostty.wiremix  -e ${lib.getExe pkgs.impala}";
            };

            battery = {
              format = "{capacity}% {icon}";
              format-discharging = "{icon} {capacity}%";
              format-charging = "{icon}";
              format-plugged = " {time}";
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
              format = " {status}";
              format-disabled = "󰂲";
              format-connected = "";
              tooltip-format = "Devices connected: {num_connections}";
              on-click = "ghostty --class=ghostty.wiremix -e ${lib.getExe pkgs.bluetui}";
            };

            pulseaudio = {
              format = "{volume}% {icon}";
              on-click = "ghostty --class=ghostty.wiremix -e ${lib.getExe pkgs.wiremix}";
              on-click-right = "pamixer -t";
              tooltip-format = "Playing at {volume}%";
              scroll-step = 5;
              format-muted = " ";
              format-icons = {
                default = [" "];
              };
            };

            cava = {
              # cava_config = "$XDG_CONFIG_HOME/cava/cava.conf";
              framerate = 60;
              # autosens = 1;
              sensitivity = 30;
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
                         font-family: ${config.stylix.fonts.monospace.name};
                         font-size: ${toString (config.stylix.fonts.sizes.desktop - 5)}pt;
                         min-height: 0;
                       }

                       window#waybar {
                         background: transparent;          /* let compositor / bar bg show */
                         padding-top: 15px;
                         color: #${colors.base05};         /* on-surface */
                       }

                       /* ===== Pill containers for all modules ===== */

                       #custom-button {
                         margin: 0px 15px;
                         margin-top: 5px;
                         padding-top: 3px;
                         padding-bottom: 3px;
                         padding-left: 10px;
                         padding-right: 15px;

                         background: alpha(#${colors.base01}, 0.2);        /* surface-alt */
                         border-radius: 999px;                 /* pill shape */
                       }

                       #workspaces,
                       #cava,
                       #clock,
                       #pulseaudio,
                       #network,
                       #bluetooth,
                       #tooltip,
                       #custom-notification,
                       #battery,
                       #language {
                         padding: 3px 10px;
                         margin: 0px 15px;
                         transition: ${transition};
                         margin-top: 5px;
                         background: alpha(#${colors.base01}, 0.2);        /* surface-alt */
                         border-radius: 999px;                 /* pill shape */
                       /*  border: 1px solid #${colors.base03}; */  /* outline */

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
                         transition: ${transition};
                       }

                       #workspaces button.urgent {
                         background: #${colors.base09};  /* urgent */
                         color: #${colors.base00};
                       }

                       /* ===== Pulseaudio icon ===== */

                       #pulseaudio {
                          padding: 0px 8px;
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
                       }


                       #tooltip {
                         border: 1px solid #${colors.base03};
                       }
          '';
      };
    };
  };
}
