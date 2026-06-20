#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _GPU_REVAMPED_GPU_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/gpu/gpu.sh"
}

teardown() {
  cleanup_test_environment
}

@test "gpu.sh - gpu_usage_from_ioreg takes the highest utilization" {
  local t='"Device Utilization %"=42 "Renderer Utilization %"=30'
  [[ "$(gpu_usage_from_ioreg "${t}")" == "42" ]]
}

@test "gpu.sh - gpu_usage_from_ioreg clamps above 100" {
  [[ "$(gpu_usage_from_ioreg '"Device Utilization %"=150')" == "100" ]]
}

@test "gpu.sh - gpu_usage_from_ioreg is empty with no match" {
  [[ -z "$(gpu_usage_from_ioreg 'nothing here')" ]]
}

@test "gpu.sh - gpu_usage_from_nvidia parses the value" {
  [[ "$(gpu_usage_from_nvidia '45')" == "45" ]]
  [[ -z "$(gpu_usage_from_nvidia 'x')" ]]
}

@test "gpu.sh - gpu_usage_from_rocm parses GPU use" {
  [[ "$(gpu_usage_from_rocm 'GPU use (%): 30%')" == "30" ]]
}

@test "gpu.sh - gpu_temp_from_nvidia parses the value" {
  [[ "$(gpu_temp_from_nvidia '60')" == "60" ]]
}

@test "gpu.sh - gpu_temp_from_hwmon converts millidegrees" {
  [[ "$(gpu_temp_from_hwmon '55000')" == "55" ]]
  [[ -z "$(gpu_temp_from_hwmon 'x')" ]]
}

@test "gpu.sh - gpu_temp_from_rocm reads the edge sensor" {
  [[ "$(gpu_temp_from_rocm 'Temperature (Sensor edge) (C): 50.0')" == "50" ]]
}

@test "gpu.sh - gpu_temp_from_istats reads the GPU temperature" {
  [[ "$(gpu_temp_from_istats 'GPU temp: 45.2 C')" == "45" ]]
}

@test "gpu.sh - gpu_freq_from_value accepts positive integers" {
  [[ "$(gpu_freq_from_value '1500')" == "1500" ]]
  [[ -z "$(gpu_freq_from_value '0')" ]]
  [[ -z "$(gpu_freq_from_value 'x')" ]]
}

@test "gpu.sh - gpu_freq_from_rocm parses sclk" {
  [[ "$(gpu_freq_from_rocm 'sclk: 1500Mhz')" == "1500" ]]
}

@test "gpu.sh - gpu_freq_apple looks up the chip clock" {
  [[ "$(gpu_freq_apple 'Apple M3 Max')" == "1398" ]]
  [[ "$(gpu_freq_apple 'Apple M1')" == "1278" ]]
  [[ "$(gpu_freq_apple 'Apple M5 Ultra')" == "1580" ]]
  [[ "$(gpu_freq_apple 'Intel Core i9')" == "0" ]]
}

@test "gpu.sh - gpu_freq_intel_mac covers every known model" {
  [[ "$(gpu_freq_intel_mac 'Radeon Pro W6800X')" == "2045" ]]
  [[ "$(gpu_freq_intel_mac 'Radeon Pro W6600X')" == "1845" ]]
  [[ "$(gpu_freq_intel_mac 'Radeon Pro 5600M')" == "1035" ]]
  [[ "$(gpu_freq_intel_mac 'Radeon Pro 5500')" == "1300" ]]
  [[ "$(gpu_freq_intel_mac 'Radeon Pro 5300')" == "1233" ]]
  [[ "$(gpu_freq_intel_mac 'Radeon Pro Vega 48')" == "1500" ]]
  [[ "$(gpu_freq_intel_mac 'Radeon Pro Vega 20')" == "1398" ]]
  [[ "$(gpu_freq_intel_mac 'Radeon Pro 580')" == "1266" ]]
  [[ "$(gpu_freq_intel_mac 'Radeon Pro 570')" == "1176" ]]
  [[ "$(gpu_freq_intel_mac 'Radeon Pro 560')" == "1233" ]]
  [[ "$(gpu_freq_intel_mac 'UHD Graphics 630')" == "1200" ]]
  [[ "$(gpu_freq_intel_mac 'Iris Plus Graphics')" == "1100" ]]
  [[ "$(gpu_freq_intel_mac 'HD Graphics 630')" == "1150" ]]
  [[ "$(gpu_freq_intel_mac 'HD Graphics 530')" == "1050" ]]
  [[ "$(gpu_freq_intel_mac 'Mystery GPU')" == "0" ]]
}

@test "gpu.sh - gram_from_smi computes memory percent" {
  [[ "$(gram_from_smi '2048, 8192')" == "25" ]]
  [[ -z "$(gram_from_smi '100, 0')" ]]
  [[ -z "$(gram_from_smi 'x, y')" ]]
}

@test "gpu.sh - _read_sys_first reads the first numeric value" {
  echo 42 > "${TEST_TMPDIR}/val"
  [[ "$(_read_sys_first "${TEST_TMPDIR}/val" 1)" == "42" ]]
  echo 55000 > "${TEST_TMPDIR}/t"
  [[ "$(_read_sys_first "${TEST_TMPDIR}/t" 1000)" == "55" ]]
  [[ -z "$(_read_sys_first "${TEST_TMPDIR}/nope" 1)" ]]
}

@test "gpu.sh - read_gpu_usage uses ioreg on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_ioreg_gpu() { echo '"Device Utilization %"=37'; }
  [[ "$(read_gpu_usage)" == "37" ]]
}

@test "gpu.sh - read_gpu_usage uses nvidia on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "nvidia-smi" ]]; }
  _read_nvidia_usage() { echo "45"; }
  [[ "$(read_gpu_usage)" == "45" ]]
}

@test "gpu.sh - read_gpu_usage falls back to sysfs" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 1; }
  _read_sys_gpu_busy() { echo "20"; }
  [[ "$(read_gpu_usage)" == "20" ]]
}

@test "gpu.sh - read_gpu_usage falls back to rocm" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "rocm-smi" ]]; }
  _read_sys_gpu_busy() { echo ""; }
  _read_rocm_usage() { echo "GPU use (%): 60%"; }
  [[ "$(read_gpu_usage)" == "60" ]]
}

@test "gpu.sh - read_gpu_temp uses istats on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "$1" == "istats" ]]; }
  _read_istats_gpu() { echo "GPU temp: 48 C"; }
  [[ "$(read_gpu_temp)" == "48" ]]
}

@test "gpu.sh - read_gpu_temp uses nvidia on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "nvidia-smi" ]]; }
  _read_nvidia_temp() { echo "62"; }
  [[ "$(read_gpu_temp)" == "62" ]]
}

@test "gpu.sh - read_gpu_temp falls back to sysfs hwmon" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 1; }
  _read_sys_gpu_temp() { echo "54"; }
  [[ "$(read_gpu_temp)" == "54" ]]
}

@test "gpu.sh - read_gpu_temp falls back to rocm" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "rocm-smi" ]]; }
  _read_sys_gpu_temp() { echo ""; }
  _read_rocm_temp() { echo "Temperature (Sensor edge) (C): 70.0"; }
  [[ "$(read_gpu_temp)" == "70" ]]
}

@test "gpu.sh - read_gpu_freq uses the Apple Silicon table" {
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="arm64"
  _read_brand_string() { echo "Apple M3 Max"; }
  [[ "$(read_gpu_freq)" == "1398" ]]
}

@test "gpu.sh - read_gpu_freq uses the Intel-Mac table" {
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="x86_64"
  _read_sp_displays() { echo "AMD Radeon Pro 580"; }
  [[ "$(read_gpu_freq)" == "1266" ]]
}

@test "gpu.sh - read_gpu_freq uses nvidia on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "nvidia-smi" ]]; }
  _read_nvidia_freq() { echo "1700"; }
  [[ "$(read_gpu_freq)" == "1700" ]]
}

@test "gpu.sh - read_gpu_freq falls back to sysfs" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 1; }
  _read_sys_gpu_freq() { echo "1400"; }
  [[ "$(read_gpu_freq)" == "1400" ]]
}

@test "gpu.sh - read_gpu_freq falls back to rocm" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { [[ "$1" == "rocm-smi" ]]; }
  _read_sys_gpu_freq() { echo ""; }
  _read_rocm_freq() { echo "sclk: 1450Mhz"; }
  [[ "$(read_gpu_freq)" == "1450" ]]
}

@test "gpu.sh - read_gram reads nvidia memory" {
  has_command() { [[ "$1" == "nvidia-smi" ]]; }
  _read_nvidia_mem() { echo "1024, 4096"; }
  [[ "$(read_gram)" == "25" ]]
}

@test "gpu.sh - read_gram is empty without nvidia" {
  has_command() { return 1; }
  [[ -z "$(read_gram)" ]]
}

@test "gpu.sh - host-probe seams are callable" {
  run _read_ioreg_gpu
  run _read_nvidia_usage
  run _read_rocm_usage
  run _read_nvidia_temp
  run _read_rocm_temp
  run _read_istats_gpu
  run _read_nvidia_freq
  run _read_rocm_freq
  run _read_nvidia_mem
  run _read_brand_string
  run _read_sp_displays
  run _read_sys_gpu_busy
  run _read_sys_gpu_temp
  run _read_sys_gpu_freq
  true
}
