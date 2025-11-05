{ lib, pkgs, config, ... }:
let
  cfg = config.magos.cowsay;
in
{
  options.magos.cowsay.enable = lib.mkEnableOption "Install cowsay for testing";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.cowsay ];
  };
}
