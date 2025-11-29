{pkgs, ...}: {

programs.waybar.settings = {
    mainBar = {
      layer ="top";
      position = "top";
      height = 30;
      modules-left = ["hyprland/wokspaces" "cava"];
      modules-center = ["clock"];
      modules-right = ["pulseaudio/slider" "network" "bluetooth" "battery" "hyprland/language"];
    };
    
};

}
