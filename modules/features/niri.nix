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
          focus-follows-mouse = _: {} ;

          keyboard = {
            xkb.layout = "us,hr";
          };

          touchpad = {
            natural-scroll = _: {} ;
            tap = _: {} ;
          };

          mouse = {
            accel-profile = "flat";
          };
        };

        layout.gaps = 5;

        binds = let
          super = "Mod";

        directions = [
          { key = "H"; action = "column"; direction = "left"; }
          { key = "L"; action = "column"; direction = "right"; }
          { key = "K"; action = "window"; direction = "up"; }
          { key = "J"; action = "window"; direction = "down"; }
        ];

          moveFocusArrows = lib.map (x: lib.nameValuePair "${super}+${lib.toSentenceCase x.direction}" { "focus-${x.action}-${x.direction}" = _: {} ;}) directions;
          moveFocusKeys= lib.map (x: lib.nameValuePair "${super}+${lib.toSentenceCase x.key}" { "focus-${x.action}-${x.direction}" = _: {};}) directions;

                    
          
        in {
          "${super}+return".spawn-sh = lib.getExe pkgs.foot;
          "${super}+Q".close-window = _: {} ;


        }
          // lib.listToAttrs moveFocusArrows
          // lib.listToAttrs moveFocusKeys
          
            

          
          
          ;
      };
    };
  };
}
