# antono2.audio

Audio playback for V applications, with decoded or streamed sounds, spatial
voices and a silent backend for tests. The native engine is
[miniaudio 0.11.25](https://github.com/mackron/miniaudio/tree/0.11.25), with
[stb_vorbis 1.22](thirdparty/stb_vorbis/README.md) for Ogg Vorbis.

**0.1.0 is an initial development release.**
The API may change before 1.0. Linux is the first runtime validation target;
macOS and Windows device playback still need platform testing.

## What it does

- Load WAV or Ogg Vorbis files into named voices, decoded in memory or streamed.
- Play from the beginning, stop, loop, pause the engine and control master or
  per-voice gain.
- Position sounds and the listener in 3D.
- Reuse a bounded pool of 1–64 loaded spatial voices.
- Ignore duplicate or older cue numbers in an ordered event stream.
- Exercise voice ownership and control logic without opening a sound device.

It does not provide recording, MP3/FLAC decoding, a full miniaudio binding,
individual-voice pause/resume or a public seek API. The silent
backend does not advance the playback clock or render samples.

## Requirements

The tested compiler is V 0.5.2 at
`c9b806b294234408af3794f419439599a293a0ea`, in ordinary and `-new-compiler`
modes. Use a C compiler and archiver (`cc` and `ar` on Linux/macOS). The V
compiler itself must already be built. There are no other V module dependencies.

Native playback needs a working OS audio device or audio service. Tests use the
silent backend and do not need audio hardware. On Linux, miniaudio loads the
available audio backend dynamically; no separate audio development headers are
needed for this build.

## Install and run

Install from [VPM](https://vpm.vlang.io/packages/antono2.audio) and build the native
archive once (replace the directory if you use a custom `VMODULES`):

```sh
v install antono2.audio
cd "$HOME/.vmodules/antono2/audio"
v run scripts/build_native_audio.vsh
v -nocache run examples/silent playback/testdata/tone440.ogg
v -nocache run examples/playback playback/testdata/tone440.ogg
# Hear three pulses on the left, in the centre, then on the right.
v -nocache run examples/spatial playback/testdata/tone440.ogg
# Stream a longer file; the example stops after at most five seconds.
v -nocache run examples/playback /path/to/music.ogg --stream
```

The audible example uses 15% master gain. It opens the default output device.
The bundled tone lasts 0.1 seconds; supply your own longer WAV/OGG for playback
and streaming checks. See [BUILDING.md](BUILDING.md) for Windows, tool overrides,
and validation from any checkout location.

```v
import antono2.audio.playback

mut audio := playback.new_audio(playback.AudioConfig{ volume: 0.15 })!
defer { audio.shutdown() }
audio.load('effect', 'effect.ogg', playback.SoundConfig{ spatial: false })!
audio.play('effect')!
// Keep your application's event loop running while the sound plays.
```

## Ownership and scope

Keep one `Audio` instance alive while its sounds are in use. `shutdown()` frees
all loaded sounds and the native engine; repeated shutdown is safe. There is
currently no individual unload operation. Serialize calls to this wrapper in
your application; concurrent control calls are not a supported contract.

`info(id)` reports channels and sample rate. Check `length_known` before using
`frames`: streamed decoders may return an unknown total length (`false`, zero).

`play(id)` stops and rewinds that voice before starting it. `set_paused()` pauses
or resumes the whole device, and is a no-op for the silent backend. Gains must be
finite and within `[0, 1]`. Supply finite spatial coordinates and a meaningful
listener orientation.

`SpatialVoicePool` keeps caller-owned voice IDs, preferring idle voices and
replacing active voices round-robin when full. Load every voice into the same
live `Audio` instance first. Selection advances only after successful playback;
the pool does not allocate decoders, own the device or assign sound priorities.

`CueWatermark` admits each increasing nonzero sequence at most once for one
caller-owned ordered stream. Restore it from the last committed sequence.
Rejected/failed playback is not retried automatically. It is not event
authentication, an out-of-order buffer or simulation authority. The
[silent example](examples/silent/main.v) combines both helpers.

## Development

```sh
v run scripts/test.vsh
```

This builds the native archive, stages a clean isolated module layout, runs all
tests in both compiler modes, and builds all three examples. It runs only the
silent example. See [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md).

## License

Original V code, examples and generated test tone: [MIT](LICENSE).
Vendored sources retain their own licenses; see
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
