#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _GPU_REVAMPED_GPU_LOADED _GPU_REVAMPED_RENDER_LOADED
  export CACHE_SYNC=1
  source "${BATS_TEST_DIRNAME}/../../../src/gpu.sh"
  read_gpu_usage() { echo "45"; }
  read_gpu_temp() { echo "60"; }
  read_gpu_freq() { echo "1398"; }
  read_gram() { echo "25"; }
}

teardown() {
  cleanup_test_environment
}

@test "gpu.sh dispatcher - functions are defined" {
  function_exists main
  function_exists gpu_refresh
  function_exists gpu_tick
  function_exists gpu_max_age
}

@test "gpu.sh dispatcher - gpu_max_age default is 5" {
  [[ "$(gpu_max_age)" == "5" ]]
}

@test "gpu.sh dispatcher - gpu_max_age honors the interval option" {
  set_tmux_option "@gpu_revamped_interval" "7"
  [[ "$(gpu_max_age)" == "7" ]]
}

@test "gpu.sh dispatcher - gpu_refresh caches every metric" {
  gpu_refresh
  [[ "$(cache_get util)" == "45" ]]
  [[ "$(cache_get temp)" == "60" ]]
  [[ "$(cache_get freq)" == "1398" ]]
  [[ "$(cache_get gram)" == "25" ]]
}

@test "gpu.sh dispatcher - refresh subcommand caches metrics" {
  main refresh
  [[ "$(cache_get util)" == "45" ]]
}

@test "gpu.sh dispatcher - gpu_percentage renders the cached load" {
  run main gpu_percentage
  [[ "${output}" == "45%" ]]
}

@test "gpu.sh dispatcher - gpu_icon maps the cached load" {
  run main gpu_icon
  [[ "${output}" == "▰▰▱" ]]
}

@test "gpu.sh dispatcher - gpu_temp renders the cached temperature" {
  run main gpu_temp
  [[ "${output}" == "60°C" ]]
}

@test "gpu.sh dispatcher - gpu_freq renders the cached frequency" {
  run main gpu_freq
  [[ "${output}" == "1398MHz" ]]
}

@test "gpu.sh dispatcher - gram_percentage renders the cached memory" {
  run main gram_percentage
  [[ "${output}" == "25%" ]]
}

@test "gpu.sh dispatcher - gram_icon maps the cached memory" {
  run main gram_icon
  [[ "${output}" == "▰▱▱" ]]
}

@test "gpu.sh dispatcher - gpu colors map the cached load" {
  set_tmux_option "@gpu_revamped_medium_fg_color" "#[fg=yellow]"
  set_tmux_option "@gpu_revamped_medium_bg_color" "#[bg=yellow]"
  run main gpu_fg_color
  [[ "${output}" == "#[fg=yellow]" ]]
  run main gpu_bg_color
  [[ "${output}" == "#[bg=yellow]" ]]
}

@test "gpu.sh dispatcher - gpu temperature tier placeholders map the cache" {
  set_tmux_option "@gpu_revamped_temp_low_icon" "COOL"
  set_tmux_option "@gpu_revamped_temp_low_fg_color" "#[fg=blue]"
  set_tmux_option "@gpu_revamped_temp_low_bg_color" "#[bg=blue]"
  run main gpu_temp_icon
  [[ "${output}" == "COOL" ]]
  run main gpu_temp_fg_color
  [[ "${output}" == "#[fg=blue]" ]]
  run main gpu_temp_bg_color
  [[ "${output}" == "#[bg=blue]" ]]
}

@test "gpu.sh dispatcher - gram colors map the cached memory" {
  set_tmux_option "@gpu_revamped_gram_low_fg_color" "#[fg=green]"
  set_tmux_option "@gpu_revamped_gram_low_bg_color" "#[bg=green]"
  run main gram_fg_color
  [[ "${output}" == "#[fg=green]" ]]
  run main gram_bg_color
  [[ "${output}" == "#[bg=green]" ]]
}

@test "gpu.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}
