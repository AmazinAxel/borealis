{ pkgs, lib, ... }: let
  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      export LC_ALL=C.UTF-8

      IFS=$'\t' read -r sid vim ms add del s w sr wr cache ctx < <(jq -r '[
        (.session_id // "-"),
        (.vim.mode // "-"), (.cost.total_api_duration_ms // 0 | floor),
        (.cost.total_lines_added // 0), (.cost.total_lines_removed // 0),
        (.rate_limits.five_hour.used_percentage // -1 | floor),
        (.rate_limits.seven_day.used_percentage // -1 | floor),
        (.rate_limits.five_hour.resets_at // 0 | floor),
        (.rate_limits.seven_day.resets_at // 0 | floor),
        (.context_window.current_usage.cache_read_input_tokens // -1),
        (.context_window.used_percentage // 0 | floor)
      ] | @tsv')

      # limits only update on this session's replies; a change here is the freshest, so share it
      f=''${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline
      p=''${XDG_RUNTIME_DIR:-/tmp}/claude-statusline-$sid
      read -r last 2>/dev/null <"$p" || last=""
      if [[ "$s $w $sr $wr" != "$last" ]]; then
        echo "$s $w $sr $wr" >"$p"
        (( s >= 0 || w >= 0 )) && echo "$s $w $sr $wr" >"$f"
      fi
      read -r s w sr wr 2>/dev/null <"$f" || true
      printf -v now '%(%s)T' -1

      r=$'\e[0m'
      dim=$'\e[90m' fg=$'\e[39m' frost=$'\e[36m'
      green=$'\e[32m' red=$'\e[31m'

      # from $4% the time until the window resets is drawn over the bar
      bar() {
        local p=$1 w=$2 t=$(( $3 - now )) n txt="" o b
        n=$(( (p * w + 50) / 100 )); (( n > w )) && n=$w
        if (( p >= $4 && t > 0 )); then
          if (( t >= 86400 )); then txt="$(( t / 86400 ))d$(( t % 86400 / 3600 ))h"
          elif (( t >= 3600 )); then txt="$(( t / 3600 ))h$(( t % 3600 / 60 ))m"
          else txt="$(( t / 60 + 1 ))m"; fi
          (( ''${#txt} > w )) && txt=""
        fi
        o=$(( (w - ''${#txt}) / 2 ))
        printf -v b '%*s%s%*s' $o "" "$txt" $(( w - o - ''${#txt} )) ""
        right+=$'\e[1;37;44m'"''${b:0:n}"$'\e[100m'"''${b:n}$r$fg $p% "
        (( rw += w + 3 + ''${#p} ))
      }

      sec=$(( ms / 1000 ))
      if (( sec >= 3600 )); then printf -v dur '%dh%02dm' $(( sec / 3600 )) $(( sec % 3600 / 60 ))
      elif (( sec >= 60 )); then dur="$(( sec / 60 ))m$(( sec % 60 ))s"
      else dur="''${sec}s"; fi

      case $vim in
        INSERT) mode="''${green}INS " ;;
        NORMAL) mode="''${frost}NOR " ;;
        *) mode="" ;;
      esac
      # cache is -1 before the first reply
      if (( cache == 0 )); then mode+=$'\e[1;31m[!]\e[22m '
      elif (( ctx >= 60 )); then mode+=$'\e[1;33m[!]\e[22m '; fi

      left="''${mode}''${fg}''${dur} ''${green}+''${add}''${dim}/''${red}-''${del}"
      shopt -s extglob
      l=''${left//$'\e'\[*([0-9;])m/}

      size=""; [[ ''${COLUMNS:-} && ''${LINES:-} ]] || size=$({ stty size </dev/tty; } 2>/dev/null) || true
      rows=''${LINES:-''${size% *}} cols=''${COLUMNS:-''${size#* }}
      (( ''${rows:-99} < 20 )) && exit 0
      cols=$(( ''${cols:-80} - 4 )) # room Claude keeps around the line

      # bars under 1% are hidden; weekly is dropped first when space runs out
      pct=() rst=() thr=()
      (( s >= 1 )) && pct+=("$s") rst+=("$sr") thr+=(50)
      (( w >= 1 )) && pct+=("$w") rst+=("$wr") thr+=(80)

      # sets k bars of width bw that fit $1 columns; fails if none fit
      fit() {
        local sum i
        for (( k = ''${#pct[@]}; k > 0; k-- )); do
          sum=0; for (( i = 0; i < k; i++ )); do (( sum += 3 + ''${#pct[i]} )); done
          bw=$(( ($1 - 2 - sum) / k ))
          (( bw >= (k > 1 ? 6 : 3) )) && { (( bw > 16 )) && bw=16; return 0; }
        done
        (( ''${#pct[@]} == 0 ))
      }

      sep="  "
      fit $(( cols - ''${#l} - 2 )) || { sep=$'\n'; fit "$cols" || k=0; }
      right="" rw=0
      for (( i = 0; i < k; i++ )); do bar "''${pct[i]}" "$bw" "''${rst[i]}" "''${thr[i]}"; done
      right="''${right% }$r"; (( rw && rw-- ))

      if [[ $sep == "  " ]]; then
        printf '%s%*s%s' "$left" $(( cols - ''${#l} - rw )) "" "$right"
      else
        printf '%s\n%*s%s' "$left$r" $(( cols - rw )) "" "$right"
      fi
    '';
  };

in {
  programs.claude-code = {
    enable = true;
    settings = {
      model = "opus";
      effortLevel = "medium";
      outputStyle = "terse";
      theme = "auto";
      tui = "fullscreen";
      skipDangerousModePermissionPrompt = true;
      disableClaudeAiConnectors = true;

      alwaysThinkingEnabled = false; # think only when the turn needs it
      todoFeatureEnabled = false;
      spinnerTipsEnabled = false;
      promptSuggestionEnabled = false; # no model call per turn for ghost-text
      awaySummaryEnabled = false; # no recap call after idling
      autoDreamEnabled = false; # no background memory consolidation
      precomputeCompactionEnabled = false; # summarize only when compacting
      disableAgentView = true; # no background daemon
      prefersReducedMotion = true;
      showTurnDuration = false;
      emojiCompletionEnabled = false;
      feedbackSurveyRate = 0;
      attribution = { commit = ""; pr = ""; sessionUrl = false; };
      statusLine = {
        type = "command";
        command = lib.getExe statusline;
        padding = 0;
        refreshInterval = 2; # redraw on resize
        hideVimModeIndicator = true; # shown in the line
      };
      preferredNotifChannel = "ghostty"; # foot notifies when unfocused
      autoCompactEnabled = true; # cheaper than blowing the window
      autoUpdates = false; # the store is read-only
      cleanupPeriodDays = 7; # trim old transcripts

      env = {
        ENABLE_TOOL_SEARCH = "1"; # fetch tool schemas on demand, not up front
        # CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"; # no background model calls
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
      };

      hooks.UserPromptSubmit = [{
        # re-sent every turn, so it stays recent in long sessions where the system prompt fades
        hooks = [{ type = "command"; command = "echo 'Caveman: ≤3 lines prose, fragments, no headers/recaps. Big task = same cap. Mid-turn: silent, or 1 fragment on a real finding.'"; }];
      }];

      permissions.deny = [ # never pull these into context
        "Read(**/node_modules/**)"
        "Read(**/.direnv/**)"
        "Read(**/result/**)"
        "Read(**/dist/**)"
        "Read(**/.git/objects/**)"
      ];
    };

    # lives in the cached system prompt, so it costs once per session
    outputStyles.terse = ''
      ---
      name: terse
      description: Short, direct, token-frugal replies
      keep-coding-instructions: true
      ---

      # Terse

      Replies:
      - HARD CAP: 3 lines of prose. More only if user asks for detail. Code blocks don't count.
      - Banned: headers, bold, numbered lists, "why" explanations, alternatives not chosen, restating what user said.
      - Talk caveman. Drop articles, filler, pleasantries, hedges, pronouns where clear. Fragments. Example: "Fixed. Cache check wrong var, claude.nix:60."
      - Answer first. No preamble, recap, or closing offer.
      - Code, error text, numbers, paths, technical terms stay exact; caveman only in prose.
      - A question gets an answer, not work: 1-2 fragments, cite file:line, don't paste code back.
      - A change gets one line: what changed, file:line. Don't restate the diff.
      - Never assume. Request ambiguous (meaning, scope, behavior, edge case, which option) → ask before acting. Use AskUserQuestion, short options.
      - Facts readable in code/files: look, don't ask. Only user intent gets asked.
      - Intent clear → one approach, no option surveys.
      - No text between tool calls. Speak only in final reply.
      - "User hasn't heard from you" reminders: one fragment, only for a finding or plan change. Otherwise stay silent.
      - Long or multi-repo task: same 3-line cap. List outcomes, not process. Skip verified details, test counts, what wasn't committed unless it matters.

      Examples:
      Q: why ags not start?
      Bad: "## Cause\nThe issue is that **ags** fails because... Here are a few options: 1. ... 2. ... Want me to fix it?"
      Good: "Missing gtk4-layer-shell in buildInputs, ags/default.nix:12. Fix?"
      Q: add btop
      Good: "Added btop, home-manager/packages.nix:40."
      Q: (after long multi-file task)
      Bad: three paragraphs of what was done and how it was verified.
      Good: "Done. Data tags in madrone, Permafrost uses them. Found+fixed strict worlds never saving, EffSecCreateInstance.java:349. Push?"

      Work:
      - Smallest change that works. Match the file's style; no unrequested refactors, abstractions or comments.
      - Search narrow: rg -n, read ranges with sed -n, cap with head. Stop at the first answer.
      - Batch independent tool calls. Never re-read a file to check an edit.
      - Change files with Edit/Write only, never sed/awk/heredoc/redirects in Bash.
      - No subagents unless asked. Think hard only when the problem needs it.
    '';

    skills.optimize = ''
      ---
      name: optimize
      description: Whole-project optimization and cleanup pass
      disable-model-invocation: true
      ---

      Thorough optimization + cleanup of the entire project in the current directory. Goal: fastest, leanest, most responsive result with zero bloat.

      1. Map: read the project's CLAUDE.md/README/build files, then every source/config file. Identify language, runtime, target constraints (memory, CPU, startup, binary size, latency) and how to build/test/typecheck.
      2. Audit everything, file by file:
         - Performance: hot paths, startup cost, blocking/sync work, redundant computation, polling where events exist, unnecessary allocations/copies, eager loading that could be lazy (or vice versa), algorithmic complexity.
         - Memory/size: leaks, unbounded caches/buffers, oversized types, duplicated data, heavy dependencies for small uses.
         - Bloat: dead code, unused imports/deps/options/files, commented-out code, needless abstraction/indirection, wrappers that add nothing, defensive code for impossible cases.
         - Duplication: repeated logic/config/values that should be one shared definition.
         - Simplicity: convoluted control flow, inconsistent naming/idioms, things the language/stdlib/framework/upstream already provides.
         - Architecture: libraries, frameworks, data flow or structure that a lighter or better-fitting choice would beat. Justify with concrete gains.
      3. Report findings before editing: ranked by impact, each with file:line, the problem, the fix, and expected gain. Separate safe cleanups from behavior-changing or architectural changes. Ask which to apply.
      4. Apply approved changes, matching existing style. Preserve behavior unless a change was approved.
      5. Verify with the project's build/typecheck/tests (never deploy, flash, or rebuild systems). Report results honestly, including anything not verified.
    '';

    context = ''
      - Never run nixos-rebuild or home-manager switch; I build myself.
      - Shell is fish: no bash <(...), use psub or /dev/stdin.
    '';
  };
}
