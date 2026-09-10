# Broadcast Radio Skill

## Purpose
Provides broadcast radio engineering expertise covering playout automation (Liquidsoap), streaming servers (Icecast), media transcoding (FFmpeg), audio processing, stream monitoring, failover, and media AI (Whisper transcription, speaker diarization). Enables building and operating internet radio stations, podcast distribution, and broadcast automation systems.

## When to Activate
- Building or operating internet radio stations
- Configuring Liquidsoap playout automation
- Setting up Icecast streaming servers
- Transcoding audio/video with FFmpeg
- Implementing stream monitoring or failover
- Audio loudness normalization (EBU R128, ATSC A/85)
- Whisper transcription or speaker diarization
- HLS/DASH live streaming
- Radio scheduling (clockwheel, rotation)

## Core Knowledge

### Broadcast Architecture
```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐
│  Media       │    │  Liquidsoap  │    │   Icecast    │
│  Library     │───▶│  Playout     │───▶│   Server     │───▶ Listeners
│  (files/db)  │    │  Engine      │    │   (mounts)   │
└─────────────┘    └──────────────┘    └──────────────┘
       │                  │                     │
       ▼                  ▼                     ▼
  ┌─────────┐      ┌──────────┐          ┌──────────┐
  │ Content │      │ Schedule │          │ Monitor  │
  │ CMS     │      │ Engine   │          │ & Alerts │
  └─────────┘      └──────────┘          └──────────┘
```

### Liquidsoap Scripting
```liquidsoap
# ── Source Configuration ──────────────────────────────────────
# Playlist with randomization
playlist = playlist(
  mode="randomize",
  reload=3600,            # Reload list every hour
  reload_mode="watch",
  "/var/radio/playlists/main.m3u"
)

# Jingle playlist
jingles = playlist(
  mode="randomize",
  "/var/radio/playlists/jingles.m3u"
)

# Fallback (emergency audio)
fallback = single("/var/radio/fallback.mp3")

# Live input (for live shows)
live = input.harbor(
  "live",
  port=8000,
  password="live_password",
  buffer=5.0,
  max=20.0,
  on_start=fun() ->
    log("Live source connected")
  end,
  on_stop=fun() ->
    log("Live source disconnected")
  end
)

# ── Jingle Insertion ─────────────────────────────────────────
# Insert jingle every 3 songs (rotation)
with_jingles = rotate(
  weights=[1, 3],
  [jingles, playlist]
)

# ── Crossfade ────────────────────────────────────────────────
radio = crossfade(
  duration=3.0,
  with_jingles
)

# ── Live Override ─────────────────────────────────────────────
# Switch to live when connected, fall back to playlist
radio = fallback(
  track_sensitive=false,
  [live, radio, fallback]
)

# ── Metadata Update ──────────────────────────────────────────
def update_metadata(m)
  # Strip path, keep filename
  title = string.replace(
    pattern="\\.mp3$",
    replace="",
    s=basename(m)
  )
  [
    ("title", title),
    ("genre", "Internet Radio"),
    ("url", "https://mystation.example.com")
  ]
end

radio = on_metadata(update_metadata, radio)

# ── Output to Icecast ────────────────────────────────────────
output.icecast(
  %mp3(
    samplerate=44100,
    stereo=true,
    bitrate=128,
    icy_metadata="title,genre"
  ),
  host="localhost",
  port=8000,
  password="hackme",
  mount="/stream.mp3",
  name="My Internet Radio",
  description="24/7 Internet Radio Station",
  genre="Various",
  url="https://mystation.example.com",
  public=true,
  radio
)

# ── HLS Output (optional) ────────────────────────────────────
output.file.hls(
  %ffmpeg(format="segment",
    %video codec="libx264",
    %audio codec="aac",
    advanced="-hls_time 6 -hls_list_size 60"
  ),
  "/var/radio/hls/stream.m3u8",
  radio
)
```

### Icecast Configuration
```xml
<!-- /etc/icecast2/icecast.xml -->
<icecast>
    <location>Earth</location>
    <admin>admin@mystation.example.com</admin>

    <limits>
        <clients>100</clients>
        <sources>5</sources>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>10</source-timeout>
        <burst-on-connect>1</burst-on-connect>
        <burst-size>65535</burst-size>
    </limits>

    <authentication>
        <source-password>hackme</source-password>
        <relay-password>hackme</relay-password>
        <admin-user>admin</admin-user>
        <admin-password>changeme</admin-password>
    </authentication>

    <hostname>mystation.example.com</hostname>

    <listen-socket>
        <port>8000</port>
        <!-- TLS: uncomment for HTTPS streaming -->
        <!-- <ssl>1</ssl> -->
        <!-- <ssl certificate>/etc/letsencrypt/live/mystation.example.com/fullchain.pem</ssl> -->
        <!-- <ssl private-key>/etc/letsencrypt/live/mystation.example.com/privkey.pem</ssl> -->
    </listen-socket>

    <mount>
        <mount-name>/stream.mp3</mount-name>
        <fallback-mount>/fallback.mp3</fallback-mount>
        <fallback-override>1</fallback-override>
        <fallback-when-full>1</fallback-when-full>
        <hidden>0</hidden>
        <public>1</public>
        <stream-name>My Internet Radio</stream-name>
        <stream-description>24/7 Internet Radio Station</stream-description>
        <stream-url>https://mystation.example.com</stream-url>
        <genre>Various</genre>
        <bitrate>128</bitrate>
        <type>application/mp3</type>
    </mount>

    <mount>
        <mount-name>/stream.aac</mount-name>
        <fallback-mount>/stream.mp3</fallback-mount>
        <hidden>0</hidden>
        <public>1</public>
    </mount>

    <fileserve>1</fileserve>

    <paths>
        <basedir>/usr/share/icecast2</basedir>
        <logdir>/var/log/icecast2</logdir>
        <webroot>/usr/share/icecast2/web</webroot>
        <adminroot>/usr/share/icecast2/admin</adminroot>
        <alias source="/" destination="/status.xsl"/>
    </paths>

    <logging>
        <accesslog>access.log</accesslog>
        <errorlog>error.log</errorlog>
        <loglevel>3</loglevel>
        <logsize>10000</logsize>
    </logging>
</icecast>
```

### FFmpeg Audio Processing
```bash
# ── Transcoding ───────────────────────────────────────────────
# MP3 → AAC
ffmpeg -i input.mp3 -c:a aac -b:a 128k output.m4a

# WAV → MP3 (with metadata)
ffmpeg -i input.wav -codec:a libmp3lame -b:a 192k \
  -metadata title="My Song" \
  -metadata artist="Artist" \
  output.mp3

# Resample to 44.1kHz stereo
ffmpeg -i input.mp3 -ar 44100 -ac 2 output.mp3

# ── Loudness Normalization (EBU R128) ─────────────────────────
# Two-pass loudness normalization
ffmpeg -i input.mp3 -af loudnorm=I=-16:TP=-1.5:LRA=11 \
  -c:a libmp3lame -b:a 192k output_normalized.mp3

# Measure loudness first
ffmpeg -i input.mp3 -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json \
  -f null /dev/null

# ── HLS Live Streaming ───────────────────────────────────────
ffmpeg -i rtp://239.0.0.1:5004 \
  -c:a aac -b:a 128k \
  -hls_time 6 \
  -hls_list_size 60 \
  -hls_flags delete_segments \
  -hls_segment_filename /var/radio/hls/segment_%03d.ts \
  /var/radio/hls/stream.m3u8

# ── Audio Filters ─────────────────────────────────────────────
# Fade in/out
ffmpeg -i input.mp3 -af "afade=t=in:ss=0:d=3,afade=t=out:st=27:d=3" output.mp3

# Normalize volume
ffmpeg -i input.mp3 -af "volume=2.0" output.mp3

# Trim (start at 30s, duration 60s)
ffmpeg -i input.mp3 -ss 30 -t 60 -c copy output.mp3

# Speed change (1.5x)
ffmpeg -i input.mp3 -filter:a "atempo=1.5" output.mp3

# Convert to mono
ffmpeg -i input.mp3 -ac 1 output_mono.mp3

# ── Metadata ──────────────────────────────────────────────────
# Display metadata
ffprobe -v quiet -print_format json -show_format input.mp3

# Update metadata (MP3)
ffmpeg -i input.mp3 -codec copy -metadata title="New Title" output.mp3

# Strip metadata
ffmpeg -i input.mp3 -codec copy -metadata:s:a:0 title= -metadata artist= output.mp3
```

### Clockwheel / Rotation Scheduling
```python
from dataclasses import dataclass
from typing import List, Optional
import random
import time

@dataclass
class ProgramSlot:
    name: str
    duration_minutes: int
    content_type: str  # "music", "jingle", "ad", "talk"
    category: Optional[str] = None
    weight: int = 1

@dataclass
class Clockwheel:
    """Radio clockwheel scheduler — programs rotate in fixed positions."""
    slots: List[ProgramSlot]
    current_index: int = 0

    def next_slot(self) -> ProgramSlot:
        slot = self.slots[self.current_index]
        self.current_index = (self.current_index + 1) % len(self.slots)
        return slot

# ── Example: 2-Hour Clockwheel ────────────────────────────────
hour_wheel = Clockwheel(slots=[
    ProgramSlot("Top of Hour Jingle", 1, "jingle"),
    ProgramSlot("News Headlines", 3, "talk"),
    ProgramSlot("Music Block A", 15, "music", "pop"),
    ProgramSlot("Jingle", 1, "jingle"),
    ProgramSlot("Music Block B", 15, "music", "rock"),
    ProgramSlot("Ad Break", 2, "ad"),
    ProgramSlot("Music Block C", 15, "music", "jazz"),
    ProgramSlot("Jingle", 1, "jingle"),
    ProgramSlot("Music Block D", 15, "music", "electronic"),
    ProgramSlot("Talk Segment", 5, "talk"),
    ProgramSlot("Ad Break", 2, "ad"),
    ProgramSlot("Music Block E", 15, "music", "indie"),
    ProgramSlot("Jingle", 1, "jingle"),
    ProgramSlot("Music Block F", 15, "music", "alternative"),
    ProgramSlot("Station ID", 1, "jingle"),
    ProgramSlot("Music Block G", 14, "music", "classics"),
])

# ── Rotation (Weighted Random from Category) ──────────────────
class RotationPool:
    """Weighted random selection within a category."""
    def __init__(self):
        self.pools = {}

    def add_track(self, category: str, path: str, weight: int = 1):
        if category not in self.pools:
            self.pools[category] = []
        self.pools[category].append({"path": path, "weight": weight})

    def select(self, category: str) -> Optional[str]:
        pool = self.pools.get(category, [])
        if not pool:
            return None
        weights = [t["weight"] for t in pool]
        return random.choices(pool, weights=weights, k=1)[0]["path"]

# Usage
rotation = RotationPool()
rotation.add_track("pop", "/music/pop/song1.mp3", weight=5)
rotation.add_track("pop", "/music/pop/song2.mp3", weight=3)
rotation.add_track("pop", "/music/pop/song3.mp3", weight=1)

# Higher weight = played more frequently
for _ in range(5):
    print(rotation.select("pop"))
```

### Stream Monitoring
```bash
# ── Check stream status ───────────────────────────────────────
# Icecast status page (XML)
curl -s http://localhost:8000/status.xsl | xmllint --format -

# Check mount point metadata
curl -s -I http://localhost:8000/stream.mp3 | grep -i icy-

# Check listener count
curl -s http://localhost:8000/status-json.xsl | python3 -m json.tool

# ── FFmpeg stream probe ──────────────────────────────────────
ffprobe -v quiet -print_format json -show_format -show_streams \
  http://localhost:8000/stream.mp3

# ── Stream health check script ───────────────────────────────
# check_stream.sh — call from cron every 5 minutes
#!/bin/bash
STREAM_URL="http://localhost:8000/stream.mp3"
ALERT_EMAIL="admin@example.com"
TIMEOUT=10

STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$STREAM_URL")

if [ "$STATUS" != "200" ]; then
    echo "Stream DOWN (HTTP $STATUS) at $(date)" | \
      mail -s "ALERT: Stream Down" $ALERT_EMAIL
    # Auto-restart Icecast if down
    systemctl restart icecast2
fi

# ── Loudness monitoring (continuous) ──────────────────────────
ffmpeg -i http://localhost:8000/stream.mp3 \
  -af loudnorm=I=-16:TP=-1.5:print_format=json \
  -f null /dev/null 2>&1 | grep -A20 "Parsed_loudnorm"
```

### Whisper Transcription & Speaker Diarization
```python
import whisper
from pyannote.audio import Pipeline
import torch

# ── Whisper Transcription ─────────────────────────────────────
def transcribe_audio(audio_path: str, model_size: str = "base") -> dict:
    """Transcribe audio using OpenAI Whisper."""
    model = whisper.load_model(model_size)
    result = model.transcribe(audio_path)

    return {
        "text": result["text"],
        "language": result["language"],
        "segments": [
            {
                "start": seg["start"],
                "end": seg["end"],
                "text": seg["text"],
            }
            for seg in result["segments"]
        ],
    }

# ── Speaker Diarization ──────────────────────────────────────
def diarize_speakers(audio_path: str) -> list:
    """Identify who spoke when in audio."""
    pipeline = Pipeline.from_pretrained(
        "pyannote/speaker-diarization-3.1",
        use_auth_token="YOUR_HF_TOKEN"
    )
    diarization = pipeline(audio_path)

    speakers = []
    for turn, _, speaker in diarization.itertracks(yield_label=True):
        speakers.append({
            "speaker": speaker,
            "start": turn.start,
            "end": turn.end,
            "duration": turn.end - turn.start,
        })
    return speakers

# ── Combined: Transcription + Diarization ─────────────────────
def transcribe_with_speakers(audio_path: str) -> dict:
    """Full transcription with speaker identification."""
    # Get transcription segments
    model = whisper.load_model("base")
    result = model.transcribe(audio_path, word_timestamps=True)

    # Get speaker diarization
    diarization_pipeline = Pipeline.from_pretrained(
        "pyannote/speaker-diarization-3.1",
        use_auth_token="YOUR_HF_TOKEN"
    )
    diarization = diarization_pipeline(audio_path)

    # Merge: assign speaker to each transcription segment
    annotated_segments = []
    for seg in result["segments"]:
        seg_mid = (seg["start"] + seg["end"]) / 2
        speaker = "unknown"
        for turn, _, spk in diarization.itertracks(yield_label=True):
            if turn.start <= seg_mid <= turn.end:
                speaker = spk
                break
        annotated_segments.append({
            "speaker": speaker,
            "start": seg["start"],
            "end": seg["end"],
            "text": seg["text"],
        })

    return {
        "text": result["text"],
        "segments": annotated_segments,
    }
```

## Workflow

### Setting Up an Internet Radio Station
```
1. Prepare Media Library
   - Organize audio files by category
   - Normalize loudness (EBU R128, target -16 LUFS)
   - Create playlists (.m3u files)

2. Configure Icecast
   - Install: apt install icecast2
   - Edit /etc/icecast2/icecast.xml (mounts, auth, limits)
   - Start: systemctl enable --now icecast2

3. Configure Liquidsoap
   - Write .liq script (playlist + jingles + live + fallback)
   - Test: liquidsoap --check script.liq
   - Run: liquidsoap script.liq

4. Monitor & Maintain
   - Set up stream health checks (cron + curl)
   - Monitor listener counts
   - Review logs: /var/log/icecast2/error.log
```

### Audio Normalization Pipeline
```bash
#!/bin/bash
# normalize_library.sh — normalize all MP3s to EBU R128
INPUT_DIR="/var/radio/music"
OUTPUT_DIR="/var/radio/music_normalized"

mkdir -p "$OUTPUT_DIR"

for f in "$INPUT_DIR"/*.mp3; do
    filename=$(basename "$f")
    echo "Normalizing: $filename"
    ffmpeg -i "$f" -af loudnorm=I=-16:TP=-1.5:LRA=11 \
      -c:a libmp3lame -b:a 192k \
      "$OUTPUT_DIR/$filename"
done
```

## Tools

### Package Installation
```bash
# Liquidsoap
# Ubuntu/Debian: apt install liquidsoap liquidsoap-plugin-*
# Or from opam: opam install liquidsoap

# Icecast
sudo apt install icecast2

# FFmpeg
sudo apt install ffmpeg

# Whisper (Python)
pip install openai-whisper

# Speaker diarization
pip install pyannote.audio

# FFprobe (included with FFmpeg)
# Usually bundled, verify: ffprobe -version
```

### Command-Line Utilities
```bash
# Liquidsoap syntax check
liquidsoap --check script.liq

# Liquidsoap run
liquidsoap script.liq

# Icecast config validation
icecast2 -c /etc/icecast2/icecast.xml --configure-test 2>&1

# Icecast start
sudo systemctl enable --now icecast2

# FFmpeg probe
ffprobe -v quiet -print_format json -show_format input.mp3

# FFmpeg loudness scan
ffmpeg -i input.mp3 -af loudnorm=I=-16:TP=-1.5:print_format=json \
  -f null /dev/null 2>&1

# Stream health check
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/stream.mp3

# Check Icecast listeners
curl -s http://localhost:8000/status-json.xsl | python3 -m json.tool

# Whisper transcription CLI
whisper audio.mp3 --model base --output_format txt
```

### MCP Integration
```json
{
  "mcpServers": {
    "broadcast-radio": {
      "command": "npx",
      "args": ["-y", "broadcast-radio-mcp"],
      "description": "Radio playout and stream management MCP server",
      "tools": [
        "stream_status",
        "check_listener_count",
        "trigger_ad_break",
        "get_current_track",
        "get_schedule"
      ]
    }
  }
}
```

## Best Practices

1. **Always normalize loudness before playout**: Target -16 LUFS (streaming) or -23 LUFS (broadcast). Use `loudnorm` two-pass for accuracy.

2. **Use fallback chains**: Never let silence reach listeners. Configure `fallback` with emergency audio in Liquidsoap.

3. **Burst on connect**: Enable `<burst-on-connect>1</burst-on-connect>` in Icecast for instant playback on connect.

4. **Limit source connections**: Set `<sources>5</sources>` to prevent unauthorized sources.

5. **Monitor stream health**: Set up cron-based health checks. Alert on HTTP errors or silence.

6. **Rotate passwords**: Change Icecast source/admin passwords regularly. Never use defaults.

7. **Use mount-specific fallbacks**: Each mount should have its own fallback to prevent cascade failures.

8. **Test Liquidsoap scripts**: Always run `liquidsoap --check script.liq` before deploying.

9. **Segment HLS properly**: Use `-hls_time 6` for 6-second segments (balances latency vs overhead).

10. **Log everything**: Configure Icecast access/error logs and Liquidsoap logging for debugging.

## Anti-patterns

- ❌ Sending silence to listeners (no fallback configured)
- ❌ Using default Icecast passwords (`hackme`) in production
- ❌ Not normalizing loudness (inconsistent volume between tracks)
- ❌ Running Liquidsoap as root (use dedicated user)
- ❌ Not monitoring listener counts (missing outage detection)
- ❌ Hardcoding stream passwords in scripts (use env vars or config files)
- ❌ Ignoring Icecast error logs (missed auth failures, mount issues)
- ❌ Using high HLS segment count without storage management (disk fills up)
- ❌ Skipping `liquidsoap --check` before deploying (syntax errors in production)
- ❌ Not setting `<burst-size>` appropriately (choppy initial playback)

## Verification

### Liquidsoap
```bash
liquidsoap --check script.liq       # Syntax check
liquidsoap --version                # Verify installation
liquidsoap -c 'print("OK")'        # Minimal test
```

### Icecast
```bash
icecast2 --help                     # Verify installation
sudo systemctl status icecast2     # Check service status
curl -s http://localhost:8000/ | head -5  # Status page accessible
```

### FFmpeg
```bash
ffmpeg -version                     # Verify installation
ffprobe -version                    # Verify probe tool
ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -t 1 /tmp/test.mp3  # Test encode
```

### Whisper
```bash
python3 -c "import whisper; print(whisper.available_models())"
```

## Examples

### Complete Liquidsoap Playout Script
```liquidsoap
#!/usr/bin/liquidsoap

# ── Configuration ─────────────────────────────────────────────
set("log.file.path", "/var/log/liquidsoap/radio.log")
set("log.level", 3)
set("server.telnet", true)
set("server.telnet.port", 1234)

# ── Playlists ─────────────────────────────────────────────────
main_playlist = playlist(
  mode="randomize",
  reload=3600,
  reload_mode="watch",
  "/var/radio/playlists/main.m3u"
)

jingle_playlist = playlist(
  mode="randomize",
  "/var/radio/playlists/jingles.m3u"
)

news_playlist = playlist(
  mode="rotate",
  "/var/radio/playlists/news.m3u"
)

ad_playlist = playlist(
  mode="randomize",
  "/var/radio/playlists/ads.m3u"
)

fallback = single("/var/radio/fallback.mp3")

# ── Live Input ────────────────────────────────────────────────
live = input.harbor(
  "live",
  port=8000,
  password="your_live_password",
  buffer=5.0,
  max=20.0
)

# ── Schedule Blocks ───────────────────────────────────────────
# Rotate: jingle → music → jingle → music → ad → repeat
with_jingles = rotate(
  weights=[1, 4],
  [jingle_playlist, main_playlist]
)

with_ads = rotate(
  weights=[8, 1],
  [with_jingles, ad_playlist]
)

# ── Crossfade ────────────────────────────────────────────────
radio = crossfade(
  duration=3.0,
  fun(a, b) ->
    add(normalize=true, [a, b])
  end,
  with_ads
)

# ── Live Override ─────────────────────────────────────────────
radio = fallback(
  track_sensitive=false,
  [live, radio, fallback]
)

# ── Metadata ─────────────────────────────────────────────────
def metadata_update(m)
  title = string.replace(
    pattern="\\.mp3$",
    replace="",
    s=basename(m)
  )
  [
    ("title", title),
    ("genre", "Internet Radio"),
    ("url", "https://mystation.example.com")
  ]
end

radio = on_metadata(metadata_update, radio)

# ── Outputs ──────────────────────────────────────────────────
# MP3 stream (128kbps)
output.icecast(
  %mp3(samplerate=44100, stereo=true, bitrate=128),
  host="localhost",
  port=8000,
  password="hackme",
  mount="/stream.mp3",
  name="My Internet Radio",
  description="24/7 Internet Radio",
  genre="Various",
  url="https://mystation.example.com",
  public=true,
  radio
)

# AAC stream (64kbps — low bandwidth)
output.icecast(
  %fdkaac(channels=2, samplerate=44100, bitrate=64),
  host="localhost",
  port=8000,
  password="hackme",
  mount="/stream.aac",
  name="My Internet Radio (AAC)",
  description="24/7 Internet Radio - Low Bandwidth",
  public=true,
  radio
)

# HLS output
output.file.hls(
  playlist="live.m3u8",
  fallible=true,
  (
    "stream_%02d.ts",
    %ffmpeg(format="segment", %audio(codec="aac", bitrate="128k"))
  ),
  "/var/radio/hls/",
  radio
)
```

### Icecast TLS Setup with Let's Encrypt
```bash
# Install certbot
sudo apt install certbot

# Get certificate
sudo certbot certonly --standalone -d mystation.example.com

# Update icecast.xml with TLS
# Add to <listen-socket>:
#   <ssl>1</ssl>
#   <ssl certificate>/etc/letsencrypt/live/mystation.example.com/fullchain.pem</ssl>
#   <ssl private-key>/etc/letsencrypt/live/mystation.example.com/privkey.pem</ssl>

# Restart Icecast
sudo systemctl restart icecast2

# Auto-renewal cron (certbot handles this by default)
sudo systemctl status certbot.timer
```

### FFmpeg Batch Normalization
```bash
#!/bin/bash
# batch_normalize.sh — EBU R128 normalization for a library
TARGET_LUFS=-16
TARGET_TP=-1.5
TARGET_LRA=11
INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-./normalized}"

mkdir -p "$OUTPUT_DIR"

for f in "$INPUT_DIR"/*.{mp3,wav,flac,m4a}; do
    [ -f "$f" ] || continue
    filename=$(basename "$f")
    echo "Processing: $filename"

    # Pass 1: measure
    STATS=$(ffmpeg -i "$f" -af "loudnorm=I=${TARGET_LUFS}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" \
      -f null /dev/null 2>&1 | grep -A20 '"input_')

    # Pass 2: normalize
    ffmpeg -y -i "$f" \
      -af "loudnorm=I=${TARGET_LUFS}:TP=${TARGET_TP}:LRA=${TARGET_LRA}" \
      -c:a libmp3lame -b:a 192k \
      "$OUTPUT_DIR/$filename" 2>/dev/null

    echo "  → $OUTPUT_DIR/$filename"
done

echo "Done. Normalized $(ls "$OUTPUT_DIR" | wc -l) files."
```
