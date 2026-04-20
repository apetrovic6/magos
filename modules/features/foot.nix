{self, inputs, ...}: {
 perSystem = { pkgs, ...}: {
  packages.foot = inputs.wrapper-modules.wrappers.foot.wrap {
    inherit pkgs;

    settings = {
      mouse = {
        hide-when-typing = "no";
      };
    };
  };
 };
}
