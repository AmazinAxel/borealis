{ borealis, config, pkgs, ... }: let
  inherit (config.borealis) user;
in {
  environment.sessionVariables.MOZ_DBUS_REMOTE = "1"; # fix zen screensharing
  environment.persistence."/persist".users.${user}.directories = [ ".config/zen" ];

  home-manager.users.${user} = {
    imports = [ borealis.zen-browser.homeModules.beta ];

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;
      nativeMessagingHosts = [ pkgs.passff-host ]; # pass store integration
      policies.ExtensionSettings."addon@darkreader.org" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
        installation_mode = "force_installed";
      };

      profiles.default = {
        settings = { # Other settings are managed by Mozilla settings sync
          "mousewheel.min_line_scroll_amount" = 50;

          # middle mouse fixes
          "middlemouse.paste" = false;
          "middlemouse.contentLoadURL" = false;
          "toolkit.tabbox.switchByScrolling" = true;

          "zen.view.compact.hide-toolbar" = true;
          "zen.view.compact.toolbar-hide-after-hover.duration" = 500;
          "zen.watermark.enabled" = false;
          "zen.urlbar.wait-to-clear" = 5000;
          "zen.urlbar.replace-newtab" = true; # open new tab page
          "zen.workspaces.show-workspace-indicator" = false;

          # hide new tab clutter
          "browser.newtabpage.activity-stream.feeds.system.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.system.topstories" = false;

          # MOD THEMING
          "uc.essentials.width" = "Normal"; # thin normal wide
          "uc.essentials.gap" = "Normal"; # small normal big
          "uc.essentials.same-height" = true;
          "uc.superpins.border" = "pins";
          "uc.remove-sidebar-scrollbar" = true;
          "uc.tabs.show-separator" = "never";
          "uc.tabs.dim-type" = "both";
          "uc.pinned.height" = "small";
          "uc.favicon.size" = "large";
          "uc.workspace.icon.size" = "large";
          "uc.workspace.current.icon.size" = "large";

          "theme.better_find_bar.transparent_background" = true;
          "theme-better_find_bar-hide_match_case" = "hide_immediately";
          "theme-better_find_bar-hide_match_diacritics" = "hide_immediately";
          "theme-better_find_bar-hide_whole_words" = "hide_immediately";
          "theme.better_find_bar.hide_find_status" = true;

          "uc.fixcontext.ergonomicsfortabs" = true;
          "uc.hidecontext.separators" = true;
          "uc.hidecontext.icons" = true;
          "uc.fixcontext.applyzenaccent" = true;
          "uc.hidecontext.copylink" = true;
          "uc.hidecontext.bookmark" = true;
          "uc.hidecontext.mutetab" = true;
          "uc.hidecontext.newcontainer" = true;
          "uc.hidecontext.sendtodevice" = true;
          "uc.hidecontext.closetab" = true;
          "uc.hidecontext.askchatbot" = true;
          "uc.hidecontext.search" = true;
          "uc.hidecontext.searchinpriv" = true;
          "uc.hidecontext.translate" = true;
          "uc.hidecontext.printselection" = true;
          "uc.hidecontext.image" = true;
          "uc.hidecontext.audiovideo" = true;
          "uc.hidecontext.checkspelling" = true;
          "uc.hidecontext.selectalltext" = true;
          "uc.hidecontext.reloadtab" = true;
          "uc.hidecontext.duplicatetab" = true;
          "uc.hidecontext.savelink" = true;
          "uc.hidecontext.screenshot" = true;
          "uc.hidecontext.navigation" = true;
        };

        search = {
          default = "bing";
          force = true;
          engines = {
            "MyNixOS" = {
              urls = [{
                template = "https://mynixos.com/search";
                params = [{ name = "q"; value = "{searchTerms}"; }];
              }];
              definedAliases = [ "@nix" ];
              icon = "https://mynixos.com/favicon.ico";
              updateInterval = 24 * 60 * 60 * 1000;
            };
          };
        };

        mods = [
          "ad97bb70-0066-4e42-9b5f-173a5e42c6fc" # better pins/essentials
          "a6335949-4465-4b71-926c-4a52d34bc9c0" # better find bar
          "81fcd6b3-f014-4796-988f-6c3cb3874db8" # declutter context menu
          "c6813222-6571-4ba6-8faf-58f3343324f6" # remove rounded corners
          "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # better active tab highlight
          "e51b85e6-cef5-45d4-9fff-6986637974e1" # smaller toast
        ];
      };
    };

    xdg.mimeApps.defaultApplications."application/pdf" = "zen-beta.desktop";
    wayland.windowManager.sway.config = {
      keybindings."Mod4+E" = "exec zen-beta";
      window.commands = [{
        criteria = { app_id = "zen-beta"; title = ".*PassFF.*"; }; # PassFF popup
        command = "floating enable";
      }];
    };
  };
}
