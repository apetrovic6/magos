{self, ...}: let
  defaultTheme = self.lib.colors.everforest-dark-soft;
in {
  perSystem = {pkgs, ...}: {
    packages.noctalia = self.lib.makeNoctaliaPackage {inherit pkgs; colors = defaultTheme;};
  };
}
