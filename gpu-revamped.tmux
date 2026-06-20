#!/usr/bin/env bash
#
# gpu-revamped.tmux: TPM entry point.
#
# Replaces the #{gpu_*} and #{gram_*} placeholders in status-left and
# status-right with calls to the dispatcher, which reads cached values.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GPU_CMD="${PLUGIN_DIR}/src/gpu.sh"

placeholders=(
  "\#{gpu_percentage}"
  "\#{gpu_icon}"
  "\#{gpu_fg_color}"
  "\#{gpu_bg_color}"
  "\#{gpu_temp}"
  "\#{gpu_temp_icon}"
  "\#{gpu_temp_fg_color}"
  "\#{gpu_temp_bg_color}"
  "\#{gpu_freq}"
  "\#{gram_percentage}"
  "\#{gram_icon}"
  "\#{gram_fg_color}"
  "\#{gram_bg_color}"
)

commands=(
  "#(${GPU_CMD} gpu_percentage)"
  "#(${GPU_CMD} gpu_icon)"
  "#(${GPU_CMD} gpu_fg_color)"
  "#(${GPU_CMD} gpu_bg_color)"
  "#(${GPU_CMD} gpu_temp)"
  "#(${GPU_CMD} gpu_temp_icon)"
  "#(${GPU_CMD} gpu_temp_fg_color)"
  "#(${GPU_CMD} gpu_temp_bg_color)"
  "#(${GPU_CMD} gpu_freq)"
  "#(${GPU_CMD} gram_percentage)"
  "#(${GPU_CMD} gram_icon)"
  "#(${GPU_CMD} gram_fg_color)"
  "#(${GPU_CMD} gram_bg_color)"
)

interpolate() {
  local value="${1}"
  local i
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value="${value//${placeholders[i]}/${commands[i]}}"
  done
  echo "${value}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${GPU_CMD}" 2>/dev/null || true

update_option "status-left"
update_option "status-right"
