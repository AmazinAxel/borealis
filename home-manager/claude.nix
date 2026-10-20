{ pkgs, lib, ... }: let
  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      export LC_ALL=C.UTF-8

      IFS=$'\t' read -r vim ms add del s w sr wr cache ctx < <(jq -r '[
        (.vim.mode // "-"), (.cost.total_api_duration_ms // 0 | floor),
        (.cost.total_lines_added // 0), (.cost.total_lines_removed // 0),
        (.rate_limits.five_hour.used_percentage // -1 | floor),
        (.rate_limits.seven_day.used_percentage // -1 | floor),
        (.rate_limits.five_hour.resets_at // 0 | floor),
        (.rate_limits.seven_day.resets_at // 0 | floor),
        (.context_window.current_usage.cache_read_input_tokens // -1),
        (.context_window.used_percentage // 0 | floor)
      ] | @tsv')

      # rate limits arrive with the first reply; show the last known until then
      f=''${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline
      read -r cs cw csr cwr 2>/dev/null <"$f" || cs=0 cw=0 csr=0 cwr=0
      (( s < 0 )) && s=$cs sr=$csr
      (( w < 0 )) && w=$cw wr=$cwr
      [[ "$s $w $sr $wr" == "$cs $cw $csr $cwr" ]] || echo "$s $w $sr $wr" >"$f"
      printf -v now '%(%s)T' -1

      r=$'\e[0m'
      dim=$'\e[90m' fg=$'\e[39m' frost=$'\e[36m'
      green=$'\e[32m' red=$'\e[31m'

      # from $4% the time until the window resets is drawn over the bar
      bar() {
        local p=$1 w=$2 t=$(( $3 - now )) n i c txt="" o=0 out="$dim▕"
        n=$(( (p * w + 50) / 100 )); (( n > w )) && n=$w
        if (( p >= $4 && t > 0 )); then
          if (( t >= 86400 )); then txt="$(( t / 86400 ))d$(( t % 86400 / 3600 ))h"
          elif (( t >= 3600 )); then txt="$(( t / 3600 ))h$(( t % 3600 / 60 ))m"
          else txt="$(( t / 60 + 1 ))m"; fi
          (( ''${#txt} > w )) && txt=""
          o=$(( (w - ''${#txt}) / 2 ))
        fi
        for (( i = 0; i < w; i++ )); do
          c=""; (( i >= o && i < o + ''${#txt} )) && c=''${txt:i-o:1}
          if (( i < n )); then
            if [[ $c ]]; then out+=$'\e[1;30;46m'"$c"$'\e[0m'; else out+="$frost█"; fi
          elif [[ $c ]]; then out+="$fg$c"
          else out+="$dim░"; fi
        done
        printf -v b '%s▏ %s%s%% ' "$out$dim" "$fg" "$p"; right+=$b
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
          sum=0; for (( i = 0; i < k; i++ )); do (( sum += 5 + ''${#pct[i]} )); done
          bw=$(( ($1 - 2 - sum) / k ))
          (( bw >= (k > 1 ? 6 : 3) )) && { (( bw > 16 )) && bw=16; return 0; }
        done
        (( ''${#pct[@]} == 0 ))
      }

      sep="  "
      fit $(( cols - ''${#l} - 2 )) || { sep=$'\n'; fit "$cols" || k=0; }
      right=""
      for (( i = 0; i < k; i++ )); do bar "''${pct[i]}" "$bw" "''${rst[i]}" "''${thr[i]}"; done
      right="''${right% }$r"
      rt=''${right//$'\e'\[*([0-9;])m/}

      if [[ $sep == "  " ]]; then
        printf '%s%*s%s' "$left" $(( cols - ''${#l} - ''${#rt} )) "" "$right"
      else
        printf '%s\n%*s%s' "$left$r" $(( cols - ''${#rt} )) "" "$right"
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
      };

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
      - Talk caveman. Drop articles, filler, pleasantries, hedges, pronouns where clear. Fragments. Example: "Fixed. Cache check wrong var, claude.nix:60."
      - Answer first. No preamble, recap, or closing offer.
      - Code, error text, numbers, paths, technical terms stay exact; caveman only in prose.
      - A question gets an answer, not work: 1-2 fragments, cite file:line, don't paste code back.
      - A change gets one line: what changed, file:line. Don't restate the diff.
      - Never assume. Request ambiguous (meaning, scope, behavior, edge case, which option) → ask before acting. Use AskUserQuestion, short options.
      - Facts readable in code/files: look, don't ask. Only user intent gets asked.
      - Intent clear → one approach, no option surveys.

      Work:
      - Smallest change that works. Match the file's style; no unrequested refactors, abstractions or comments.
      - Search narrow: rg -n, read ranges with sed -n, cap with head. Stop at the first answer.
      - Batch independent tool calls. Never re-read a file to check an edit.
      - No subagents unless asked. Think hard only when the problem needs it.
    '';

    context = ''
      - Never run nixos-rebuild or home-manager switch; I build myself.
      - Shell is fish: no bash <(...), use psub or /dev/stdin.
    '';
  };
}
