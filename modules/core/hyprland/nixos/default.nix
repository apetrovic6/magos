{inputs, ...}: {
  flake.nixosModules.hyprland = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit
      (lib)
      mkEnableOption
      mkOption
      mkIf
      types
      optionalAttrs
      mkMerge
      ;

    cfg = config.magos.core.hyprland;
    hypr = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  in {

    
    options.magos.core.hyprland = {
      enable = mkEnableOption "Enable Hyprland desktop";
      xwayland = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Xwayland support for Hyprland.";
      };

monitor = mkOption {
      type = types.str;
      default = ",preferred,auto,1";
      description = ''
        Hyprland `monitor` line that will be used in the Home-Manager config.
        Format: name,resolution@hz,pos,scale
        Example: "eDP-1,2560x1440@165,0x0,1"
      '';
    };


      nvidia = {
        enable = mkEnableOption "Enable NVIDIA support (env + kernel toggles)";
        modesetting = mkOption {
          type = types.bool;
          default = false;
          description = "Enable kernel modesetting for NVIDIA.";
        };
        powerManagement = mkOption {
          type = types.bool;
          default = false;
          description = "Enable NVIDIA power management.";
        };
      };

      # Use Hyprland packages from the hyprland input (recommended)
      useHyprlandInputFlake = mkOption {
        type = types.bool;
        default = true;
        description = "Use inputs.hyprland for Hyprland and its portal, keeping them in sync.";
      };

      # Let callers extend systemPackages
      extraPackages = mkOption {
        type = with types; listOf package;
        default = [];
        description = "Extra packages to add alongside the Hyprland desktop stack.";
      };
    };

    config = mkIf cfg.enable {
      # Hyprland Cachix (additive so it won't stomp existing substituters)
      nix.settings = {
        substituters = ["https://hyprland.cachix.org"];
        trusted-substituters = ["https://hyprland.cachix.org"];
        trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
      };

      # Wayland-friendly env, plus conditional NVIDIA vars
      environment.variables = mkMerge [
        {
          GDK_BACKEND = "wayland,x11,*";
          QT_QPA_PLATFORM = "wayland;xcb";
          SDL_VIDEODRIVER = "wayland";
          CLUTTER_BACKEND = "wayland";

          XDG_CURRENT_DESKTOP = "Hyprland";
          XDG_SESSION_TYPE = "wayland";
          XDG_SESSION_DESKTOP = "Hyprland";

          QT_STYLE_OVERRIDE = "kvantum";
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          QT_QPA_PLATFORMTHEME = "qt5ct";

          MOZ_ENABLE_WAYLAND = "1";
          NIXOS_OZONE_WL = "1";
        }

        (optionalAttrs cfg.nvidia.enable {
          LIBVA_DRIVER_NAME = "nvidia";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        })
      ];

      # Kernel-side NVIDIA toggles
      hardware.nvidia = {
        modesetting.enable = cfg.nvidia.enable && cfg.nvidia.modesetting;
        powerManagement.enable = cfg.nvidia.enable && cfg.nvidia.powerManagement;
      };

      # Hyprland program + portal
      programs.hyprland =
        {
          enable = true;
          xwayland.enable = cfg.xwayland;
        }
        // (
          if cfg.useHyprlandInputFlake
          then {
            package = hypr.hyprland;
            portalPackage = hypr.xdg-desktop-portal-hyprland;
          }
          else {}
        );

      # Desktop stack
      environment.systemPackages = with pkgs;
        [
          hyprpaper
          hyprpicker
          wlogout
          adwaita-fonts
          hyprcursor
          hyprpanel
          # wf-recorder
          # grimblast
          playerctl
          wireplumber
          wl-clipboard
          xdg-desktop-portal-hyprland
          qt5.qtwayland
          qt6.qtwayland
        ]
        ++ cfg.extraPackages;
    };
  };
}
