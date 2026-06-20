# tmux-gpu-revamped

[![Tests](https://github.com/gufranco/tmux-gpu-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/gufranco/tmux-gpu-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

NVIDIA GPU load, temperature, and memory for your tmux status bar, without ever
blocking the status render.

One `nvidia-smi` query runs in a detached background worker and writes three
values to tmux server user-options. The status line reads them instantly. No temp
files are used. When no NVIDIA GPU is present the placeholders render empty.

Inspired by the GPU metrics in
[tmux-cpu](https://github.com/tmux-plugins/tmux-cpu). Built from
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
| `@gpu_revamped_gram_format` | `%s%%` | format for the memory value |
| `@gpu_revamped_gram_medium_thresh` | `50` | memory percent for the medium tier |
| `@gpu_revamped_gram_high_thresh` | `85` | memory percent for the high tier |
| `@gpu_revamped_gram_{low,medium,high}_icon` | `▰▱▱`, `▰▰▱`, `▰▰▰` | memory tier icons |
| `@gpu_revamped_gram_{low,medium,high}_{fg,bg}_color` | empty | memory tier colors |
| `@gpu_revamped_enable_logging` | `0` | set to `1` to log under `~/.tmux/gpu-revamped-logs` |

## Support by platform and architecture

This plugin reports NVIDIA GPUs through `nvidia-smi`. It works on any platform
where an NVIDIA driver and `nvidia-smi` are present, which in practice is Linux
and Windows with a discrete NVIDIA card.

| Setup | Supported |
|-------|-----------|
| Linux or Windows with an NVIDIA GPU and `nvidia-smi` | yes |
| Apple Silicon Macs | no, there is no `nvidia-smi`; placeholders render empty |
| Intel Macs, AMD GPUs, integrated Intel GPUs | no, not covered by `nvidia-smi` |

Without `nvidia-smi` on `PATH` the plugin renders nothing and never errors, so it
is safe to load on a machine that has no NVIDIA GPU.

## License

[MIT](LICENSE), copyright Gustavo Franco.
