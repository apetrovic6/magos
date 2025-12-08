{...}: {
  flake.homeModules.hyprland-tiling = {
    config,
    lib,
    ...
  }: let
    modifier = "SUPER";
  in {
    wayland.windowManager.hyprland.settings = {
      bindd =
        [
          # Close windows
          "${modifier}, W, Close window, killactive,"

          # Control tiling
          "${modifier}, J, Toggle window split, togglesplit,"
          "${modifier}, P, Pseudo window, pseudo,"
          "${modifier}, T, Toggle window floating/tiling, togglefloating,"
          "${modifier} ALT, F, Full screen, fullscreen, 0"
          "${modifier} CTRL, F, Tiled full screen, fullscreenstate, 0 2"
          "${modifier} ALT, F, Full width, fullscreen, 1"

          # Move focus with ${modifier} + arrow keys
          "${modifier}, LEFT, Move window focus left, movefocus, l"
          "${modifier}, RIGHT, Move window focus right, movefocus, r"
          "${modifier}, UP, Move window focus up, movefocus, u"
          "${modifier}, DOWN, Move window focus down, movefocus, d"

          # Control scratchpad
          "${modifier}, S, Toggle scratchpad, togglespecialworkspace, scratchpad"
          "${modifier} ALT, S, Move window to scratchpad, movetoworkspacesilent, special:scratchpad"

          # TAB between workspaces
          "${modifier}, TAB, Next workspace, workspace, e+1"
          "${modifier} SHIFT, TAB, Previous workspace, workspace, e-1"
          "${modifier} CTRL, TAB, Former workspace, workspace, previous"

          # Swap active window with the one next to it with ${modifier} + SHIFT + arrows
          "${modifier} SHIFT, LEFT, Swap window to the left, swapwindow, l"
          "${modifier} SHIFT, RIGHT, Swap window to the right, swapwindow, r"
          "${modifier} SHIFT, UP, Swap window up, swapwindow, u"
          "${modifier} SHIFT, DOWN, Swap window down, swapwindow, d"

          # Cycle through applications on active workspace
          "ALT, TAB, Cycle to next window, cyclenext"
          "ALT SHIFT, TAB, Cycle to prev window, cyclenext, prev"
          "ALT, TAB, Reveal active window on top, bringactivetotop"
          "ALT SHIFT, TAB, Reveal active window on top, bringactivetotop"

          # Resize active window
          "${modifier} ALT, left, Expand window left, resizeactive, -100 0"
          "${modifier} ALT, right, Shrink window left, resizeactive, 100 0"
          "${modifier} ALT, up, Shrink window up, resizeactive, 0 -100"
          "${modifier} ALT, down,Expand window down, resizeactive, 0 100"

          # Scroll through existing workspaces with ${modifier} + scroll
          "${modifier}, mouse_down, Scroll active workspace forward, workspace, e+1"
          "${modifier}, mouse_up, Scroll active workspace backward, workspace, e-1"

          # Toggle groups
          "${modifier} SHIFT, G, Toggle window grouping, togglegroup"
          "${modifier} ALT, G, Move active window out of group, moveoutofgroup"

          # Join groups
          "${modifier} ALT, LEFT, Move window to group on left, moveintogroup, l"
          "${modifier} ALT, RIGHT, Move window to group on right, moveintogroup, r"
          "${modifier} ALT, UP, Move window to group on top, moveintogroup, u"
          "${modifier} ALT, DOWN, Move window to group on bottom, moveintogroup, d"

          # Navigate a single set of grouped windows
          "${modifier} ALT, TAB, Next window in group, changegroupactive, f"
          "${modifier} ALT SHIFT, TAB, Previous window in group, changegroupactive, b"

          # Scroll through a set of grouped windows with ${modifier} + ALT + scroll
          "${modifier} ALT, mouse_down, Next window in group, changegroupactive, f"
          "${modifier} ALT, mouse_up, Previous window in group, changegroupactive, b"
        ]
        ++ lib.concatMap (
          x: let
            toCode = i: 9 + i;
          in
            [
              # Switch workspaces with SUPER + [1-9]
              "${modifier}, code:${toString (toCode x)}, Switch to workspace ${toString x}, workspace, ${toString x}"

              # Move active window to a workspace with SUPER + SHIFT + [1-9]
              "${modifier} SHIFT, code:${toString (toCode x)}, Move window to workspace ${toString x}, movetoworkspace, ${toString x}"
            ]
            ++ lib.optional (x <= 5)
            # Activate window in a group by number
            "${modifier} ALT, ${toString x},  Switch to group window ${toString x}, changegroupactive, ${toString x}"
        ) (lib.range 1 9);

      bindmd = [
        "${modifier}, mouse:272, Move window, movewindow"
        "${modifier}, mouse:273, Resize window, resizewindow"
      ];
    };
  };
}
