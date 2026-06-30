#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _GPU_REVAMPED_HISTORY_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/gpu/history.sh"
}

teardown() {
  cleanup_test_environment
}

@test "history.sh - history_push appends to an empty list" {
  [[ "$(history_push "" 40 20)" == "40" ]]
}

@test "history.sh - history_push appends to a populated list" {
  [[ "$(history_push "10 20" 30 20)" == "10 20 30" ]]
}

@test "history.sh - history_push trims to the maximum length" {
  [[ "$(history_push "1 2 3" 4 3)" == "2 3 4" ]]
}

@test "history.sh - history_push ignores a non-numeric value" {
  [[ "$(history_push "10 20" "x" 20)" == "10 20" ]]
}

@test "history.sh - history_push falls back to a default maximum" {
  run history_push "5 6" 7 "bad"
  [[ "${output}" == "5 6 7" ]]
}

@test "history.sh - sparkline_char maps the ramp" {
  [[ "$(sparkline_char 0)" == "▁" ]]
  [[ "$(sparkline_char 100)" == "█" ]]
  [[ "$(sparkline_char 50)" == "▄" ]]
}

@test "history.sh - sparkline_char clamps and defaults" {
  [[ "$(sparkline_char 150)" == "█" ]]
  [[ "$(sparkline_char xx)" == "▁" ]]
}

@test "history.sh - render_sparkline builds a string" {
  [[ "$(render_sparkline "0 50 100")" == "▁▄█" ]]
}

@test "history.sh - render_sparkline skips non-numeric tokens" {
  [[ "$(render_sparkline "0 x 100")" == "▁█" ]]
}

@test "history.sh - render_sparkline is empty for a blank list" {
  [[ -z "$(render_sparkline "")" ]]
  [[ -z "$(render_sparkline "   ")" ]]
}
