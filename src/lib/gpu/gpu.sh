#!/usr/bin/env bash
#
# gpu.sh: GPU load, temperature, and memory acquisition via nvidia-smi.
#
# One nvidia-smi query yields all three raw values. gpu_parse_smi is pure; the
# reader wraps the host probe behind a seam tests can stub.

[[ -n "${_GPU_REVAMPED_GPU_LOADED:-}" ]] && return 0
_GPU_REVAMPED_GPU_LOADED=1

_GPU_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_GPU_LIB_DIR}/../utils/has-command.sh"

# gpu_parse_smi LINE -> "<util> <temp> <gram_pct>", or empty when malformed.
# LINE is a CSV row: "utilization, temperature, memory.used, memory.total".
gpu_parse_smi() {
  local -a f
  read -ra f <<< "${1//,/ }"
  [[ ${#f[@]} -ge 4 ]] || { echo ""; return 0; }
  local util="${f[0]}" temp="${f[1]}" used="${f[2]}" total="${f[3]}"
  [[ "${util}" =~ ^[0-9]+$ ]] || util=0
  [[ "${temp}" =~ ^[0-9]+$ ]] || temp=0
  local gram=0
  if [[ "${used}" =~ ^[0-9]+$ && "${total}" =~ ^[0-9]+$ && "${total}" -gt 0 ]]; then
    gram=$(awk -v u="${used}" -v t="${total}" 'BEGIN { printf "%.0f", (u / t) * 100 }')
  fi
  echo "${util} ${temp} ${gram}"
}

# Host-probe seam. Tests override this.
_read_nvidia_smi() {
  nvidia-smi \
    --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total \
    --format=csv,noheader,nounits 2>/dev/null | head -1
}

has_gpu() {
  has_command nvidia-smi
}

# read_gpu -> "<util> <temp> <gram_pct>", or empty when no GPU is present.
read_gpu() {
  if has_gpu; then
    gpu_parse_smi "$(_read_nvidia_smi)"
  fi
}

export -f gpu_parse_smi
export -f _read_nvidia_smi
export -f has_gpu
export -f read_gpu
