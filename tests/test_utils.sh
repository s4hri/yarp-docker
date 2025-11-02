#!/usr/bin/env bash
# Env:
#   AUDIO_MUTED=yes|no (default yes)  — mute Pulse sink during paplay
#   ALSA_DEVICE=<pcm>  (default pulse) — e.g., pulse | default | hw:0,0

set -euo pipefail

AUDIO_MUTED="${AUDIO_MUTED:-yes}"
ALSA_DEVICE="${ALSA_DEVICE:-pulse}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "MISSING: $1"; exit 2; }; }
die()  { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

# Hard requirements (no installs, no skips)
need xset
need pactl
need paplay
need aplay
need speaker-test

# 1) X11 (headless)
[[ -n "${DISPLAY:-}" ]] || die "DISPLAY is empty"
xset q >/dev/null 2>&1 || die "Cannot query X server via xset"
ok "X connection (xset q)"

# 2) Pulse/pipewire control + playback (muted by default)
pactl info >/dev/null 2>&1 || die "pactl cannot reach Pulse/pipewire (check PULSE_SERVER/socket)"
ok "Pulse control reachable"

# pick a wav (must exist already)
wav=""
[[ -f /usr/share/sounds/alsa/Front_Center.wav ]] && wav=/usr/share/sounds/alsa/Front_Center.wav
[[ -n "${PULSE_TEST_WAV:-}" && -f "${PULSE_TEST_WAV:-}" ]] && wav="$PULSE_TEST_WAV"
[[ -n "$wav" ]] || die "No test WAV found (provide PULSE_TEST_WAV or install a system sample)"

if [[ "$AUDIO_MUTED" == "yes" ]]; then
  sink="$(pactl get-default-sink 2>/dev/null || pactl info 2>/dev/null | awk -F': ' '/Default Sink/ {print $2}')"
  [[ -n "$sink" ]] || die "Cannot determine default Pulse sink"
  pactl set-sink-mute "$sink" 1 >/dev/null 2>&1 || die "Failed to mute sink"
  paplay "$wav" >/dev/null 2>&1 || { pactl set-sink-mute "$sink" 0 >/dev/null 2>&1 || true; die "paplay failed"; }
  pactl set-sink-mute "$sink" 0 >/dev/null 2>&1 || die "Failed to unmute sink"
  ok "Pulse playback (muted) via paplay"
else
  paplay "$wav" >/dev/null 2>&1 || die "paplay failed"
  ok "Pulse playback via paplay"
fi

# 3) ALSA devices + playback (strict)
aplay -l >/dev/null 2>&1 || die "ALSA devices not visible (aplay -l)"
ok "ALSA devices visible"

# Note: to keep it silent, default ALSA_DEVICE=pulse (requires ALSA->Pulse plugin available)
speaker-test -c 2 -t sine -l 1 -D "$ALSA_DEVICE" >/dev/null 2>&1 || die "speaker-test failed (-D $ALSA_DEVICE)"
ok "ALSA playback (-D $ALSA_DEVICE)"

echo "ALL TESTS PASSED"
