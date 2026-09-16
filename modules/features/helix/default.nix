{
  self,
  inputs,
  ...
}: let
  defaultTheme = "everforest_dark";

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
      # Renamed from `extraPackages` upstream in nix-wrapper-modules#540
      # (2026-05-19). A pure rename for callers that only set it; the type also
      # widened to accept `{ data, prefix ? false, ... }` entries so an entry can
      # be prefixed rather than suffixed onto PATH.
      #
      # Not to be confused with `programs.helix.extraPackages`, which is the
      # home-manager/NixOS option and still spelled the old way — that is the
      # name in the commented-out block below.
      runtimePkgs = with pkgs; [alejandra tailwindcss-language-server];
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
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.helix;
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
