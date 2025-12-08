{...}: {
  flake.lib.hyprland = {pkgs, ...}:{
      mkWebapp = url: browser ? pkgs.brave: "${getExe browser} --profile-directory=\"Web Apps\" --app=${url}";
  };
}
