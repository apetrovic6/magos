{...}: {
  flake.homeModules.walker-ugala = {
    config,
    lib,
    ...
  }: let
    c = config.magos.palette;
  in {
    imports = [
      ../../../theme/palette.nix
    ];

    programs.walker.themes.ugala = {
      style =
        /*
        css
        */
        with c; ''


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
              <?xml version="1.0" encoding="UTF-8"?>
          <interface>
            <requires lib="gtk" version="4.0"/>
            <object class="GtkWindow" id="Window">
              <style><class name="window"/></style>
              <property name="resizable">true</property>
              <property name="title">Walker</property>
              <child>
                <object class="GtkBox" id="BoxWrapper">
                  <style><class name="box-wrapper"/></style>
                  <property name="width-request">644</property>
                  <property name="overflow">hidden</property>
                  <property name="orientation">horizontal</property>
                  <property name="valign">center</property>
                  <property name="halign">center</property>

                  <child>
                    <object class="GtkBox" id="Box">
                      <style><class name="box"/></style>
                      <property name="orientation">vertical</property>
                      <property name="hexpand-set">true</property>
                      <property name="hexpand">true</property>
                      <property name="spacing">10</property>

                      <!-- SEARCH ROW -->
                      <child>
                        <object class="GtkBox" id="SearchContainer">
                          <style><class name="search-container"/></style>
                          <property name="overflow">hidden</property>
                          <property name="orientation">horizontal</property>
                          <property name="halign">fill</property>
                          <property name="hexpand-set">true</property>
                          <property name="hexpand">true</property>
                          <child>
                            <object class="GtkEntry" id="Input">
                              <style><class name="input"/></style>
                              <property name="halign">fill</property>
                              <property name="hexpand-set">true</property>
                              <property name="hexpand">true</property>
                            </object>
                          </child>
                        </object>
                      </child>

                      <!-- CONTENT ROW -->
                      <child>
                        <object class="GtkBox" id="ContentContainer">
                          <style><class name="content-container"/></style>
                          <property name="orientation">horizontal</property>
                          <property name="spacing">10</property>
                          <property name="vexpand">true</property>
                          <property name="vexpand-set">true</property>

                          <!-- LEFT: LIST (with overlays for hint/placeholder) -->
                          <child>
                            <object class="GtkOverlay" id="Overlay">
                              <property name="hexpand">true</property>
                              <property name="vexpand">true</property>

                              <child>
                                <object class="GtkScrolledWindow" id="Scroll">
                                  <style><class name="scroll"/></style>
                                  <property name="hexpand">true</property>
                                  <property name="vexpand">true</property>
                                  <property name="can-focus">false</property>
                                  <property name="overlay-scrolling">true</property>
                                  <!-- Let it grow; don't cap max-content-* -->
                                  <property name="propagate-natural-height">true</property>
                                  <property name="propagate-natural-width">true</property>
                                  <property name="hscrollbar-policy">automatic</property>
                                  <property name="vscrollbar-policy">automatic</property>
                                  <child>
                                    <object class="GtkGridView" id="List">
                                      <style><class name="list"/></style>
                                      <property name="max-columns">1</property>
                                      <property name="can-focus">false</property>
                                      <property name="hexpand">true</property>
                                      <property name="vexpand">true</property>
                                    </object>
                                  </child>
                                </object>
                              </child>

                              <child type="overlay">
                                <object class="GtkLabel" id="ElephantHint">
                                  <style><class name="elephant-hint"/></style>
                                  <property name="halign">center</property>
                                  <property name="valign">center</property>
                                  <property name="label">Waiting for elephant...</property>
                                </object>
                              </child>

                              <child type="overlay">
                                <object class="GtkLabel" id="Placeholder">
                                  <style><class name="placeholder"/></style>
                                  <property name="halign">center</property>
                                  <property name="valign">center</property>
                                  <property name="label">No Results</property>
                                </object>
                              </child>
                            </object>
                          </child>

                          <!-- RIGHT: PREVIEW COLUMN -->
                          <child>
                            <object class="GtkBox" id="Preview">
                              <style><class name="preview"/></style>
                              <property name="hexpand">false</property>
                              <property name="vexpand">true</property>
                              <!-- optional fixed width:
                              <property name="width-request">260</property> -->
                            </object>
                          </child>
                        </object>
                      </child>

                      <!-- ERROR ROW -->
                      <child>
                        <object class="GtkLabel" id="Error">
                          <style><class name="error"/></style>
                          <property name="xalign">0</property>
                          <property name="visible">false</property>
                        </object>
                      </child>
                    </object>
                  </child>

                </object>
              </child>
            </object>
          </interface>
        '';
      };
    };
  };
}
