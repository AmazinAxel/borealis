{ config, lib, pkgs, ... }: let
  inherit (config.borealis) user;
  nord = (import ../nord.nix).hex;
in {
  environment.systemPackages = [ pkgs.gnome-text-editor ];
  environment.persistence."/persist".users.${user}.directories = [ ".local/share/org.gnome.TextEditor" ]; # session + unsaved drafts

  home-manager.users.${user} = hm: {
    dconf.settings."org/gnome/TextEditor" = {
      style-scheme = "nord";
      style-variant = "dark";
      recolor-window = true; # whole window takes the scheme's colors
      spellcheck = true;
      # match site/static/css/cabin.css body: 16px/1.5 Sora (16px = 12pt)
      use-system-font = false;
      custom-font = "Sora 12";
      line-height = 1.5;
      restore-session = true;
      last-save-directory = "file://${hm.config.xdg.userDirs.download}";
    };

    xdg.dataFile."gtksourceview-5/styles/nord.xml".text = with nord; ''
      <?xml version="1.0" encoding="UTF-8"?>
      <style-scheme id="nord" name="Nord" version="1.0">
        <metadata>
          <property name="variant">dark</property>
          <property name="accent_color">${nord8}</property>
          <property name="accent_bg_color">${nord10}</property>
          <property name="accent_fg_color">${nord6}</property>
        </metadata>

        <style name="text" foreground="${nord4}" background="${nord0}"/>
        <style name="selection" background="${nord2}"/>
        <style name="cursor" foreground="${nord4}"/>
        <style name="current-line" background="${nord1}"/>
        <style name="line-numbers" foreground="${nord3}" background="${nord0}"/>
        <style name="current-line-number" foreground="${nord4}" background="${nord1}"/>
        <style name="right-margin" foreground="${nord3}" background="${nord1}"/>
        <style name="bracket-match" foreground="${nord8}" bold="true"/>
        <style name="search-match" foreground="${nord0}" background="${nord13}"/>
        <style name="draw-spaces" foreground="${nord3}"/>

        <style name="def:comment" foreground="${nord3}" italic="true"/>
        <style name="def:keyword" foreground="${nord9}"/>
        <style name="def:statement" foreground="${nord9}"/>
        <style name="def:preprocessor" foreground="${nord9}"/>
        <style name="def:type" foreground="${nord7}"/>
        <style name="def:function" foreground="${nord8}"/>
        <style name="def:string" foreground="${nord14}"/>
        <style name="def:special-char" foreground="${nord13}"/>
        <style name="def:constant" foreground="${nord15}"/>
        <style name="def:number" foreground="${nord15}"/>
        <style name="def:boolean" foreground="${nord9}"/>
        <style name="def:error" foreground="${nord11}" underline="error"/>
        <style name="def:note" foreground="${nord13}" bold="true"/>

        <style name="def:heading" foreground="${nord8}" bold="true"/>
        <style name="def:emphasis" italic="true"/>
        <style name="def:strong-emphasis" bold="true"/>
        <style name="def:link-text" foreground="${nord8}"/>
        <style name="def:url" foreground="${nord10}" underline="single"/>
        <style name="def:net-address" foreground="${nord10}" underline="single"/>
        <style name="def:preformatted-section" foreground="${nord14}"/>
        <style name="def:list-marker" foreground="${nord9}" bold="true"/>
        <style name="def:insertion" foreground="${nord14}"/>
        <style name="def:deletion" foreground="${nord11}"/>
      </style-scheme>
    '';

    xdg.mimeApps.defaultApplications."text/markdown" = lib.mkForce [ "org.gnome.TextEditor.desktop" ];
  };
}
