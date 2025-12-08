{...}: {
  flake.homeModules.hyprland-bindings = {
    config,
    lib,
    pkgs,
    ...
  }:
    with pkgs; let
      inherit (lib) getExe;
      modifier = "SUPER";

      launcher = "walker -m desktopapplications";
      browser = getExe librewolf;
      terminal = getExe ghostty;
      passwordManager = getExe bitwarden-desktop;
      fileManager = getExe xfce.thunar;
      messenger = getExe signal-desktop-bin;

      mkWebapp = url: "${getExe brave} --profile-directory=\"Web Apps\" --app=${url}";

      execTerminal = {
        id,
        exe,
      }: ''
        ${terminal} --class=ghostty.${id} -e ${exe}
      '';

      mkBind = {
        mods ? ["${modifier}"],
        key,
        desc ? "",
        command,
      }: ''
        ${lib.concatStringsSep " " mods}, ${key}, ${desc},  exec, ${command}
      '';
    in {
      wayland.windowManager.hyprland.settings.bindd = [
        (mkBind {
          key = "SPACE";
          desc = "Launcher";
          command = launcher;
        })

        (mkBind {
          key = "RETURN";
          desc = "Terminal";
          command = terminal;
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
          command = fileManager;
        })

        (mkBind {
          key = "B";
          desc = "Browser";
          command = browser;
        })

        (mkBind {
          key = "G";
          desc = "Messenger";
          command = messenger;
        })

        (mkBind {
          key = "N";
          desc = "Helix";
          command = execTerminal {
            id = "helix";
            exe = "hx";
          };
        })

        (mkBind {
          key = "F";
          desc = "Terminal File Manager";
          command = execTerminal {
            id = "filemanager";
            exe = "${getExe pkgs.yazi}";
          };
        })

        (mkBind {
          key = "D";
          desc = "Lazy Docker";
          command = execTerminal {
            id = "docker";
            exe = "${getExe pkgs.lazydocker}";
          };
        })

        (mkBind {
          key = "ESCAPE";
          desc = "Power Menu";
          command = "walker -m menus:power-menu";
        })

        (mkBind {
          mods = [modifier "SHIFT"];
          key = "N";
          desc = "Toggle SwayNC";
          command = "swaync-client -t";
        })

        (mkBind {
          mods = [modifier "SHIFT"];
          key = "SPACE";
          desc = "Toggle Waybar";
          command = "pkill -SIGUSR1 waybar";
        })

        (mkBind {
          key = "C";
          desc = "Wireless Settings";
          command = execTerminal {
            id = "wifi";
            exe = "${getExe pkgs.impala}";
          };
        })

        (mkBind {
          key = "I";
          desc = "Bluetooth Control Panel";
          command = execTerminal {
            id = "bluetooth";
            exe = "${getExe pkgs.bluetui}";
          };
        })

        (mkBind {
          key = "E";
          desc = "Audio Control Panel";
          command = execTerminal {
            id = "audio";
            exe = "${getExe pkgs.wiremix}";
          };
        })

        (mkBind {
          key = "A";
          desc = "ChatGPT";
          command = mkWebapp "https://chatgpt.com";
        })

        (mkBind {
          mods = [];
          key = "A";
          desc = "ChatGPT";
          command = mkWebapp "https://chatgpt.com";
        })      ];
    };
}
