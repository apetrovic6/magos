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
        # spawn-at-stratup = [
        #   (lib.getExe self'.packages.${pkgs.stdenv.hostPlatform.system}.noctalia)
        # ];

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

        layout.gaps = 5;

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
            "${super}+return".spawn-sh = lib.getExe pkgs.foot;
            "${super}+Q".close-window = _: {};
            "${super}+F".maximize-column = _:{};
            "${super}+G".fullscreen-column = _:{};
            "${super}+T".toggle-window-floating= _:{};
            "${super}+C".center-column = _:{};
          }
          // directionalBinds
          // workspaceBinds;


        
      };
    };
  };
}
