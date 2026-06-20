# tmux-gpu-revamped

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

## Requirements

`nvidia-smi` on `PATH`. Without it the plugin renders nothing and never errors.

## License

[MIT](LICENSE), copyright Gustavo Franco.
