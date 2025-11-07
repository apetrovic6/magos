
{...}: {
  flake.homeModules.walker-ugala = {
    config,
    lib,
    ...
  }: 
let
    c = config.magos.palette;
    in
    {
  
    imports = [
        ../../../theme/palette.nix
    ];


      programs.walker.themes.ugala = {
    style =  /* css */ with c; '' 
                      * {
                  all: unset;
                }

                .normal-icons {
                  -gtk-icon-size: 16px;
                }

                .large-icons {
                  -gtk-icon-size: 32px;
                }

                scrollbar {
                  opacity: 0;
                }

                .box-wrapper {
                  box-shadow:
                    0 19px 38px rgba(0, 0, 0, 0.3),
                    0 15px 12px rgba(0, 0, 0, 0.22);
                  background: alpha(${backgroundDefault}, 0.8);
                  padding: 20px;
                  border-radius: 20px;
                  border: 1px solid alpha(${border}, 0.75);
                }

                .preview-box,
                .elephant-hint,
                .placeholder {
                  color: ${textDefault};
                }

                .box {
                }

                .search-container {
                  border-radius: 10px;
                }

                .input placeholder {
                  opacity: 0.5;
                }

                .input {
                  caret-color: @selected-text;
                  background: darker(${backgroundAlpha50});
                  padding: 10px;
                }

                .input:focus,
                .input:active {
                }

                .content-container {
                }

                .placeholder {
                }

                .scroll {
                }

                .list {
                  color: ${textDefault};
                }

                child {
                }

                .item-box {
                  border-radius: 10px;
                  padding: 10px;
                }

                .item-quick-activation {
                  margin-left: 10px;
                  background: alpha(${background}, 0.25);
                  border-radius: 5px;
                  padding: 10px;
                }

                child:hover .item-box,
                child:selected .item-box {
                  background: darker(alpha(${backgroundDefault}, 0.5));
                }

                .item-text-box {
                }

                .item-text {
                }

                .item-subtext {
                  font-size: 12px;
                  opacity: 0.5;
                }

                .item-image,
                .item-image-text {
                  margin-right: 10px;
                }

                .item-image-text {
                  font-size: 28px;
                }

                .preview {
                  border: 1px solid alpha(${border}, 0.25);
                  padding: 10px;
                  border-radius: 10px;
                  color: ${foreground};
                }

                .calc .item-text {
                  font-size: 24px;
                }

                .calc .item-subtext {
                }

                .symbols .item-image {
                  font-size: 24px;
                }

                .todo.done .item-text-box {
                  opacity: 0.25;
                }

                .todo.urgent {
                  font-size: 24px;
                }

                .todo.active {
                  font-weight: bold;
                }

                .bluetooth.disconnected {
                  opacity: 0.5;
                }

                .preview .large-icons {
                  -gtk-icon-size: 64px;
                }

                .keybinds-wrapper {
                  border-top: 1px solid darker(${border});
                  font-size: 12px;
                  opacity: 0.5;
                  color: #${backgroundDefault};
                }

                .keybinds {
                }

                .keybind {
                }

                .keybind-bind {
                  color: lighter(${textAlternate});
                  font-weight: bold;
                }

                .keybind-label {
                }

          '';


            # Check out the default layouts for examples https://github.com/abenz1267/walker/tree/master/resources/themes/default
            layouts = {
              "layout" = ''
               <object class="GtkScrolledWindow" id="Scroll">
  <style><class name="scroll"></class></style>
  <property name="hexpand">true</property>
  <property name="vexpand">true</property>          <!-- added -->
  <property name="vexpand-set">true</property>      <!-- added -->
  <property name="can-focus">false</property>       <!-- was can_focus -->
  <property name="overlay-scrolling">true</property>
  <property name="max-content-width">600</property>
  <property name="max-content-height">300</property>
  <property name="min-content-height">0</property>
  <property name="propagate-natural-height">true</property>
  <property name="propagate-natural-width">true</property>
  <property name="hscrollbar-policy">automatic</property>
  <property name="vscrollbar-policy">automatic</property>
  <child>
    <object class="GtkGridView" id="List">
      <style><class name="list"></class></style>
      <property name="max-columns">1</property>     <!-- was max_columns -->
      <property name="can-focus">false</property>   <!-- was can_focus -->
      <property name="hexpand">true</property>      <!-- optional but helpful -->
      <property name="vexpand">true</property>      <!-- optional but helpful -->
    </object>
  </child>
</object>              '';
            };

      };
  };
}
