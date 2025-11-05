{ inputs, ... }:{
flake.nixosModules.core.cowsay = {config, lib, pkgs, ... }:
let
  cfg = config.magos.core.cowsay;
in
{
  options.magos.core.cowsay.enable = lib.mkEnableOption "Install cowsay for testing";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.cowsay ];
  };
};
}
