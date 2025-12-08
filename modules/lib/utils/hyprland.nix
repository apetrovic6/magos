{lib, ...}: {
  flake.lib = {
    hyprland = {
      mkBind = {
        mods ? ["SUPER"],
        key,
        desc ? "",
        cmd,
      }: ''
        ${lib.concatStringsSep " " mods}, ${key}, ${desc},  exec, ${cmd}
      '';
      mkSubmapBind = {
        key,
        cmd,
      }: ''
        bind = , ${key}, exec, ${cmd}
        bind = , ${key}, submap, reset
      '';
    };
  };
}
