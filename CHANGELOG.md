# Changelog

## 0.1.0 — 2026-11-09

- Decoded and streamed WAV/Ogg Vorbis voices backed by miniaudio 0.11.25.
- Master/per-voice gain, looping, restart, stop, engine pause and 3D positioning.
- Silent engine for tests, bounded reusable spatial voices and ordered cue guards.
- Preserve format information when a streamed decoder cannot report total length,
  exposing `SoundInfo.length_known` instead of failing the whole query.
- Reject non-finite gain, distance and spatial inputs before passing them to C.
- Standalone playback/silent examples and isolated validation in both V modes.

This is an initial development API. Hardware output, latency and performance
are platform-dependent. No stable ABI or API is promised before 1.0.
