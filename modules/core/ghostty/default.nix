{inputs, ...}: {
  flake.homeModules.ghostty = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) types mkOption mkEnableOption;
    cfg = config.magos.hm.core.ghostty;
  in {
    options.magos.hm.core.ghostty = {
      enable = mkEnableOption "Enable and setup Ghostty";

      enableBashIntegration = mkOption {
        type = types.bool;
        default = config.magos.shell.bash.enable or true;
        description = "Enable Ghostty Bash integration";
      };

      enableZshIntegration = mkOption {
        type = types.bool;
        default = config.magos.shell.zsh.enable or false;
        description = "Enable Ghostty Zsh integration";
      };
    };

    config = lib.mkIf cfg.enable {
      programs.ghostty = {
        enable = cfg.enable;

        enableBashIntegration = cfg.enableBashIntegration;
        enableZshIntegration = cfg.enableZshIntegration;

        installBatSyntax = true;
        installVimSyntax = true;

        settings.window-padding-x = 5;
        # settings.window-padding-y = 10;

        settings.keybind = [
          # Splits
          "ctrl+s=new_split:auto"
          "ctrl+left=goto_split:left"
          "ctrl+right=goto_split:right"
          "ctrl+up=goto_split:up"
          "ctrl+down=goto_split:down"

          # Resize Split
          "ctrl+shift+left=resize_split:left,10"
          "ctrl+shift+right=resize_split:right,10"
          "ctrl+shift+up=resize_split:up,10"
          "ctrl+shift+down=resize_split:down,10"
          "ctrl+shift+enter=equalize_splits"

          # Tabs
          "ctrl+t=new_tab"
          "ctrl+w=close_tab"
          "shift+left=next_tab"
          "shift+right=previous_tab"
        ];
      };
    };
  };
}
