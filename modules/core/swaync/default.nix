{inputs, ...}: {
  flake.homeModules.swaync = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) types mkOption mkEnableOption;
    cfg = config.magos.hm.core.swaync;
  in {
    imports = [];

    options.magos.hm.core.swaync = {
      enable = mkEnableOption "Enable SwayNC";
    };

    config = lib.mkIf cfg.enable {
      services.swaync = {
        enable = true;
        settings = {
          positionX = "right";
          positionY = "top";
          layer = "overlay";
          "control-center-layer" = "top";
          "layer-shell" = true;
          cssPriority = "application";

          "control-center-width" = 320;
          "control-center-margin-top" = 0;
          "control-center-margin-bottom" = 0;
          "control-center-margin-right" = 10;
          "control-center-margin-left" = 0;

          "notification-2fa-action" = true;
          "notification-inline-replies" = false;
          "notification-window-width" = 380;
          "notification-icon-size" = 48;
          "notification-body-image-height" = 240;
          "notification-body-image-width" = 240;

          timeout = 8;
          "timeout-low" = 4;
          "timeout-critical" = 0;

          "fit-to-screen" = false;
          "keyboard-shortcuts" = true;
          "image-visibility" = "when-available";
          "transition-time" = 150;
          "hide-on-clear" = true;
          "hide-on-action" = true;
          "script-fail-notify" = true;

          widgets = [
            "mpris"
            "volume"
            "backlight"
            "title"
            "notifications"
          ];

          "widget-config" = {
            title = {
              text = "Notifications";
              "clear-all-button" = true;
              "button-text" = "Clear";
            };

            mpris = {
              "image-size" = 80;
              "image-radius" = 10;
            };

            volume = {
              label = "";
              step = 5;
            };

            backlight = {
              label = "󰃞";
              step = 5;
            };

            "buttons-grid" = {
              actions = [
                {
                  label = "";
                  command = "ghostty -e wiremix";
                  tooltip = "Network";
                }
                {
                  label = "";
                  command = "ghostty -e bluetui";
                  tooltip = "Bluetooth";
                }
                {
                  label = "󰂛";
                  command = "swaync-client -d";
                  type = "toggle";
                  tooltip = "DND";
                }
                {
                  label = "󰈙";
                  command = "ghostty bash -i -c 'Docs'";
                  tooltip = "Files";
                }
              ];
            };
          };
        };

        style = let
          colors = config.lib.stylix.colors;
          desktopOpacity = config.stylix.opacity.desktop; # bars/widgets
          popupOpacity = config.stylix.opacity.popups; # notifications
        in
          /*
          css
          */
          ''
                        /* === Stylix Base16 → roles ===========================
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
                           * ===================================================== */

                          @define-color theme_fg           #${colors.base05};                         /* Primary Text */
                          @define-color theme_fg_secondary alpha(#${colors.base04}, 0.78);           /* Secondary Text */

                          @define-color theme_bg           alpha(#${colors.base00}, ${toString config.stylix.opacity.desktop});           /* Panel/Background */
                          @define-color popup_bg           alpha(#${colors.base00}, ${toString (config.stylix.opacity.popups * 0.8 )});           /* Floating Notification Background */

                          @define-color module_bg          alpha(#${colors.base01}, ${toString config.stylix.opacity.desktop});           /* Default Module Background */
                          @define-color module_hover_bg    alpha(#${colors.base02}, 0.35);           /* Module Hover */

                          @define-color button_bg          alpha(#${colors.base02}, 0.28);           /* Button Default */
                          @define-color button_hover_bg    alpha(#${colors.base02}, 0.40);           /* Button Hover */

                          @define-color accent_color       alpha(#${colors.base0D}, 0.80);           /* Accent Active */
                          @define-color accent_color_hover #${colors.base0D};                         /* Accent Hover */

                          @define-color border_light       alpha(#${colors.base06}, 0.18);
                          @define-color border_dark        alpha(#${colors.base00}, 0.06);
                          @define-color border_medium      alpha(@border_light, 0.5);

                          @define-color icon_primary       @theme_fg;
                          @define-color icon_secondary     alpha(#${colors.base04}, 0.88);

                          @define-color slider_trough_bg   alpha(#${colors.base01}, 0.35);
                          @define-color slider_thumb_bg    #${colors.base06};

                          @define-color close_button_bg        alpha(#${colors.base03}, 0.15);
                          @define-color close_button_hover_bg  alpha(#${colors.base03}, 0.30);

                          @define-color mpris_player_bg    alpha(#${colors.base00}, 0.50);

                          /* ── Base Reset ───────────────────────────────────────────────────── */
                          * {
                            font-family: "${config.stylix.fonts.monospace.name}", monospace;
                            font-size: ${toString (config.stylix.fonts.sizes.desktop - 1)}px;
                            color: @theme_fg;
                            border: none;
                            border-radius: 0;
                            background: none;
                            padding: 0;
                            margin: 0;
                            box-shadow: none;
                            text-shadow: none;
                            outline: none;
                          }

                          /* ── 2. Control Center Container ─────────────────────────────────── */
                          .control-center {
                            background-color: @theme_bg;
                            border: 1px solid @border_medium;
                            border-top-color: @border_light;
                            border-bottom-color: @border_dark;
                            border-radius: 20px;
                            padding: 10px;
                            margin-top: 50px;
                            min-width: 380px;
                            min-height: 800px;
                          }

                          /* ── 3. Widget Modules ───────────────────────────────────────────── */
                          .widget-mpris,
                          .widget-volume,
                          .widget-backlight,
                          .widget-buttons-grid,
                          .control-center-list > box > *:not(.widget-title) {
                            background-color: @module_bg;
                            border-radius: 18px;
                            padding: 18px;
                            margin-bottom: 14px;
                            border: 1px solid @border_medium;
                          }
                          .widget-volume, .widget-backlight { padding: 5px 10px; }
                          .widget-buttons-grid { padding: 12px; }
                          .control-center > box > *:last-child { margin-bottom: 0; }

                          /* Widget Titles */
                          .widget-title {
                            background: transparent;
                            border: none;
                            padding: 4px 6px 12px 6px;
                            margin-bottom: 8px;
                          }
                          .widget-title label {
                            font-family: "${config.stylix.fonts.monospace.name}";
                            font-size: 17px;
                            font-weight: 500;
                            color: @theme_fg_secondary;
                            margin-left: 4px;
                            background: none;
                          }
                          .widget-title button {
                            font-family: inherit;
                            font-size: 16px;
                            color: @theme_fg;
                            background-color: @button_bg;
                            border: none;
                            border-radius: 10px;
                            padding: 7px 16px;
                            transition: background-color 0.15s ease;
                          }
                          .widget-title button:hover,
                          .widget-title button:active {
                            background-color: @button_hover_bg;
                          }

                          /* ── 4. MPRIS Widget ────────────────────────────────────────────── */
                          .widget-mpris {
                            padding: 0;
                            border: none;
                            border-radius: 18px;
                            background: transparent;
                          }
                          .widget-mpris .widget-mpris-player {
                            background-color: @mpris_player_bg;
                            border-radius: 12px;
                            border: 1px solid @border_medium;
                            padding: 16px;
                          }
                          .widget-mpris .widget-mpris-album-art {
                            background: none;
                            min-width: 60px;
                            min-height: 60px;
                            border-radius: 16px;
                            margin-right: 12px;
                          }
                          .widget-mpris .widget-mpris-title {
                            font-size: 20px;
                            font-weight: 600;
                            color: @theme_fg;
                            margin-bottom: 4px;
                            background: none;
                          }
                          .widget-mpris .widget-mpris-subtitle {
                            font-size: 16px;
                            color: @theme_fg_secondary;
                            background: none;
                          }
                          .widget-mpris .widget-mpris-player button {
                            all: unset;
                            background: transparent;
                            border-radius: 50%;
                            padding: 7px;
                            color: @icon_secondary;
                            font-size: 16px;
                            min-width: 34px;
                            min-height: 34px;
                            transition: background-color 0.15s ease, color 0.15s ease;
                          }
                          .widget-mpris .widget-mpris-player button:hover {
                            background-color: @button_hover_bg;
                            color: @icon_primary;
                          }
                          .widget-mpris .widget-mpris-player button:disabled {
                            color: alpha(@icon_secondary, 0.3);
                          }

                          /* ── 5. Sliders (Volume, Backlight) ─────────────────────────────── */
                          .widget-volume label, .widget-backlight label {
                            font-size: 24px;
                            color: @icon_primary;
                            min-width: 24px;
                            margin-right: 14px;
                          }
                          scale trough {
                            min-height: 12px;
                            border-radius: 6px;
                            background-color: @slider_trough_bg;
                          }
                          scale trough progress {
                            min-height: 12px;
                            border-radius: 6px;
                            background-color: @accent_color;
                            transition: background-color 0.15s ease;
                          }
                          scale:hover trough progress {
                            background-color: @accent_color;
                          }
                          trough highlight {
                            padding: 5px;
                            background: @accent_color;
                            border-radius: 20px;
                            box-shadow: 0 0 5px rgba(0, 0, 0, .5);
                            transition: all 0.7s ease;
                          }
                          scale slider {
                            min-width: 14px;
                            min-height: 14px;
                            border-radius: 7px;
                            background-color: @slider_thumb_bg;
                          }

                          /* ── 6. Button Grid ─────────────────────────────────────────────── */
                          .widget-buttons-grid > flowbox {
                            padding: 0;
                            background: none;
                          }
                          .widget-buttons-grid > flowbox > flowboxchild {
                            padding: 3px;
                            background: none;
                          }
                          .widget-buttons-grid > flowbox > flowboxchild > button {
                            background-color: rgba(0,0,0, 0.7);
                            border-radius: 66px;
                            padding: 14px;
                            min-width: 24px;
                            min-height: 24px;
                            color: @icon_secondary;
                            transition: background-color 0.15s ease, color 0.15s ease;
                          }
                          .widget-buttons-grid > flowbox > flowboxchild > button:hover {
                            background-color: rgba(20,20,20, 0.45);
                            color: @icon_primary;
                          }
                          .widget-buttons-grid > flowbox > flowboxchild > button.toggle:checked {
                            background-color: @accent_color;
                            color: white;
                          }
                          .widget-buttons-grid > flowbox > flowboxchild > button.toggle:checked:hover {
                            background-color: @accent_color_hover;
                          }

                          /* ── 7. Notification Center ─────────────────────────────────────── */
                          .control-center-list {
                            padding-bottom: 1px;
                            background-color: transparent;
                          }
                          .control-center .notification-row {
                            margin-bottom: 12px;
                          }
                          .control-center .notification-background {
                            background-color: @module_bg;
                            border: 1px solid @border_medium;
                            padding: 16px;
                            border-radius: 18px;
                            transition: background-color 0.15s ease;
                          }
                          .control-center .notification-row:hover .notification-background {
                            border-radius: 18px;
                            background-color: @module_hover_bg;
                          }

                          .control-center .notification .summary {
                             font-weight: 600;
                             color: @theme_fg;
                             background: none;
                            margin-bottom: 5px;
                          }

                          .control-center .notification .body {
                            color: @theme_fg_secondary;
                          }
                          .control-center .notification .time {
                            font-size: 15px;
                            font-weight: 500;
                            color: @theme_fg_secondary;
                            margin-left: 12px;
                          }
                          .control-center .close-button {
                            background-color: @close_button_bg;
                            border-radius: 50%;
                            min-width: 24px;
                            min-height: 24px;
                            transition: background-color 0.15s ease;
                          }
                          .control-center .close-button:hover {
                            background-color: @close_button_hover_bg;
                          }
                          .control-center .close-button image {
                            margin-right: 12px;
                            color: @icon_secondary;
                          }

                          .control-center .notification image {
                            margin-right: 12px;
                            min-width: 36px;
                            min-height: 36px;
                            border-radius: 8px;
                          }

                          /* ── 8. Floating Notifications ─────────────────────────────────── */
                          .floating-notifications .notification-row {
                            margin-bottom: 12px;
                          }
                          .floating-notifications .notification-background {
                            background: @popup_bg;
                            border: 1px solid @border_light;
                            border-radius: 18px;
                            padding: 18px;
                            margin: 8px 14px;
                            transition: background-color 0.15s ease;
                          }

                          .floating-notifications .notification-row:hover .notification-background {
                            background-color: @popup_bg;
                          }
                          
                          .floating-notifications .notification .summary {
                            font-weight: 700;
                            color: @theme_fg;
                            background: none;
                          }

                          .floating-notifications .notification .body {
                            color: @theme_fg;
                          }
                          .floating-notifications .notification .time {
                            font-size: 15px;
                            color: @icon_secondary;
                            margin-left: 10px;
                          }
                          .floating-notifications .notification image {
                            min-width: 48px;
                            min-height: 48px;
                            margin-right: 14px;
                            border-radius: 10px;
                          }
                          .floating-notifications .close-button {
                            background-color: @close_button_bg;
                            border-radius: 50%;
                            min-width: 28px;
                            min-height: 28px;
                            transition: background-color 0.15s ease;
                          }
                          .floating-notifications .close-button:hover {
                            background-color: @close_button_hover_bg;
                          }
                          .floating-notifications .close-button image {
                            margin-right: 12px;
                            color: @icon_secondary;
                          }
                          .floating-notifications .notification-alt-actions {
                            margin-top: 16px;
                            padding-top: 16px;
                            border-top: 1px solid @border_medium;
                          }
                          .floating-notifications .notification-action button,
                          .floating-notifications .notification-alt-actions button {
                            font-size: 16px;
                            color: @theme_fg;
                            background-color: @button_bg;
                            border-radius: 12px;
                            padding: 8px 18px;
                            transition: background-color 0.15s ease;
                          }
                          .floating-notifications .notification-action button:hover,
                          .floating-notifications .notification-alt-actions button:hover {
                            background-color: @button_hover_bg;
                          }

          '';
      };
    };
  };
}
