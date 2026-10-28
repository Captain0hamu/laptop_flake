# Sourced only in an interactive Tor development shell.
tor-banner() {
  local cols rows indent purple accent dim reset green light dark i padding mode="${1:-shell}"
  local -a left middle right info
  read -r rows cols < <(stty size 2>/dev/null) || cols=0
  [[ "$cols" =~ ^[0-9]+$ ]] && (( cols > 0 )) || cols=80
  [[ "$rows" =~ ^[0-9]+$ ]] && (( rows > 0 )) || rows=24

  purple='' accent='' dim='' reset='' green='' light='' dark=''
  if [[ -t 1 && "${TERM:-dumb}" != dumb && ! ${NO_COLOR+x} ]]; then
    purple=$'\033[38;5;135m' light=$'\033[38;5;183m' dark=$'\033[38;5;97m'
    green=$'\033[38;5;114m' accent=$'\033[1;38;5;183m' dim=$'\033[2m' reset=$'\033[0m'
  fi

  if (( cols >= 70 && rows >= 15 )); then
    indent=$(( (cols - 70) / 2 ))
    left=(
      '          ' '        ' '         ' '        ▄█' '      ▄█'
      '    ▄██' '   ▄██' '  ▄██' '  ██' '   ▀██' '    ▀██' '      ▀█' '         '
    )
    middle=(
      '  ▄▄' '  ▄██' ' ▄██' '███' '██░░███'
      '██░░███████' '██░░███████████' '██░░█████████████'
      '██░░██████████████' '██░░█████████████' '██░░███████████'
      '██░░███████' '▀████████▀'
    )
    right=(
      '▄' '▀' '▀' '█▄' '█▄' '██▄' '██▄' '██▄' '██' '██▀' '██▀' '█▀' ''
    )
    info=(
      '' '' 'T O R   S H E L L' '────────────────────────────'
      '' 'MODE     Explicit SOCKS proxy' 'CLIENT   tor-start / tor-stop'
      'RUN      torsocks <command>' 'CHECK    check.torproject.org' ''
      'Traffic is not routed automatically.' 'Not network isolation.' ''
    )
    if [[ "$mode" == start ]]; then
      info[2]='T O R   C L I E N T'
      info[5]='MODE     Starting in background'
      info[6]='LISTEN   127.0.0.1:9050'
      info[7]='STOP     tor-stop'
      info[8]='SHELL    tor-shell'
      info[10]='Wait for bootstrap to reach 100%.'
      info[11]='Traffic is not routed automatically.'
    fi
    printf '\n'
    for (( i = 0; i < ${#left[@]}; i++ )); do
      padding=$(( 30 - ${#left[i]} - ${#middle[i]} - ${#right[i]} ))
      if (( i < 3 )); then
        printf '%*s%s%b%s%b%s%b%*s%b%s%b\n' "$indent" '' "${left[i]}" \
          "$green" "${middle[i]}" "$light" "${right[i]}" "$reset" \
          "$padding" '' "$accent" "${info[i]}" "$reset"
      else
        printf '%*s%b%s%b%s%b%s%b%*s%b%s%b\n' "$indent" '' "$dark" "${left[i]}" \
          "$purple" "${middle[i]}" "$light" "${right[i]}" "$reset" \
          "$padding" '' "$accent" "${info[i]}" "$reset"
      fi
    done
    printf '\n'
  elif (( cols >= 37 && rows >= 6 )); then
    local title='T O R  S H E L L' hint='torsocks <command>'
    if [[ "$mode" == start ]]; then
      title='T O R  C L I E N T'
      hint='Stop with tor-stop'
    fi
    printf '\n%b%s%b%s\n' "$green" '    ▄▄     ' "$reset" "$title"
    printf '%b%s%b\n' "$purple" '  ▄████▄   ------------------' "$reset"
    printf '%b%s%b%b%s%b\n' "$purple" ' ███░████  ' "$reset" "$accent" "$hint" "$reset"
    printf '%b%s%b\n\n' "$purple" '  ▀████▀   Proxy is not automatic.' "$reset"
  elif (( cols >= 23 && rows >= 3 )); then
    if [[ "$mode" == start ]]; then
      printf '%b%s%b\n%s\n' "$purple" 'TOR CLIENT' "$reset" 'Stop: tor-stop'
    else
      printf '%b%s%b\n%s\n' "$purple" 'TOR SHELL' "$reset" 'Use: torsocks <command>'
    fi
  else
    local label='TOR SHELL'
    [[ "$mode" == start ]] && label='TOR CLIENT'
    printf '%b%s%b\n' "$purple" "${label:0:cols}" "$reset"
  fi
}
