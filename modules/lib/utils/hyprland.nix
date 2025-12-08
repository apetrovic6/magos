{...}: {
  flake.lib = {lib, ...}: {
    hyprland = {
      mkSubmapBind = {
        key,
        command,
      }: ''
        bind =  , ${key}, exec, ${command}
        bind = , ${key}, submap, reset
      '';
    };
  };
}
