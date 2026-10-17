{ pkgs, lib, ... }: let
  trim = { name, src, hookDir, keep, ruleset }: pkgs.runCommand "claude-code-${name}" { } ''
    mkdir -p $out/skills
    cp -r ${src}/.claude-plugin $out/
    mkdir -p $out/${hookDir}
    cp -r ${src}/${hookDir}/. $out/${hookDir}/
    ${lib.concatMapStringsSep "\n" (s: "cp -r ${src}/skills/${s} $out/skills/${s}") keep}
    chmod -R u+w $out
    cp ${ruleset} $out/skills/${name}/SKILL.md
    find $out -name '*.json' -exec sed -i 's|"node |"${pkgs.bun}/bin/bun |' {} +
  '';

in {
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    plugins = {
      caveman = trim {
        name = "caveman";
        hookDir = "src/hooks";
        keep = [ "caveman" "caveman-commit" "caveman-review" ];
        ruleset = ./claude/caveman.md;
        src = pkgs.fetchFromGitHub {
          owner = "JuliusBrussee"; repo = "caveman";
          rev = "v2.3.1";
          hash = "sha256-zQJ5fVaEuUjQoboJm9SvStwHI8kmqwyxecOSYvzuVBQ=";
        };
      };
      ponytail = trim {
        name = "ponytail";
        hookDir = "hooks";
        keep = [ "ponytail" "ponytail-review" ];
        ruleset = ./claude/ponytail.md;
        src = pkgs.fetchFromGitHub {
          owner = "DietrichGebert"; repo = "ponytail";
          rev = "v4.9.0";
          hash = "sha256-8cYggVltBAlZ/Zj4pl1bOu7mQdZFXCmDGW4RSpvRA+w=";
        };
      };
    };

    settings = {
      model = "opus";
      effortLevel = "medium";
      theme = "auto";
      tui = "fullscreen";
      skipDangerousModePermissionPrompt = true;
      enabledPlugins."typescript-lsp@claude-plugins-official" = true;

      alwaysThinkingEnabled = false; # think only when the turn needs it
      todoFeatureEnabled = false;
      spinnerTipsEnabled = false;
      includeCoAuthoredBy = false;
      autoCompactEnabled = true; # cheaper than blowing the window
      autoUpdates = false; # the store is read-only
      cleanupPeriodDays = 7; # trim old transcripts

      env = {
        ENABLE_TOOL_SEARCH = "1"; # fetch tool schemas on demand, not up front
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"; # no background model calls
        BASH_MAX_OUTPUT_LENGTH = "12000"; # truncate runaway command output
        MAX_MCP_OUTPUT_TOKENS = "8000";
        DISABLE_TELEMETRY = "1";
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_BUG_COMMAND = "1";
        DISABLE_FEEDBACK_COMMAND = "1";
        DISABLE_COST_WARNINGS = "1";
        DISABLE_AUTOUPDATER = "1";
        DISABLE_INSTALLATION_CHECKS = "1";
        CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
        CAVEMAN_DEFAULT_MODE = "full"; # off|lite|full|ultra
        CAVEMAN_QUIET_STARTUP = "1";
        PONYTAIL_DEFAULT_MODE = "full"; # off|lite|full|ultra
        PONYTAIL_QUIET_STARTUP = "1";
      };

      permissions.deny = [ # never pull these into context
        "Read(**/node_modules/**)"
        "Read(**/.direnv/**)"
        "Read(**/result/**)"
        "Read(**/dist/**)"
        "Read(**/.git/objects/**)"
      ];
    };

    # always in context, so keep it short
    context = ''
      - Answer directly. No preamble, no plan-of-attack, no closing summary.
      - Read only what you need: rg/grep with line numbers, sed -n ranges. Never cat a large file whole.
      - Batch independent tool calls into one block.
      - Never re-read a file to confirm an edit landed.
      - Report a change as file:line and stop. Don't restate the diff.
      - One approach, chosen. Don't survey alternatives unless asked.
      - Ask only when a wrong guess would waste real work.
      - Never run nixos-rebuild or home-manager switch; I build myself.
      - Shell is fish: no bash <(...), use psub or /dev/stdin.
    '';

    skills = {
      answer-directly = ''
        ---
        name: answer-directly
        description: Use when the user asks a question rather than requesting a change - "how does X work", "why is X", "can I", "what's the difference", "is X possible". Not for tasks that edit files.
        ---

        # Answer directly

        - Lead with the answer in the first sentence. Three sentences is usually the whole reply.
        - Point at evidence as `file:line`. Don't paste the code back unless the shape is the answer.
        - One or two targeted reads, then answer. If two reads didn't settle it, say what's unclear and ask.
        - No options table, no trade-off survey, no "would you like me to...".
        - Don't start work the user didn't ask for. A question is not a task.
      '';

      narrow-search = ''
        ---
        name: narrow-search
        description: Use before locating something in a codebase - "where is", "find the", "which file", "does this repo have", or any grep/search sweep across unfamiliar files.
        ---

        # Narrow search

        - `rg -n 'pattern'` first. Add `-l` when you only need filenames, `-c` when you only need counts.
        - Read the hit with `sed -n 'START,ENDp' file`, not the whole file. Widen only if the range was too tight.
        - Cap output: pipe through `head`. A search that returns 200 lines was the wrong search.
        - Prefer one precise pattern over three broad ones. Refine the regex instead of re-reading.
        - Don't spawn a subagent to search a single repo; it re-derives context you already have.
        - Stop at the first hit that answers the question.
      '';

      small-change = ''
        ---
        name: small-change
        description: Use when the user has already specified the change - a fix, rename, config toggle, option addition, or small feature. Not for open-ended design work.
        ---

        # Small change

        - The request is the spec. Implement it; don't plan it first.
        - Touch the fewest lines that do the job. No drive-by refactors, no renames not asked for.
        - Match the surrounding file's style, comment density, and idiom.
        - Edit tools fail loudly, so skip verification reads. Run a build or test only if the user asked or the change is non-obvious.
        - Report in one line: what changed, where. Then stop.
      '';
    };
  };
}
