{...}: {
  flake.homeModules.hyprland-media = {
    config,
    lib,
    ...
  }: {
    # Hyprland binds that *trigger* Hyprpanel's OSD by changing system state.
    wayland.windowManager.hyprland.settings = {
      # Volume
      bindeld = [
        # Volume
        ",XF86AudioRaiseVolume,Vol up,exec, pctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume,Vol down,exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute,Mute,exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute,Mute mic,exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        # Precise 1%
        "ALT,XF86AudioRaiseVolume,Vol +1,exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+"
        "ALT,XF86AudioLowerVolume,Vol -1,exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"
        "ALT,XF86MonBrightnessUp,Brightness +1,exec, brightnessctl set +1%"
        "ALT,XF86MonBrightnessDown,Brightness -1,exec, brightnessctl set 1%-"

        # Media keys (no OSD needed)
        ",XF86AudioNext,Next,exec, playerctl next"
        ",XF86AudioPause,Play/Pause,exec, playerctl play-pause"
        ",XF86AudioPlay,Play/Pause,exec,  playerctl play-pause"
        ",XF86AudioPrev,Prev,exec, playerctl previous"

        # Your custom output switch
        "SUPER,XF86AudioMute,Switch output,exec, omarchy-cmd-audio-switch"

        # Brightness
        ",XF86MonBrightnessUp,Brightness up,exec, brightnessctl -d intel_backlight set 5%+"
        ",XF86MonBrightnessDown,Brightness down,exec, rightnessctl -d intel_backlight set 5%-"
      ];
    };
  };
}
