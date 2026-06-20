#!/usr/bin/env bash
#
# gpu.sh: command dispatcher for tmux-gpu-revamped.
#
# Usage:
#   gpu.sh gpu_percentage | gpu_icon | gpu_fg_color | gpu_bg_color
#   gpu.sh gpu_temp | gpu_temp_icon | gpu_temp_fg_color | gpu_temp_bg_color
#   gpu.sh gram_percentage | gram_icon | gram_fg_color | gram_bg_color
#   gpu.sh refresh

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CACHE_PREFIX="gpu_revamped"
export PLUGIN_LOG_NS="gpu-revamped"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/has-command.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/cache.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/gpu/gpu.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/gpu/render.sh"

gpu_max_age() {
  get_tmux_option "@gpu_revamped_interval" "5"
}

gpu_refresh() {
  cache_set util "$(read_gpu_usage)"
  cache_set temp "$(read_gpu_temp)"
  cache_set freq "$(read_gpu_freq)"
  cache_set gram "$(read_gram)"
}

gpu_tick() {
  cache_refresh_if_stale util "$(gpu_max_age)" gpu_refresh
}

main() {
  local cmd="${1:-}"

  if [[ "${cmd}" == "refresh" ]]; then
    gpu_refresh
    return 0
  fi

  gpu_tick

  case "${cmd}" in
    gpu_percentage)    metric_value "$(cache_get util)" "@gpu_revamped_percentage_format" "%s%%" ;;
    gpu_icon)          metric_icon "$(cache_get util)" "gpu_revamped" 30 80 "▰▱▱" "▰▰▱" "▰▰▰" ;;
    gpu_fg_color)      metric_color "$(cache_get util)" "gpu_revamped" 30 80 fg ;;
    gpu_bg_color)      metric_color "$(cache_get util)" "gpu_revamped" 30 80 bg ;;
    gpu_temp)          gpu_temp_value "$(cache_get temp)" ;;
    gpu_temp_icon)     metric_icon "$(cache_get temp)" "gpu_revamped_temp" 65 80 "" "" "" ;;
    gpu_temp_fg_color) metric_color "$(cache_get temp)" "gpu_revamped_temp" 65 80 fg ;;
    gpu_temp_bg_color) metric_color "$(cache_get temp)" "gpu_revamped_temp" 65 80 bg ;;
    gpu_freq)          gpu_render_freq "$(cache_get freq)" ;;
    gram_percentage)   metric_value "$(cache_get gram)" "@gpu_revamped_gram_format" "%s%%" ;;
    gram_icon)         metric_icon "$(cache_get gram)" "gpu_revamped_gram" 50 85 "▰▱▱" "▰▰▱" "▰▰▰" ;;
    gram_fg_color)     metric_color "$(cache_get gram)" "gpu_revamped_gram" 50 85 fg ;;
    gram_bg_color)     metric_color "$(cache_get gram)" "gpu_revamped_gram" 50 85 bg ;;
    *)                 return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
