#!/usr/bin/env bash
#
# history.sh: a bounded history ring buffer rendered as a sparkline.
#
# History lives in a single space-separated tmux user-option, never a temp file.
# Each refresh appends the latest reading; the list is trimmed to a maximum
# length so the option can never grow without bound. The sparkline maps each
# 0..100 reading to one of eight block glyphs.

[[ -n "${_GPU_REVAMPED_HISTORY_LOADED:-}" ]] && return 0
_GPU_REVAMPED_HISTORY_LOADED=1

# history_push LIST VALUE MAX -> LIST with VALUE appended, trimmed to the last
# MAX entries. Non-numeric VALUE returns LIST unchanged. MAX defaults to 20.
history_push() {
  local list="${1}" value="${2}" max="${3:-20}"
  [[ "${value}" =~ ^[0-9]+$ ]] || { echo "${list}"; return 0; }
  [[ "${max}" =~ ^[0-9]+$ && "${max}" -gt 0 ]] || max=20
  local -a items
  read -ra items <<< "${list} ${value}"
  local count="${#items[@]}"
  local start=0
  (( count > max )) && start=$(( count - max ))
  local out="" i
  for (( i = start; i < count; i++ )); do
    out="${out}${out:+ }${items[i]}"
  done
  echo "${out}"
}

# sparkline_char VALUE -> one ramp glyph for a 0..100 reading. Out-of-range
# values clamp; non-numeric input yields the lowest glyph.
sparkline_char() {
  local v="${1}"
  [[ "${v}" =~ ^[0-9]+$ ]] || v=0
  (( v > 100 )) && v=100
  # An array keeps each multibyte glyph intact regardless of locale.
  local ramp=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
  local idx=$(( v * 7 / 100 ))
  printf '%s' "${ramp[idx]}"
}

# render_sparkline LIST -> a sparkline string built from every numeric token.
render_sparkline() {
  local list="${1}" out="" token
  [[ -z "${list// /}" ]] && { echo ""; return 0; }
  local -a items
  read -ra items <<< "${list}"
  for token in "${items[@]}"; do
    [[ "${token}" =~ ^[0-9]+$ ]] || continue
    out="${out}$(sparkline_char "${token}")"
  done
  echo "${out}"
}

export -f history_push
export -f sparkline_char
export -f render_sparkline
