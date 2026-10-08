#!/usr/bin/env bash
# hyperflow installer — native push-to-talk dictation for Hyprland
set -euo pipefail

GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; BOLD=$'\e[1m'; NC=$'\e[0m'
info() { echo "${GREEN}✓${NC} $*"; }
warn() { echo "${YELLOW}!${NC} $*"; }
die()  { echo "${RED}✗ $*${NC}" >&2; exit 1; }

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "${BOLD}hyperflow installer${NC}"
echo

# --- dependencies -------------------------------------------------------------
missing=()
for dep in arecord curl wl-copy wtype ffprobe pw-play python3 hyprctl; do
    command -v "$dep" >/dev/null || missing+=("$dep")
done
if ((${#missing[@]})); then
    warn "missing: ${missing[*]}"
    echo "  ubuntu/debian: sudo apt install alsa-utils curl wl-clipboard wtype ffmpeg pipewire-utils python3"
    die "install the missing dependencies and re-run"
fi
info "dependencies OK"

# --- install the command ------------------------------------------------------
mkdir -p "$HOME/.local/bin"
install -m 755 "$SRC/hyperflow" "$HOME/.local/bin/hyperflow"
info "installed ~/.local/bin/hyperflow"
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) warn "~/.local/bin is not on PATH — add: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

# --- sounds -------------------------------------------------------------------
ASSETS="$HOME/.local/share/hyperflow/assets"
mkdir -p "$ASSETS"
if [ ! -f "$ASSETS/ping-up.ogg" ]; then
    ffmpeg -hide_banner -loglevel error -f lavfi -i "sine=frequency=1050:duration=0.07" \
        -af "volume=0.35" -c:a libvorbis -q:a 3 "$ASSETS/ping-up.ogg" -y
    ffmpeg -hide_banner -loglevel error -f lavfi -i "sine=frequency=520:duration=0.11" \
        -af "volume=0.35" -c:a libvorbis -q:a 3 "$ASSETS/ping-down.ogg" -y
    info "generated start/stop sounds"
else
    info "sounds already present"
fi

# --- config -------------------------------------------------------------------
CFG="$HOME/.config/hyperflow/env"
mkdir -p "$(dirname "$CFG")"
if [ ! -f "$CFG" ]; then
    cat > "$CFG" <<'EOF'
# hyperflow config — keep this file private (chmod 600)
# Azure AI Speech resource (Speech → Speech to text → "fast transcription" endpoint)
AZURE_STT_ENDPOINT=https://<your-resource>.cognitiveservices.azure.com
AZURE_SPEECH_KEY=<your key>
# auto language detection candidates (per phrase — great for code-mixed speech)
AZURE_STT_LOCALES=en-US,hi-IN
EOF
    chmod 600 "$CFG"
    warn "created $CFG — fill in your Azure Speech endpoint + key"
else
    info "config exists, left untouched"
fi

# --- done ---------------------------------------------------------------------
echo
echo "${BOLD}next steps:${NC}"
echo "  1. edit $CFG (endpoint + key)"
echo "  2. Hyprland hold-to-talk bind (add to hyprland.conf):"
echo
echo '       bind  = , mouse:276, exec, hyperflow start   # hold side button'
echo '       bindr = , mouse:276, exec, hyperflow stop    # release to type'
echo
echo '     or a keyboard hold:'
echo
echo '       bind  = ALT, GRAVE, exec, hyperflow start'
echo '       bindr = ALT, GRAVE, exec, hyperflow stop'
echo
echo "  3. Waybar indicator: copy snippets from waybar/ into your config"
echo "  4. hyprctl reload, then hold the button and talk"
echo
info "done — say something nice"