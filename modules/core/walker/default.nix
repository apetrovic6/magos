{ inputs, ... }:{
flake.homeModules.walker = {config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkEnableOption;
  cfg = config.magos.hm.walker;
in
{
  options.magos.hm.walker = {
      enable = mkEnableOption "Enable and setup walker";
  };

  config = lib.mkIf cfg.enable {
  

        programs.walker = {
          enable = true;
          runAsService = true; # Note: this option isn't supported in the NixOS module only in the home-manager module

          # All options from the config.toml can be used here https://github.com/abenz1267/walker/blob/master/resources/config.toml
          config = {
          theme = "default";
          placeholders = {
            "default" = { input = "Search"; list = "No Results"; };
            "files" = { input = "Browse Files"; list = "No Files Found"; };
            "calc" = { input = "Calculate"; list = "Enter Expression"; };
            "runner" = { input = "Run Command"; list = "No Commands"; };
            "websearch" = { input = "Search Web"; list = ""; };
            "clipboard" = { input = "Clipboard"; list = "Clipboard Empty"; };
            "symbols" = { input = "Symbol"; list = "No Symbols"; };
            "todo" = { input = "Todo"; list = "No Todos"; };
          };

        providers.prefixes = [
          {provider = "websearch"; prefix = "@";}
          {provider = "providerlist"; prefix = ";";}
          {provider = "clipboard"; prefix = ":";}
          {provider = "files"; prefix = "/";}
          {provider = "runner"; prefix = ">";}
          {provider = "windows"; prefix = "$";}
          {provider = "symbols"; prefix = ".";}
          {provider = "todo"; prefix = "!";}
        ];

      # providers.actions = [];

     keybinds.quick_activate = [];



      };
    };
  };
};
}
