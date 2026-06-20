# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-20

### Added

- AMD (`rocm-smi`), Intel and generic Linux (`/sys/class/drm`), and Apple Silicon
  (`ioreg`) GPU load, so the plugin works beyond NVIDIA.
- GPU frequency placeholder `#{gpu_freq}` with per-chip clock tables for Apple
  Silicon and Intel Macs.
- macOS GPU temperature via `istats`.

### Changed

- Each metric now probes multiple vendors and renders empty only when no source
  exists on the host.

## [1.0.0] - 2026-06-19

### Added

- GPU load placeholders: `#{gpu_percentage}`, `#{gpu_icon}`, `#{gpu_fg_color}`,
  `#{gpu_bg_color}`.
- GPU temperature placeholders: `#{gpu_temp}`, `#{gpu_temp_icon}`,
  `#{gpu_temp_fg_color}`, `#{gpu_temp_bg_color}`.
- GPU memory placeholders: `#{gram_percentage}`, `#{gram_icon}`,
  `#{gram_fg_color}`, `#{gram_bg_color}`.
- Non-blocking design: one `nvidia-smi` query runs in a background worker and the
  three values are read from tmux user-options, with no temp files.
- Graceful empty output when no NVIDIA GPU is present.
