{inputs, ...}: let
  base16ToMaterial = colors: {
    mSurface = "#${colors.base00}";
    mSurfaceVariant = "#${colors.base01}";
    mOnSurface = "#${colors.base05}";
    mOnSurfaceVariant = "#${colors.base04}";
    mPrimary = "#${colors.base0D}";
    mOnPrimary = "#${colors.base00}";
    mSecondary = "#${colors.base0E}";
    mOnSecondary = "#${colors.base00}";
    mTertiary = "#${colors.base0C}";
    mOnTertiary = "#${colors.base00}";
    mError = "#${colors.base08}";
    mOnError = "#${colors.base00}";
    mOutline = "#${colors.base02}";
    mShadow = "#000000";
  };
in {
  flake.lib = {
    colors = {
      everforest-dark-soft = {
        base00 = "333c43";
        base01 = "3a464c";
        base02 = "4d5960";
        base03 = "859289";
        base04 = "9da9a0";
        base05 = "d3c6aa";
        base06 = "ddd8be";
        base07 = "f3ead3";
        base08 = "e67e80";
        base09 = "e69875";
        base0A = "dbbc7f";
        base0B = "a7c080";
        base0C = "83c092";
        base0D = "7fbbb3";
        base0E = "d699b6";
        base0F = "9da9a0";
      };
    };

    inherit base16ToMaterial;

    makeNoctaliaPackage = {
      pkgs,
      colors,
      wallpaper ? null,
    }: let
      noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

      configDir = pkgs.runCommand "noctalia-config" {} ''
        mkdir -p $out/noctalia/palettes
        cp ${pkgs.writeText "custom.json" (builtins.toJSON (base16ToMaterial colors))} $out/noctalia/palettes/custom.json
        cp ${pkgs.writeText "noctalia.toml" ''
          [bar.default]
          position = "top"
          auto_hide = true
          reserve_space = false
          layer = "top"
          margin_edge = "3px"

          [wallpaper]
          enabled = false

          [widget.network]
          show_label = false

          [theme]
          mode = "dark"
          source = "custom"
          builtin = "Gruvbox"
          community_palette = "Everforest"
          custom_palette = "custom"
          
          
          [dock]
          enabled = false

          [launcher]
          enabled = true

          [lockscreen]
          enabled = true
          ${if wallpaper != null then ''wallpaper = "${wallpaper}"'' else ""}
        ''} $out/noctalia/noctalia.toml
      '';
    in
      pkgs.symlinkJoin {
        name = "noctalia";
        paths = [noctaliaPkg];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/noctalia \
            --set NOCTALIA_CONFIG_HOME "${configDir}" \
            --run 'mkdir -p "$HOME/.local/state/noctalia" && touch "$HOME/.local/state/noctalia/.setup-complete"'
        '';
      };
  };
}
