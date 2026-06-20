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

@test "gpu.sh - gpu_parse_smi parses load, temp, and memory percent" {
  [[ "$(gpu_parse_smi "45, 60, 2048, 8192")" == "45 60 25" ]]
}

@test "gpu.sh - gpu_parse_smi is empty when fields are missing" {
  [[ -z "$(gpu_parse_smi "45, 60")" ]]
}

@test "gpu.sh - gpu_parse_smi defaults non-numeric load and temp to zero" {
  [[ "$(gpu_parse_smi "x, y, 100, 200")" == "0 0 50" ]]
}

@test "gpu.sh - gpu_parse_smi yields zero memory percent for zero total" {
  [[ "$(gpu_parse_smi "10, 50, 100, 0")" == "10 50 0" ]]
}

@test "gpu.sh - has_gpu reflects nvidia-smi presence" {
  has_command() { return 0; }
  has_gpu
  has_command() { return 1; }
  ! has_gpu
}

@test "gpu.sh - read_gpu parses the probe output when a GPU is present" {
  has_command() { return 0; }
  _read_nvidia_smi() { echo "30, 55, 1024, 4096"; }
  [[ "$(read_gpu)" == "30 55 25" ]]
}

@test "gpu.sh - read_gpu is empty when no GPU is present" {
  has_command() { return 1; }
  [[ -z "$(read_gpu)" ]]
}
