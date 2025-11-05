
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
    nix.settings = {
      extra-substituters = ["https://walker.cachix.org" "https://walker-git.cachix.org"];
      extra-trusted-public-keys = ["walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM=" "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="];
    };


        programs.walker = {
          
      };
  };
};
}
