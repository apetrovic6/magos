{ inputs, ... }:{
flake.homeModules.ghostty = {config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkEnableOption;
  cfg = config.magos.hm.ghostty;
in
{
  options.magos.hm.ghostty = {
      enable = mkEnableOption "Enable and setup Ghostty";

      enableBashIntegration = mkOption { 
         type = types.boolean;
         default = config.magos.shell.bash.enable or true;
         description = "Enable Ghostty Bash integration";
      };

      enableZshIntegration = mkOption { 
         type = types.boolean;
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

          settings.window-padding-x = 10;
          settings.window-padding-y = 10;

      };
  };
};
}
