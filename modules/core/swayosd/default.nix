{
  inputs,
  self,
  ...
}: {
  flake.homeModules.swayosd = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkOption types mkIf optionals mkMerge;
    cfg = config.magos.hm.core.swayosd;
  in {
    imports = [
    ];

    options.magos.hm.core.swayosd = {
      enable = mkEnableOption "Enable SwayOSD";
    };

    config = mkIf cfg.enable {
      services.swayosd = {
        enable = true;
        stylePath = "${config.xdg.configHome}/swayosd/style.css";
      };

      xdg.configFile."swayosd/style.css".text = let
        colors = config.lib.stylix.colors;
        popupOpacity = config.stylix.opacity.popups;
      in ''
        /* Stylix → roles
             * surface      = base00
             * on-surface   = base05
             * selection    = base02
             * primary      = base0D
             */

            window#osd {
              border-radius: 999px;
              border: none;
              /* OSD background: theme surface with popup opacity */
              background: alpha(#${colors.base00}, ${toString popupOpacity});

              #container {
                margin: 16px;
              }

              image,
              label {
                color: #${colors.base05}; /* on-surface */
              }

              progressbar:disabled,
              image:disabled {
                opacity: 0.5;
              }

              progressbar,
              segmentedprogress {
                min-height: 6px;
                border-radius: 999px;
                background: transparent;
                border: none;
              }

              trough,
              segment {
                min-height: inherit;
                border-radius: inherit;
                border: none;
                /* faint track using selection color */
                background: alpha(#${colors.base02}, 0.5);
              }

              progress,
              segment.active {
                min-height: inherit;
                border-radius: inherit;
                border: none;
                /* fill / active segment uses primary accent */
                background: #${colors.base0D};
              }

              segment {
                margin-left: 8px;
              }

              /* GTK CSS, not SCSS: no & */
              segment:first-child {
                margin-left: 0;
              }
            };
      '';
    };
  };
}
