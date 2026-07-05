{
  self,
  inputs,
  ...
}: let
  defaultTheme = "catppuccin_frappe";

  editorSettings = import ./_config/editor.nix;
  languages = import ./_config/languages.nix;
  makeKeybinds = pkgs: import ./_config/keybinds.nix {inherit pkgs;};

  makeHelixPackage = {
    pkgs,
    theme ? defaultTheme,
  }:
    inputs.wrapper-modules.wrappers.helix.wrap {
      inherit pkgs;
      settings =
        editorSettings
        // {
          theme = theme;
          keys = (makeKeybinds pkgs).keys;
        };
      inherit languages;
      # languages.language = language.language;
      # languages.language-server = language.language-server;
      extraPackages = with pkgs; [alejandra];
    };
in {
  flake.nixosModules.helix = {
    pkgs,
    lib,
    config,
    ...
  }: {
    options.magos.helix.theme = lib.mkOption {
      type = lib.types.str;
      default = defaultTheme;
      description = "Helix colorscheme name.";
    };

    config = {
      programs.helix = {
        enable = true;
        package = self.packages.helix;
        # settings =
        #   editorSettings
        #   // {
        #     theme = config.magos.helix.theme;
        #     keys = (makeKeybinds pkgs).keys;
        #   };
        # inherit languages;
        # runtimePackages = with pkgs; [alejandra];
      };
    };
  };

  perSystem = {pkgs, ...}: {
    packages.helix = makeHelixPackage {inherit pkgs;};
  };
}
