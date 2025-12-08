{self, ...}: {
  flake.homeModules.hyprland-bindings = {
    config,
    lib,
    pkgs,
    ...
  }:
    with pkgs; let
      inherit (lib) getExe;
      inherit (self.lib.hyprland) mkBind mkSubmapBind;
      modifier = "SUPER";

      launcher = "walker -m desktopapplications";
      browser = getExe librewolf;
      terminal = getExe ghostty;
      passwordManager = getExe bitwarden-desktop;
      fileManager = getExe xfce.thunar;
      messenger = getExe signal-desktop-bin;

      mkWebapp = url: "${lib.getExe pkgs.brave} --profile-directory=\"Web Apps\" --app=${url}";

      execTerminal = {
        id,
        exe,
      }: ''
        ${terminal} --class=ghostty.${id} -e ${exe}
      '';
    in {
      wayland.windowManager.hyprland.settings = {
        bindd = [
          (mkBind {
            key = "SPACE";
            desc = "Launcher";
            cmd = launcher;
          })

          (mkBind {
            key = "RETURN";
            desc = "Terminal";
            cmd = terminal;
          })

          # #"${modifier}, M, Music player, exec, ${music}"

          "${modifier}, O, Obsidian, exec, ${obsidian} -disable-gpu"
          "${modifier}, SLASH, Password manager, exec, ${passwordManager}"

          # Hyprpanel
          # "${modifier} SHIFT, SPACE, Toggle Hyprpanel, exec, hyprpanel toggleWindow bar-0"
          # "${modifier} SHIFT, N, Notifications, exec, hyprpanel t notificationsmenu"

          (mkBind {
            mods = ["SUPER" "SHIFT"];
            key = "F";
            desc = "File Manager";
            cmd = fileManager;
          })

          (mkBind {
            key = "B";
            desc = "Browser";
            cmd = browser;
          })

          (mkBind {
            key = "G";
            desc = "Messenger";
            cmd = messenger;
          })

          (mkBind {
            key = "N";
            desc = "Helix";
            cmd = execTerminal {
              id = "helix";
              exe = "hx";
            };
          })

          (mkBind {
            key = "F";
            desc = "Terminal File Manager";
            cmd = execTerminal {
              id = "filemanager";
              exe = "${getExe pkgs.yazi}";
            };
          })

          (mkBind {
            key = "D";
            desc = "Lazy Docker";
            cmd = execTerminal {
              id = "docker";
              exe = "${getExe pkgs.lazydocker}";
            };
          })

          (mkBind {
            key = "ESCAPE";
            desc = "Power Menu";
            cmd = "walker -m menus:power-menu";
          })

          (mkBind {
            mods = [modifier "SHIFT"];
            key = "N";
            desc = "Toggle SwayNC";
            cmd = "swaync-client -t";
          })

          (mkBind {
            mods = [modifier "SHIFT"];
            key = "SPACE";
            desc = "Toggle Waybar";
            cmd = "pkill -SIGUSR1 waybar";
          })

          (mkBind {
            key = "C";
            desc = "Wireless Settings";
            cmd = execTerminal {
              id = "wifi";
              exe = "${getExe pkgs.impala}";
            };
          })

          (mkBind {
            key = "I";
            desc = "Bluetooth Control Panel";
            cmd = execTerminal {
              id = "bluetooth";
              exe = "${getExe pkgs.bluetui}";
            };
          })

          (mkBind {
            key = "E";
            desc = "Audio Control Panel";
            cmd = execTerminal {
              id = "audio";
              exe = "${getExe pkgs.wiremix}";
            };
          })

          (mkBind {
            key = "A";
            desc = "ChatGPT";
            cmd = mkWebapp "https://chatgpt.com";
          })
        ];

        bind = [
          "ALT, R, submap, resize"
          "ALT, W, submap, web"
        ];
      };

      wayland.windowManager.hyprland.extraConfig = ''
        # --- resize submap ---
        # Start a submap called "resize".
        submap = resize

        # Set repeatable binds for resizing the active window.
        binde = , right, resizeactive, 10 0
        binde = , left,  resizeactive, -10 0
        binde = , up,    resizeactive, 0 -10
        binde = , down,  resizeactive, 0 10

        # escape to leave the resize submap
        bind = , escape, submap, reset

        # Reset the submap, which will return to the global submap
        submap = reset

        submap = web

        ${
          mkSubmapBind {
            key = "N";
            cmd = mkWebapp  "https://noogle.dev";
          }
        }

        submap = reset
      '';
    };
}
