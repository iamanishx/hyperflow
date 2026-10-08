# hyperflow

Native push-to-talk dictation for **Hyprland**. One bash script. No daemon, no shim, no Electron.

Hold a button → speak → release → the words land at your cursor. Any app: browser, editor, terminal, chat.

```
hold  →  🎤  REC in waybar + start ping
speak
release →  transcribe ping, text typed at cursor
```

## Why

Every dictation tool for Wayland is either a daemon, an Electron app, or a paid SaaS.
hyperflow is ~150 lines of bash that Hyprland triggers per keypress — zero idle RAM, zero background processes, and it talks **directly** to Azure's fast transcription API (the current mai-transcribe model family — one of the best speech models available, with per-phrase language detection for code-mixed speech like Hinglish).

## Features

- **Hold-to-talk or tap-to-toggle** — bound to any key or mouse button
- **Waybar indicator** — idle mic → `REC` while recording → `…` while transcribing
- **Start/stop sounds**
- **Auto language detection** per phrase (English + Hindi by default; any locales)
- **Terminal-aware paste** — `Ctrl+Shift+V` in terminals, `Ctrl+V` everywhere else
- **Guards** — too-short taps notify instead of uploading nothing; empty results notify instead of pasting garbage
- **No idle cost** — it only exists for the seconds you're dictating

---

## Installation guide

### 1. Dependencies

```bash
sudo apt install alsa-utils curl wl-clipboard wtype ffmpeg pipewire-utils python3
```

(`hyprctl` ships with Hyprland.)

### 2. Get an Azure Speech key (free tier works)

1. Create an **Azure AI Speech** resource at [ai.azure.com](https://ai.azure.com) or the Azure portal
2. Open the resource → **Speech to text** → copy the **endpoint** and **key**
   - endpoint looks like `https://<name>.cognitiveservices.azure.com`
3. The **F0 free tier** includes 5 audio hours/month — plenty for dictation

### 3. Install

```bash
git clone https://github.com/iamanishx/hyperflow
cd hyperflow
./install.sh
```

### 4. Configure

Edit `~/.config/hyperflow/env`:

```bash
AZURE_STT_ENDPOINT=https://<your-resource>.cognitiveservices.azure.com
AZURE_SPEECH_KEY=<your key>
AZURE_STT_LOCALES=en-US,hi-IN   # per-phrase auto-detect candidates
```

### 5. Bind a button (hyprland.conf)

Hold the side mouse button:

```ini
bind  = , mouse:276, exec, hyperflow start
bindr = , mouse:276, exec, hyperflow stop
```

or a keyboard hold:

```ini
bind  = ALT, GRAVE, exec, hyperflow start
bindr = ALT, GRAVE, exec, hyperflow stop
```

or tap-to-toggle:

```ini
bind = ALT, SPACE, exec, hyperflow toggle
```

> **Linux mouse button codes:** left `272`, right `273`, wheel-press `274`, side-back `275`, side-forward `276`. Check yours with `wev`.

Then `hyprctl reload` and hold the button.

### 6. Waybar indicator (optional but nice)

- Copy the `custom/hyperflow` block from [`waybar/module.jsonc`](waybar/module.jsonc) into your waybar modules file
- Add `"custom/hyperflow"` to a `modules-*` array
- Optionally append [`waybar/style.css`](waybar/style.css) to your stylesheet

---

## Install it with your AI agent

Paste this into Claude / pi / codex / opencode / whatever agent you run:

```text
Install hyperflow on this Hyprland machine: https://github.com/iamanishx/hyperflow

Steps:
1. Install dependencies: alsa-utils curl wl-clipboard wtype ffmpeg pipewire-utils python3
2. Clone the repo and run ./install.sh
3. Ask me for my Azure Speech endpoint + key (Azure AI Speech resource) and write them to ~/.config/hyperflow/env with chmod 600 — never echo the key anywhere
4. Add hold-to-talk binds to ~/.config/hypr/hyprland.conf:
   bind  = , mouse:276, exec, hyperflow start
   bindr = , mouse:276, exec, hyperflow stop
   (verify my mouse's side-button code first — check with wev; 274/275/276 vary)
5. Add the waybar module from waybar/module.jsonc to my bar config, validate the JSONC, and reload waybar
6. Run hyprctl reload, then do a start/stop cycle and verify ~/.cache/hyperflow/status.json flips active → inactive
7. Report what you changed
```

---

## How it works

```
hyprland bind → arecord (16 kHz mono wav) → Azure fast transcription
→ combinedPhrases → wl-copy → hyprctl sendshortcut (paste) → done
```

That's the whole program. The status file at `~/.cache/hyperflow/status.json` is
hyprwhspr-compatible JSON, so the waybar module is just a `cat` on an interval.

## Tips

- **Hold a beat before speaking** — any mic stream needs ~a second to warm up; instant tap-release captures nothing (you'll get a notification).
- **Code-mixed speech**: keep your languages in `AZURE_STT_LOCALES` (e.g. `en-US,en-IN,hi-IN`). Detection happens per phrase.
- Debug without pasting: `HYPERFLOW_NO_PASTE=1 hyperflow toggle` — transcript lands on the clipboard only.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Nothing happens on press | `hyperflow start` in a terminal — look for config errors |
| "Hold a bit longer" | you tapped; hold ≥1s while speaking |
| "No speech detected" | check mic: `arecord -d 3 /tmp/t.wav && pw-play /tmp/t.wav` |
| Bar icon stuck | `cat ~/.cache/hyperflow/status.json` |
| Config errors | `cat ~/.config/hyperflow/env` — endpoint and key both set? |

## License

MIT