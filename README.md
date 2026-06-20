# tmux-gpu-revamped

[![Tests](https://github.com/gufranco/tmux-gpu-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/gufranco/tmux-gpu-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

GPU load, temperature, frequency, and memory for your tmux status bar, across
NVIDIA, AMD, Intel, and Apple Silicon, without ever blocking the status render.

A detached background worker probes the GPU and writes the values to tmux server
user-options. The status line reads them instantly. No temp files are used. When
a metric has no source on the host the matching placeholders render empty.

Built from
[tmux-plugin-template](https://github.com/gufranco/tmux-plugin-template).

## Placeholders

| Placeholder | Output |
|-------------|--------|
| `#{gpu_percentage}` | GPU load, for example `45%` |
| `#{gpu_icon}` | a tier icon for the load |
| `#{gpu_fg_color}` / `#{gpu_bg_color}` | colors for the load tier |
| `#{gpu_temp}` | GPU temperature, for example `60°C` |
| `#{gpu_temp_icon}` | a tier icon for the temperature |
| `#{gpu_temp_fg_color}` / `#{gpu_temp_bg_color}` | colors for the temperature tier |
| `#{gpu_freq}` | GPU clock, for example `1398MHz` |
| `#{gram_percentage}` | GPU memory used, for example `25%` |
| `#{gram_icon}` | a tier icon for memory |
| `#{gram_fg_color}` / `#{gram_bg_color}` | colors for the memory tier |

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'gufranco/tmux-gpu-revamped'
set -g status-right '#{gpu_icon} #{gpu_percentage} #{gpu_temp} #{gram_percentage}'
```

Press `prefix + I` to install.

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@gpu_revamped_interval` | `5` | seconds a sample stays fresh |
| `@gpu_revamped_percentage_format` | `%s%%` | format for the load value |
| `@gpu_revamped_medium_thresh` | `30` | load percent for the medium tier |
| `@gpu_revamped_high_thresh` | `80` | load percent for the high tier |
| `@gpu_revamped_{low,medium,high}_icon` | `▰▱▱`, `▰▰▱`, `▰▰▰` | load tier icons |
| `@gpu_revamped_{low,medium,high}_{fg,bg}_color` | empty | load tier colors |
| `@gpu_revamped_temp_unit` | `C` | `C` or `F` |
| `@gpu_revamped_temp_format` | `%s°C` | format for the temperature value |
| `@gpu_revamped_temp_medium_thresh` | `65` | degrees Celsius for the medium tier |
| `@gpu_revamped_temp_high_thresh` | `80` | degrees Celsius for the high tier |
| `@gpu_revamped_temp_{low,medium,high}_icon` | empty | temperature tier icons |
| `@gpu_revamped_temp_{low,medium,high}_{fg,bg}_color` | empty | temperature tier colors |
| `@gpu_revamped_freq_format` | `%sMHz` | format for the GPU clock |
| `@gpu_revamped_gram_format` | `%s%%` | format for the memory value |
| `@gpu_revamped_gram_medium_thresh` | `50` | memory percent for the medium tier |
| `@gpu_revamped_gram_high_thresh` | `85` | memory percent for the high tier |
| `@gpu_revamped_gram_{low,medium,high}_icon` | `▰▱▱`, `▰▰▱`, `▰▰▰` | memory tier icons |
| `@gpu_revamped_gram_{low,medium,high}_{fg,bg}_color` | empty | memory tier colors |
| `@gpu_revamped_enable_logging` | `0` | set to `1` to log under `~/.tmux/gpu-revamped-logs` |

## Support by platform and architecture

| Setup | Load | Temperature | Frequency | Memory |
|-------|------|-------------|-----------|--------|
| Linux + NVIDIA (`nvidia-smi`) | yes | yes | yes | yes |
| Linux + AMD (`rocm-smi`) | yes | yes | yes | no |
| Linux + Intel or generic (`/sys/class/drm`) | yes | yes | yes | no |
| macOS Apple Silicon | yes, `ioreg` | no, see note | yes, chip table | no |
| macOS Intel | yes, `ioreg` | no, see note | yes, model table | no |

Verified on an Apple M3 Max: load reads through `ioreg` and frequency comes from a
per-chip clock table, so the GPU placeholders are populated even though there is no
`nvidia-smi`. GPU temperature on macOS is not available without elevated access: istats has no
GPU category and powermetrics needs sudo, so the macOS GPU temperature placeholder
stays empty (validated on an Apple M3 Max). GPU temperature works on Linux. GPU memory (`gram`) is NVIDIA only. Any metric with no source on
the host renders empty and never errors.

## License

[MIT](LICENSE), copyright Gustavo Franco.
