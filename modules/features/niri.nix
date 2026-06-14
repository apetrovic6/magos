{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.niri = {
    pkgs,
    lib,
    ...
  }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri;
    };
  };

  perSystem = {
    pkgs,
    lib,
    self',
    ...
  }: {
    packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;

      settings = {
        spawn-at-startup = [
          (lib.getExe self'.packages.noctalia)
        ];

        # xwayland-sattelite.path = lib.getExe pkgs.xwayland-satellite;
        extraConfig = ''
          prefer-no-csd
        '';

        input = {
          focus-follows-mouse = _: {};
          keyboard = {
            xkb.layout = "us,hr";
          };

          touchpad = {
            natural-scroll = _: {};
            tap = _: {};
          };

          mouse = {
            accel-profile = "flat";
          };
        };

        layout.gaps = 10;

        focus-ring = {
          width = 1.5;

          active-color = "";
          inactive-color = "";
        };


        border = {
          width = 1.5;
          active-color = "";
          inactive-color = "";
        };

        binds = let
          super = "Mod";

          directions = [
            {
              key = "H";
              type = "column";
              direction = "left";
            }
            {
              key = "L";
              type = "column";
              direction = "right";
            }
            {
              key = "K";
              type = "window";
              direction = "up";
            }
            {
              key = "J";
              type = "window";
              direction = "down";
            }
          ];

          verbs = [
            {
              modifier = super;
              verb = "focus";
            }
            {
              modifier = "${super}+Shift";
              verb = "move";
            }
          ];

          directionalBinds = lib.listToAttrs (lib.concatMap (
              v:
                lib.concatMap (x: [
                  (lib.nameValuePair "${v.modifier}+${lib.toSentenceCase x.direction}" {"${v.verb}-${x.type}-${x.direction}" = _: {};})
                  (lib.nameValuePair "${v.modifier}+${x.key}" {"${v.verb}-${x.type}-${x.direction}" = _: {};})
                ])
                directions
            )
            verbs);

          workspaceBinds = lib.listToAttrs (lib.concatMap (n: [
            (lib.nameValuePair "${super}+${toString n}" {focus-workspace = n;})
            (lib.nameValuePair "${super}+Shift+${toString n}" {move-column-to-workspace = n;})
          ]) (lib.range 0 9));
        in
          {
            "${super}+Shift+Slash".show-hotkey-overlay = _: {};

            "${super}+return" = _: {
              props.hotkey-overlay-title = "Spawn Terminal";
              content.spawn-sh = lib.getExe self'.packages.foot;
            };

            "${super}+B".spawn-sh = "librewolf";
            "${super}+Q".close-window = _: {};
            "${super}+F".maximize-column = _: {};
            # "${super}+G".fullscreen-column = _:{};
            "${super}+T".toggle-window-floating = _: {};
            "${super}+C".center-column = _: {};

            "XF86AudioRaiseVolume".spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"];
            "XF86AudioLowerVolume".spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"];
            "XF86AudioMute".spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
            "XF86AudioMicMute".spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];

            # "XF86MonBrightnessUp".spawn = ["brightnessctl" "set" "1%+"];
            # "XF86MonBrightnessDown".spawn = ["brightnessctl" "set" "1%-"];

            # Brightness
            "XF86MonBrightnessUp".spawn = ["brightnessctl" "-d" "intel_backlight" "set" "5%+"];
            "XF86MonBrightnessDown".spawn = ["brightnessctl" "-d" "intel_backlight" "set" "5%-"];
          }
          // directionalBinds
          // workspaceBinds;
      };
    };
  };
}
