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

      mkSubmap = {
        mods ? ["ALT"],
        key,
        name,
      }: "${lib.concatStringsSep " " mods}, ${key}, submap, ${name}";

      mkSubmapBind = {
        type ? "bind",
        key,
        action ? "exec",
        cmd,
      }: ''
        bind = , ${key}, exec, ${cmd}
        bind = , ${key}, submap, reset
      '';
    };
  };
}
