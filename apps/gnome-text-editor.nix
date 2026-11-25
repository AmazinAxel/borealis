{ config, lib, pkgs, ... }: let
  inherit (config.borealis) user;
  nord = (import ../nord.nix).hex;
in {
  environment.systemPackages = [ pkgs.gnome-text-editor ];
  environment.persistence."/persist".users.${user}.directories = [ ".local/share/org.gnome.TextEditor" ]; # session + unsaved drafts

  home-manager.users.${user} = hm: {
    dconf.settings."org/gnome/TextEditor" = {
      style-scheme = "nord";
      style-variant = "follow"; # system dark/light, scheme swapped via metadata below
      recolor-window = true; # whole window takes the scheme's colors
      spellcheck = true;
      # match site/static/css/cabin.css body: 16px/1.5 Sora (16px = 12pt)
      use-system-font = false;
      custom-font = "Sora 12";
      line-height = 1.5;
      restore-session = true;
      last-save-directory = "file://${hm.config.xdg.userDirs.download}";
    };

    # roles follow https://www.nordtheme.com/docs/colors-and-palettes; Text Editor swaps the pair on
    # system dark/light via light-variant/dark-variant, and recolors its chrome from the *_color metadata
    xdg.dataFile = lib.mapAttrs' (id: s: lib.nameValuePair "gtksourceview-5/styles/${id}.xml" { text = with nord; ''
      <?xml version="1.0" encoding="UTF-8"?>
      <style-scheme id="${id}" name="${s.name}" version="1.0">
        <metadata>
          <property name="variant">${s.variant}</property>
          <property name="${s.otherKey}">${s.other}</property>
          <property name="window_bg_color">${s.bg}</property>
          <property name="window_fg_color">${s.fg}</property>
          <property name="view_bg_color">${s.bg}</property>
          <property name="view_fg_color">${s.fg}</property>
          <property name="headerbar_bg_color">${s.panel}</property>
          <property name="headerbar_fg_color">${s.fg}</property>
          <property name="sidebar_bg_color">${s.panel}</property>
          <property name="sidebar_fg_color">${s.fg}</property>
          <property name="popover_bg_color">${s.panel}</property>
          <property name="popover_fg_color">${s.fg}</property>
          <property name="dialog_bg_color">${s.panel}</property>
          <property name="accent_color">${s.accent}</property>
          <property name="accent_bg_color">${nord10}</property>
          <property name="accent_fg_color">${nord6}</property>
        </metadata>

        <style name="text" foreground="${s.fg}" background="${s.bg}"/>
        <style name="selection" background="${s.sel}"/>
        <style name="selection-unfocused" background="${s.sel}"/>
        <style name="cursor" foreground="${s.fg}"/>
        <style name="secondary-cursor" foreground="${s.accent}"/>
        <style name="current-line" background="${s.line}"/>
        <style name="line-numbers" foreground="${nord3}" background="${s.bg}"/>
        <style name="current-line-number" foreground="${s.fg}" background="${s.line}"/>
        <style name="right-margin" foreground="${nord3}" background="${s.line}"/>
        <style name="background-pattern" background="${s.line}"/>
        <style name="map-overlay" background="${s.sel}"/>
        <style name="snippet-focus" background="${s.sel}"/>
        <style name="bracket-match" foreground="${s.accent}" bold="true"/>
        <style name="bracket-mismatch" foreground="${nord11}" bold="true" underline="error"/>
        <style name="search-match" foreground="${nord0}" background="${nord13}"/>
        <style name="draw-spaces" foreground="${s.dim}"/>

        <style name="def:comment" foreground="${s.comment}" italic="true"/>
        <style name="def:doc-comment-element" foreground="${nord10}" italic="true"/>
        <style name="def:note" foreground="${nord10}" bold="true"/>
        <style name="def:keyword" foreground="${s.keyword}"/>
        <style name="def:statement" foreground="${s.keyword}"/>
        <style name="def:preprocessor" foreground="${nord10}"/>
        <style name="def:type" foreground="${s.type}"/>
        <style name="def:function" foreground="${s.accent}"/>
        <style name="def:builtin" foreground="${s.accent}"/>
        <style name="def:constant" foreground="${s.fg}"/>
        <style name="def:special-constant" foreground="${s.keyword}"/>
        <style name="def:boolean" foreground="${s.keyword}"/>
        <style name="def:string" foreground="${nord14}"/>
        <style name="def:character" foreground="${nord14}"/>
        <style name="def:special-char" foreground="${s.special}"/>
        <style name="def:number" foreground="${nord15}"/>
        <style name="def:error" foreground="${nord11}" underline="error" underline-color="${nord11}"/>
        <style name="def:warning" underline="error" underline-color="${s.special}"/>

        <style name="def:heading" foreground="${s.accent}" bold="true"/>
        ${lib.concatMapStrings (n: ''<style name="def:heading${toString n}" foreground="${s.accent}" bold="true"/>
        '') (lib.range 0 6)}<style name="def:emphasis" italic="true"/>
        <style name="def:strong-emphasis" bold="true"/>
        <style name="def:inline-code" foreground="${s.type}"/>
        <style name="def:preformatted-section" foreground="${s.type}"/>
        <style name="def:link-text" foreground="${s.accent}"/>
        <style name="def:link-symbol" foreground="${s.keyword}"/>
        <style name="def:link-destination" foreground="${nord10}" underline="low"/>
        <style name="def:net-address" foreground="${nord10}" underline="low"/>
        <style name="def:list-marker" foreground="${s.keyword}" bold="true"/>
        <style name="def:thematic-break" foreground="${nord3}" bold="true"/>
        <style name="def:insertion" foreground="${nord14}"/>
        <style name="def:deletion" foreground="${nord11}" strikethrough="true"/>

        <style name="diff:added-line" foreground="${nord14}"/>
        <style name="diff:removed-line" foreground="${nord11}"/>
        <style name="diff:changed-line" foreground="${s.special}"/>
        <style name="diff:location" foreground="${nord15}"/>
        <style name="diff:diff-file" foreground="${s.accent}" bold="true"/>
        <style name="xml:element-name" foreground="${s.keyword}"/>
        <style name="json:keyname" foreground="${s.type}"/>
        <style name="python:decorator" foreground="${nord12}"/>
        <style name="rust:attribute" foreground="${nord12}"/>
        <style name="rust:macro" foreground="${s.accent}"/>
        <style name="c:attribute" foreground="${nord12}"/>
        <style name="vala:attributes" foreground="${nord12}"/>
      </style-scheme>
    ''; }) (with nord; {
      nord = {
        name = "Nord"; variant = "dark"; otherKey = "light-variant"; other = "nord-light";
        fg = nord4; bg = nord0; panel = nord1; line = nord1; sel = nord2; dim = nord3;
        comment = "#616e88"; # nord3 brightened, as Nord's own editor ports do (raw nord3 is ~2:1 on nord0)
        accent = nord8; keyword = nord9; type = nord7; special = nord13;
      };
      nord-light = { # Nord has no official light theme: Snow Storm bg, Polar Night text, pale frost/yellow shifted a step darker
        name = "Nord Light"; variant = "light"; otherKey = "dark-variant"; other = "nord";
        fg = nord0; bg = nord6; panel = nord5; line = nord5; sel = nord4; dim = nord4;
        comment = nord3;
        accent = nord10; keyword = nord10; type = nord9; special = nord12;
      };
    });

    xdg.mimeApps.defaultApplications."text/markdown" = lib.mkForce [ "org.gnome.TextEditor.desktop" ];
  };
}
