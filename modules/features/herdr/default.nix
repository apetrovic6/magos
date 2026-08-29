{
  lib,
  inputs,
  ...
}: let
  # Underscore-prefixed so `import-tree` skips it: this is a nix-wrapper-modules
  # module, not a flake-parts one.
  herdrModule = import ./_module.nix;

  # Mirrors what used to live in ~/.config/herdr/config.toml, plus the full
  # keybinding skeleton.
  baseSettings = {
    keys = import ./_config/keys.nix;

    ui.agent_panel_sort = "priority";

    theme = {
      name = "terminal";
      auto_switch = false;
    };
  };

  # mkDefault every leaf rather than whole sections, so overriding one setting
  # downstream does not have to restate (or mkForce) its siblings:
  #
  #   self.packages.x86_64-linux.herdr.wrap {
  #     settings.keys.detach = "prefix+d";
  #   }
  #
  # Lists (e.g. keys.command) are leaves here, so overriding one replaces it
  # wholesale rather than appending.
  settings = lib.mapAttrsRecursive (_: lib.mkDefault) baseSettings;

  makeHerdrPackage = {pkgs}:
    inputs.wrapper-modules.lib.evalPackage {
      inherit pkgs settings;
      imports = [herdrModule];
    };
in {
  # Exported so the module itself is reusable (and upstreamable) independently
  # of the settings baked in above.
  flake.wrapperModules.herdr = herdrModule;

  perSystem = {pkgs, ...}: {
    packages.herdr = makeHerdrPackage {inherit pkgs;};
  };
}
