{
  self,
  inputs,
  ...
}: let
  defaultTheme = self.lib.colors.everforest-dark-soft;

  makeSettings = {
    pkgs,
    lib,
    colors,
    terminalPkg,
    noctaliaPkg,
    wallpaper ? null,
    cursor ? null,
  }: let
    super = "Super";

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
  in {
    spawn-at-startup =
      [(lib.getExe noctaliaPkg)]
      ++ lib.optional (wallpaper != null) ["${pkgs.swaybg}/bin/swaybg" "-i" "${wallpaper}" "-m" "fill"];

    xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

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

    hotkey-overlay = {
      skip-at-startup = _: {};
    };

    layout = {
      gaps = 8;

      # default-column-width = {proportion = 1.0;};

      focus-ring = {
        width = 1;
        active-color = "#${colors.base0D}";
        inactive-color = "#${colors.base03}";
      };

      border = {
        width = 1;
        active-color = "#${colors.base0D}";
        inactive-color = "#${colors.base03}";
      };
    };

    screenshot-path = null;

    binds =
      {
        "${super}+Shift+Slash".show-hotkey-overlay = _: {};
        "${super}+Shift+Space".switch-layout = "next";
        "${super}+Shift+M".quit = _: {};
        "${super}+Space".spawn-sh = "${lib.getExe noctaliaPkg} msg panel-toggle launcher";

        "${super}+return" = _: {
          props.hotkey-overlay-title = "Spawn Terminal";
          content.spawn-sh = lib.getExe terminalPkg;
        };

        "${super}+Escape".spawn-sh = "${lib.getExe noctaliaPkg} msg session lock";

        "${super}+B".spawn-sh = "librewolf";
        "${super}+Q".close-window = _: {};
        "${super}+F".maximize-column = _: {};
        "${super}+R".switch-preset-column-width = _: {};
        "${super}+T".toggle-window-floating = _: {};
        "${super}+C".center-column = _: {};
        "${super}+Comma".consume-window-into-column = _: {};
        "${super}+Period".expel-window-from-column = _: {};

        "${super}+Ctrl+S".spawn-sh = "grim -g \"$(slurp)\" - | satty --filename -";
        "${super}+Ctrl+Shift+S".spawn-sh = "grim - | satty --filename -";

        "XF86AudioRaiseVolume".spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"];
        "XF86AudioLowerVolume".spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"];
        "XF86AudioMute".spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
        "XF86AudioMicMute".spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];

        "XF86MonBrightnessUp".spawn = ["brightnessctl" "-d" "intel_backlight" "set" "5%+"];
        "XF86MonBrightnessDown".spawn = ["brightnessctl" "-d" "intel_backlight" "set" "5%-"];
      }
      // directionalBinds
      // workspaceBinds;
  } // lib.optionalAttrs (cursor != null) {
    cursor = {
      xcursor-theme = cursor.name;
      xcursor-size = cursor.size;
    };
  };
in {
  flake.nixosModules.niri = {
    pkgs,
    lib,
    config,
    ...
  }: let
    system = pkgs.stdenv.hostPlatform.system;
    colors = config.lib.stylix.colors or defaultTheme;
    pkg = self.packages.${system};
  in {
    environment.systemPackages = with pkgs; [grim slurp satty];

    programs.niri = {
      enable = true;
      package = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = makeSettings {
          inherit pkgs lib colors;
          terminalPkg = pkg.foot;
          noctaliaPkg = self.lib.makeNoctaliaPackage {
            inherit pkgs colors;
            wallpaper = config.stylix.image or null;
          };
          wallpaper = config.stylix.image or null;
          cursor = config.stylix.cursor or null;
        };
      };
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
      settings = makeSettings {
        inherit pkgs lib;
        colors = defaultTheme;
        terminalPkg = self'.packages.foot;
        noctaliaPkg = self'.packages.noctalia;
      };
    };
  };
}
