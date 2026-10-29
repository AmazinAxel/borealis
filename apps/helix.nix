{ borealis, config, pkgs, lib, ... }: let
  inherit (config.borealis) user;
  # perl grammar breaks on glibc 2.44 (bsearch _Generic clash)
  helixPkg = borealis.helix.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    includeGrammarIf = g: g.name != "perl";
  };
in {
  programs = {
    git.config.core.editor = "hx";
    nano.enable = false; # use Helix
  };
  nix.settings = {
    extra-substituters = [ "https://helix.cachix.org" ];
    extra-trusted-public-keys = [ "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=" ];
  };

  home-manager.users.${user} = {
    programs = {
      fish = {
        functions.h = "__cdp_arg $argv[1]; or return; hx .";
        interactiveShellInit = ''complete -c h -f -a "(__proj_dirs)"'';
      };
      helix = {
        enable = true;
        defaultEditor = true;
        package = helixPkg;
        extraPackages = with pkgs; [
          marksman # markdown
          harper # grammar checker
          prettier # formatter
          typescript-language-server # some LSP stuff
          vscode-langservers-extracted # more lSP stuff
        ];
        settings = {
          theme = {
            light = "iceberg-light"; # tokoyonight_day catppuccin_latte solarized-light
            dark = "nord-night";
          };

          editor = {
            middle-click-paste = false;
            scroll-lines = 10; # mouse scroll
            shell = ["fish" "-c"]; # default is bash
            auto-info = true;
            default-line-ending = "lf";
            trim-final-newlines = true; # only trims extra newlines
            trim-trailing-whitespace = true;
            popup-border = "all";
            # clipboard-provider = "termcode";

            statusline = {
              left = ["mode" "file-name" ];
              center = [];
              right = [ "read-only-indicator" "file-modification-indicator" "version-control" ];
            };

            workspace-trust.prompt = false; # this is annoying

            lsp = {
              display-messages = false; # ??
              display-inlay-hints = true;
              inlay-hints-length-limit = 20;
            };
            idle-timeout = 250; # delay while typing
            inline-diagnostics = {
              cursor-line = "error";
              other-lines = "error";
            };
            end-of-line-diagnostics = "error";
            cursor-shape = {
              insert = "bar";
              select = "underline";
            };
            file-picker = {
              hidden = false; # show hidden files
              git-global = false; # not necessary, we dont modify this
              git-exclude = false; # ^
              ignore = false; # ^
            };
            search.smart-case = false; # do NOT be case sensitive no matter what

            indent-guides.render = true;
            gutters = [ "diagnostics" "spacer" "line-numbers" "spacer" "diff" ];
            soft-wrap.enable = true;
          };
          keys = let
            keybinds = {
              C-z = "undo"; # control+Z
              C-S-z = "redo"; # control+shift+Z
              A-tab = "goto_last_accessed_file"; # alt-tab, goto_last_modified_file
              C-tab = "buffer_picker"; # ctrl+tab
              S-tab = "unindent";
              tab = "indent";
              C-s = [ "normal_mode" ":write" ]; # ctrl+S save
              C-v = "paste_clipboard_before";
              C-r = [ ":reload" ]; # reload file
              C-q = [ ":quit" ]; # ctrl+Q quit
              C-left = "move_prev_word_start";
              C-right = "move_next_word_start";
            };
          in {
            normal = keybinds // {
              C-c = "yank_main_selection_to_clipboard";
              c = "toggle_comments";
              space.f = "file_picker_in_current_directory";
              space.F = "file_picker";
              space.m = "@:move <C-r>%<C-w>";
              space.b.n = "goto_next_change";
              space.b.N = "goto_prev_change";
              space.b.r = ":reset-diff-change";
              space.x = [ ":sh rm '%{buffer_name}'"  ":buffer-close!" ];
              space.o = [ ":sh cp '%{buffer_name}' ./"  ":open %sh{basename '%{buffer_name}'}" ];
              C-g = [ ":write-all" ":insert-output lazygit >/dev/tty" ":redraw" ":reload-all" ]; # lazygit
              space.D = [
                ":sh git diff -U99999 HEAD -- %{buffer_name} | sed '1,/^@@/d' > /tmp/hx-diff-show.diff"
                ":vsplit /tmp/hx-diff-show.diff"
              ];
            };
            insert = keybinds // { tab = "insert_tab"; };
            select = keybinds // {
              C-left = "extend_prev_word_start";
              C-right = "extend_next_word_start";
              C-c = "yank_main_selection_to_clipboard";
              c = "toggle_comments";
            };
          };
        };

        languages = {
          language-server.harper-ls = {
            command = "harper-ls";
            args = [ "--stdio" ];
            config.harper-ls.linters = {
              UseTitleCase = false;
              UseEllipsisCharacter = false;
              Excellent = false;
              LongSentences = false;
              DiscourseMarkers = false;
              SplitWords = false;
              ExpandMemoryShorthand = false;
              NumericRangeEnDash = false;
            };
          };
          language = [{
            name = "markdown";
            language-servers = [ "marksman" "harper-ls" ];
            auto-format = true;
            formatter = {
              command = "prettier";
              args = [ "--parser" "markdown" ];
            };
          }];
        };
      };
    };

    xdg.mimeApps.defaultApplications = lib.genAttrs [
      "text/plain"
      "text/markdown"
      "application/json"
      "application/yaml"
      "application/toml"
      "application/x-shellscript"
      "text/x-python"
      "text/javascript"
      "text/vnd.trolltech.linguist" # .ts
      "application/x-tiled-tsx" # .tsx
      "text/x-csrc"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-c++hdr"
      "text/rust"
      "text/x-go"
      "text/x-lua"
      "text/x-log"
      "application/octet-stream" # unknown fallback
    ] (_: "Helix.desktop");
  };
}
