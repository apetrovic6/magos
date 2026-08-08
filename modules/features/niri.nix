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
    outputs ? {},
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
  in
    {
      spawn-at-startup =
        [
          (lib.getExe noctaliaPkg)
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          [
            "${pkgs.bash}/bin/sh"
            "-c"
            "systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP && systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-gnome.service xdg-desktop-portal-wlr.service"
          ]
        ]
        ++ lib.optional (wallpaper != null) ["${pkgs.swaybg}/bin/swaybg" "-i" "${wallpaper}" "-m" "fill"];

      xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

      extraConfig = ''
        prefer-no-csd

        // NVIDIA screencast: `force-pipewire-invalid-modifier` used to be set here
        // to work around PipeWire modifier fixation failing ("wrong modifier choice
        // type"). As of niri 26.04 / nvidia 595.84 it is actively harmful: GBM
        // allocates the buffer fine with modifier=Invalid, but NVIDIA's EGL cannot
        // import an implicit-modifier dmabuf, so every frame dies with
        //   [GL] GL_INVALID_OPERATION ... EGLImage not supported
        //   niri::screencasting::pw_utils: error rendering to dmabuf
        // and the share is a black/frozen screen. Leave explicit modifier
        // negotiation enabled. If "wrong modifier choice type" ever comes back,
        // re-add:
        //   debug { force-pipewire-invalid-modifier }
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
          width = 1.5;
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
          "${super}+Space" = _: {
            props.hotkey-overlay-title = "Toggle Launcher";
            content.spawn-sh = "${lib.getExe noctaliaPkg} msg panel-toggle launcher";
          };
          "${super}+N".spawn-sh = "${lib.getExe noctaliaPkg} msg panel-toggle control-center";

          "${super}+Ctrl+Up".focus-workspace-up = _: {};
          "${super}+Ctrl+Down".focus-workspace-down = _: {};

          "${super}+Alt+Up".move-workspace-up = _: {};
          "${super}+Alt+Down".move-workspace-down = _: {};

          "${super}+Shift+Ctrl+Up".move-column-to-workspace-up = _: {};
          "${super}+Shift+Ctrl+Down".move-column-to-workspace-down = _: {};

          "${super}+return" = _: {
            props.hotkey-overlay-title = "Spawn Terminal";
            content.spawn-sh = lib.getExe terminalPkg;
          };

          "${super}+Escape" = _: {
            props.hotkey-overlay-title = "Session Control";
            content.spawn-sh = "${lib.getExe noctaliaPkg} msg panel-toggle launcher /session";
          };

          "${super}+B".spawn-sh = "librewolf";
          "${super}+O".toggle-overview = _: {};
          "${super}+W".close-window = _: {};
          "${super}+F".maximize-column = _: {};
          "${super}+R".switch-preset-column-width = _: {};
          "${super}+T".toggle-window-floating = _: {};
          "${super}+C".center-column = _: {};
          "${super}+Comma".consume-window-into-column = _: {};
          "${super}+Period".expel-window-from-column = _: {};

          "${super}+E" = _: {
            props.hotkey-overlay-title = "Audio Mixer";
            content.spawn = ["${lib.getExe terminalPkg}" "--app-id" "foot-floating" "-e" "${lib.getExe pkgs.wiremix}"];
          };

          # "${super}+A".spawn = ["${lib.getExe terminalPkg}" "--app-id" "foot-floating" "-e" "${lib.getExe pkgs.impala}"];
          "${super}+I" = _: {
            props.hotkey-overlay-title = "Bluetooth";
            content.spawn = ["${lib.getExe terminalPkg}" "--app-id" "foot-floating" "-e" "${lib.getExe pkgs.bluetui}"];
          };

          "${super}+Ctrl+S" = _: {
            props.hotkey-overlay-title = "Screenshot Area";
            content.spawn-sh = "${lib.getExe pkgs.grim} -g \"$(${lib.getExe pkgs.slurp})\" - | ${lib.getExe pkgs.satty} --filename -";
          };

          "${super}+Ctrl+Shift+S" = _: {
            props.hotkey-overlay-title = "Screenshot Screen";
            content.spawn-sh = "${lib.getExe pkgs.grim} - | ${lib.getExe pkgs.satty} --filename -";
          };

          "XF86AudioRaiseVolume".spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"];
          "XF86AudioLowerVolume".spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"];
          "XF86AudioMute".spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
          "XF86AudioMicMute".spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];

          "XF86MonBrightnessUp".spawn = ["brightnessctl" "-d" "intel_backlight" "set" "5%+"];
          "XF86MonBrightnessDown".spawn = ["brightnessctl" "-d" "intel_backlight" "set" "5%-"];
        }
        // directionalBinds
        // workspaceBinds;

      window-rules = [
        {
          matches = [{title = "^Picture.in.Picture$";}];
          open-floating = true;
          open-focused = false;
        }
        {
          matches = [
            {app-id = "^nm-connection-editor$";}
            {app-id = "^pavucontrol$";}
            {app-id = "^blueman-manager$";}
            {app-id = "^foot-floating$";}
          ];
          open-floating = true;
        }
        {
          matches = [
            {app-id = "^com.bitwarden.desktop$";}
          ];
          block-out-from = "screen-capture";
        }
      ];
    }
    // lib.optionalAttrs (cursor != null) {
      cursor = {
        xcursor-theme = cursor.name;
        xcursor-size = cursor.size;
      };
    }
    // lib.optionalAttrs (outputs != {}) {
      inherit outputs;
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
    cfg = config.magos.niri;
  in {
    options.magos.niri.outputs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = {};
      description = "Per-output niri settings keyed by output name (e.g. scale, mode).";
    };

    config = {
      environment.systemPackages = [pkgs.wl-clipboard];

      xdg.portal = {
        enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-wlr];
        config.niri = {
          "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
          "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
        };
      };

      services.gnome.gnome-keyring.enable = true;

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
            outputs = cfg.outputs;
          };
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
