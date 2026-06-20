#!/usr/bin/env bash
#
# gpu.sh: GPU load, temperature, frequency, and memory acquisition.
#
# Ported from yoru-revamped-tmux with multi-vendor support: NVIDIA via
# nvidia-smi, AMD via rocm-smi, Intel and generic Linux via /sys/class/drm,
# Apple Silicon via ioreg, and macOS temperature via istats. Pure parsers turn
# probe output into numbers; readers wrap the host probes behind seams tests stub.

[[ -n "${_GPU_REVAMPED_GPU_LOADED:-}" ]] && return 0
_GPU_REVAMPED_GPU_LOADED=1

_GPU_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_GPU_LIB_DIR}/../utils/has-command.sh"
# shellcheck source=/dev/null
source "${_GPU_LIB_DIR}/../utils/platform.sh"

# ---------------------------------------------------------------------------
# Pure parsers
# ---------------------------------------------------------------------------

# gpu_usage_from_ioreg TEXT -> highest "Utilization %" integer, clamped to 100.
gpu_usage_from_ioreg() {
  local v
  v=$(printf '%s\n' "${1}" | grep -o '"[A-Za-z]* Utilization %"=[0-9]*' \
    | cut -d= -f2 | sort -rn | head -1)
  [[ "${v}" =~ ^[0-9]+$ ]] || { echo ""; return 0; }
  (( v > 100 )) && v=100
  echo "${v}"
}

# gpu_usage_from_nvidia TEXT -> integer utilization.
gpu_usage_from_nvidia() {
  local v
  v=$(printf '%s\n' "${1}" | head -1 | tr -d ' ')
  [[ "${v}" =~ ^[0-9]+$ ]] && echo "${v}"
}

# gpu_usage_from_rocm TEXT -> integer GPU use percent.
gpu_usage_from_rocm() {
  local v
  v=$(printf '%s\n' "${1}" | awk '/GPU use/ {gsub(/%/, ""); print $NF; exit}')
  [[ "${v}" =~ ^[0-9]+$ ]] && echo "${v}"
}

# gpu_temp_from_nvidia TEXT -> integer Celsius.
gpu_temp_from_nvidia() {
  local v
  v=$(printf '%s\n' "${1}" | head -1 | tr -d ' ')
  [[ "${v}" =~ ^[0-9]+$ ]] && echo "${v}"
}

# gpu_temp_from_hwmon MILLIDEG -> integer Celsius.
gpu_temp_from_hwmon() {
  [[ "${1}" =~ ^[0-9]+$ ]] || { echo ""; return 0; }
  echo $(( ${1} / 1000 ))
}

# gpu_temp_from_rocm TEXT -> integer Celsius from the edge sensor.
gpu_temp_from_rocm() {
  printf '%s\n' "${1}" | awk '/edge/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.?[0-9]*$/) {print int($i); exit}}'
}

# gpu_temp_from_istats TEXT -> integer Celsius from `istats gpu temp`.
gpu_temp_from_istats() {
  printf '%s\n' "${1}" | awk '/GPU/ {for(i=1;i<=NF;i++) if($i ~ /[0-9]/) {gsub(/[^0-9.]/, "", $i); if($i != "") {print int($i); exit}}}'
}

# gpu_freq_from_value VALUE -> the value when it is a positive integer.
gpu_freq_from_value() {
  [[ "${1}" =~ ^[0-9]+$ ]] && (( ${1} > 0 )) && echo "${1}"
}

# gpu_freq_from_rocm TEXT -> integer MHz from the sclk line.
gpu_freq_from_rocm() {
  printf '%s\n' "${1}" | awk '/sclk/ && /Mhz/ {gsub(/[^0-9]/, "", $2); print $2; exit}'
}

# gpu_freq_apple BRAND_STRING -> max GPU clock MHz for an Apple Silicon chip.
gpu_freq_apple() {
  local brand="${1}" gen variant
  gen=$(printf '%s' "${brand}" | grep -oE 'M[1-5]' | grep -oE '[1-5]' | head -1)
  [[ "${gen}" =~ ^[1-5]$ ]] || { echo "0"; return 0; }
  variant=$(printf '%s' "${brand}" | grep -oE '(Pro|Max|Ultra)' | head -1)
  local base=(0 1278 1398 1398 1580 1580)
  local max=(0 1296 1398 1398 1580 1580)
  case "${variant}" in
    Ultra|Max) echo "${max[gen]}" ;;
    *)         echo "${base[gen]}" ;;
  esac
}

# gpu_freq_intel_mac MODEL -> base clock MHz for known Intel-Mac GPUs.
gpu_freq_intel_mac() {
  case "${1}" in
    *"Radeon Pro W6800X"*) echo 2045 ;;
    *"Radeon Pro W6600X"*) echo 1845 ;;
    *"Radeon Pro 5600M"*)  echo 1035 ;;
    *"Radeon Pro 5500"*)   echo 1300 ;;
    *"Radeon Pro 5300"*)   echo 1233 ;;
    *"Radeon Pro Vega"*48*) echo 1500 ;;
    *"Radeon Pro Vega"*20*) echo 1398 ;;
    *"Radeon Pro 580"*)    echo 1266 ;;
    *"Radeon Pro 570"*)    echo 1176 ;;
    *"Radeon Pro 560"*)    echo 1233 ;;
    *"UHD Graphics 630"*)  echo 1200 ;;
    *"Iris Plus"*)         echo 1100 ;;
    *"HD Graphics 630"*)   echo 1150 ;;
    *"HD Graphics 530"*)   echo 1050 ;;
    *)                     echo 0 ;;
  esac
}

# gram_from_smi LINE -> integer percent from "used, total" memory CSV.
gram_from_smi() {
  local -a f
  read -ra f <<< "${1//,/ }"
  local used="${f[0]:-}" total="${f[1]:-}"
  [[ "${used}" =~ ^[0-9]+$ && "${total}" =~ ^[0-9]+$ && "${total}" -gt 0 ]] || { echo ""; return 0; }
  awk -v u="${used}" -v t="${total}" 'BEGIN { printf "%.0f", (u / t) * 100 }'
}

# ---------------------------------------------------------------------------
# Host-probe seams (tests override these)
# ---------------------------------------------------------------------------

_read_ioreg_gpu() { ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null; }
_read_nvidia_usage() { nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null; }
_read_rocm_usage() { rocm-smi -u 2>/dev/null; }
_read_nvidia_temp() { nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null; }
_read_rocm_temp() { rocm-smi -t 2>/dev/null; }
_read_istats_gpu() { istats gpu temp 2>/dev/null; }
_read_nvidia_freq() { nvidia-smi --query-gpu=clocks.current.graphics --format=csv,noheader,nounits 2>/dev/null; }
_read_rocm_freq() { rocm-smi --showclocks 2>/dev/null; }
_read_nvidia_mem() { nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1; }
_read_brand_string() { sysctl -n machdep.cpu.brand_string 2>/dev/null; }
_read_sp_displays() { system_profiler SPDisplaysDataType 2>/dev/null | awk -F: '/Chipset Model/ {gsub(/^[ \t]+/, "", $2); print $2; exit}'; }

# _read_sys_first GLOB DIVISOR -> first readable numeric value under GLOB,
# divided by DIVISOR (1 for none). Used for /sys/class/drm probes.
_read_sys_first() {
  local glob="${1}" div="${2:-1}" f v
  for f in ${glob}; do
    [[ -r "${f}" ]] || continue
    v=$(cat "${f}" 2>/dev/null)
    [[ "${v}" =~ ^[0-9]+$ ]] || continue
    (( div > 1 )) && v=$(( v / div ))
    echo "${v}"
    return 0
  done
}

_read_sys_gpu_busy() { _read_sys_first "/sys/class/drm/card[0-9]*/device/gpu_busy_percent" 1; }
_read_sys_gpu_temp() { _read_sys_first "/sys/class/drm/card[0-9]*/device/hwmon/hwmon*/temp1_input" 1000; }
_read_sys_gpu_freq() { _read_sys_first "/sys/class/drm/card[0-9]*/gt_cur_freq_mhz" 1; }

# ---------------------------------------------------------------------------
# Readers (the worker calls these)
# ---------------------------------------------------------------------------

read_gpu_usage() {
  if is_macos; then
    gpu_usage_from_ioreg "$(_read_ioreg_gpu)"
  elif is_linux; then
    if has_command nvidia-smi; then
      local v; v=$(gpu_usage_from_nvidia "$(_read_nvidia_usage)"); [[ -n "${v}" ]] && { echo "${v}"; return 0; }
    fi
    local s; s=$(_read_sys_gpu_busy); [[ -n "${s}" ]] && { echo "${s}"; return 0; }
    if has_command rocm-smi; then
      gpu_usage_from_rocm "$(_read_rocm_usage)"
    fi
  fi
}

read_gpu_temp() {
  if is_macos; then
    has_command istats && gpu_temp_from_istats "$(_read_istats_gpu)"
  elif is_linux; then
    if has_command nvidia-smi; then
      local v; v=$(gpu_temp_from_nvidia "$(_read_nvidia_temp)"); [[ -n "${v}" ]] && { echo "${v}"; return 0; }
    fi
    local s; s=$(_read_sys_gpu_temp); [[ -n "${s}" ]] && { echo "${s}"; return 0; }
    if has_command rocm-smi; then
      gpu_temp_from_rocm "$(_read_rocm_temp)"
    fi
  fi
}

read_gpu_freq() {
  if is_macos; then
    if is_apple_silicon; then
      gpu_freq_apple "$(_read_brand_string)"
    else
      gpu_freq_intel_mac "$(_read_sp_displays)"
    fi
  elif is_linux; then
    if has_command nvidia-smi; then
      local v; v=$(gpu_freq_from_value "$(_read_nvidia_freq | head -1 | tr -d ' ')"); [[ -n "${v}" ]] && { echo "${v}"; return 0; }
    fi
    local s; s=$(_read_sys_gpu_freq); [[ -n "${s}" ]] && { echo "${s}"; return 0; }
    if has_command rocm-smi; then
      gpu_freq_from_rocm "$(_read_rocm_freq)"
    fi
  fi
}

read_gram() {
  has_command nvidia-smi && gram_from_smi "$(_read_nvidia_mem)"
}

export -f gpu_usage_from_ioreg gpu_usage_from_nvidia gpu_usage_from_rocm
export -f gpu_temp_from_nvidia gpu_temp_from_hwmon gpu_temp_from_rocm gpu_temp_from_istats
export -f gpu_freq_from_value gpu_freq_from_rocm gpu_freq_apple gpu_freq_intel_mac
export -f gram_from_smi
export -f _read_ioreg_gpu _read_nvidia_usage _read_rocm_usage _read_nvidia_temp _read_rocm_temp
export -f _read_istats_gpu _read_nvidia_freq _read_rocm_freq _read_nvidia_mem
export -f _read_brand_string _read_sp_displays _read_sys_first
export -f _read_sys_gpu_busy _read_sys_gpu_temp _read_sys_gpu_freq
export -f read_gpu_usage read_gpu_temp read_gpu_freq read_gram
