{
  self,
  inputs,
  ...
}: let
  defaultTheme = "catppuccin_frappe";

  editorSettings = import ./_config/editor.nix;
  languageSettings = import ./_config/languages.nix;

  makeHelixPackage = {
    pkgs,
    theme ? defaultTheme,
  }:
    inputs.wrapper-modules.wrappers.helix.wrap {
      inherit pkgs;
      settings = editorSettings // {theme = theme;};
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
        settings = editorSettings // {theme = config.magos.helix.theme;};
        languages = languageSettings;
      };
    };
  };

  perSystem = {pkgs, ...}: {
    packages.helix = makeHelixPackage {inherit pkgs;};
  };
}
