{ config, pkgs, ... }: let
  inherit (config.borealis) user;
in {
  environment.persistence."/persist".users.${user}.directories = [
    ".config/Code"
    ".vscode-shared" # logins and recents
    ".vscode" # password store
  ];

  home-manager.users.${user}.programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        arcticicestudio.nord-visual-studio-code
        jnoortheen.nix-ide
        mechatroner.rainbow-csv
        davidanson.vscode-markdownlint # .md lint & spellcheck
        yzhang.markdown-all-in-one # .md keybinds, preview support
        github.vscode-github-actions
        dbaeumer.vscode-eslint
        ms-vscode.live-server
        ms-vscode-remote.remote-ssh
        svelte.svelte-vscode
        ms-vsliveshare.vsliveshare
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
        name = "Sk-VSC";
        publisher = "ayhamalali";
        version = "2.6.6";
        sha256 = "sha256-hTMSi3UTbum+mht9ELWReAX8V5/s61/f7iFEj70xj7Q";
      } {
        name = "vscode-nbt";
        publisher = "Misodee";
        version = "0.9.3";
        sha256 = "sha256-47AO385wHsiMquXX6YvhWbCkjOENzB4DECgwMCpeSv4";
      } {
        name = "nord-light";
        publisher = "huytd";
        version = "0.1.1";
        sha256 = "sha256-q2GG3j5j3CLGF02J7/plywKLkhUmm2Gn3MiSVmiZ+48=";
      }];

      userSettings = {
        security.workspace.trust.enabled = false; # trust everything
        editor = {
          wordWrap = "on";
          fontFamily = "'Iosevka Nerd Font Mono'";
          fontLigatures = "'calt'"; # Iosevka ligatures
          minimap.enabled = false;
        };
        explorer = {
          confirmDelete = false;
          confirmDragAndDrop = false; # No drag & drop popup
          confirmPasteNative = false; # No image paste popup
        };
        git = {
          enableSmartCommit = true;
          confirmSync = false;
          autofetch = false;
        };
        workbench = {
          startupEditor = "none";
          colorTheme = "Nord"; # default
          preferredDarkColorTheme = "Nord";
          preferredLightColorTheme = "Nord Light";
          experimental.modernUI =  false;
        };
        window.autoDetectColorScheme = true; # Follow system
        chat.disableAIFeatures = true;
        terminal.integrated = {
          defaultProfile.linux = "fish";
          profiles.linux.fish = {
            path = "fish";
            icon = "terminal-bash";
          };
        };
        update.mode = "none";
        svelte.enable-ts-plugin = true; # Svelte TS intellisense
        window.titleBarStyle = "custom"; # Fix Wayland bug
        javascript.updateImportsOnFileMove.enabled = "always";
        typescript.updateImportsOnFileMove.enabled = "always";
        diffEditor.ignoreTrimWhitespace = false; # Keep diff viewer clean
        markdownlint.focusMode = 5; # Don't show nearby Markdown warnings when typing
        "claudeCode.preferredLocation" = "panel"; # do not unwrap quotes
      };
    };
  };
}
