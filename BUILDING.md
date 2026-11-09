# Building and validation

## Compiler

Validation uses V 0.5.2, revision
`c9b806b294234408af3794f419439599a293a0ea`, with VC
`21490f7811a2dd366c3daa39bef8e53c1e3e5727` and TinyCC
`d6e7ac1b1bcc98aed734a6ecbfa8509f24606c74` when using V's default C compiler.
The CI bootstrap uses the same V and VC revisions with the system C compiler.
Newer compilers may work but are not implied by this validation record.

Use `-nocache` when compiling applications importing this package with the pinned
compiler. Its module cache can omit the native miniaudio typedef includes from
shared generated C units. `scripts/test.vsh` applies this option automatically
for both modes; it does not allow a fallback to another compiler.

## Native library

Run `v run scripts/build_native_audio.vsh` before compiling an application.
It builds `.cache/native/libantono2_audio.a` from the vendored C sources.
Rebuild after changing operating system, architecture, C ABI, native source or
compiler. Do not copy this archive between platforms.

`ANTONO2_AUDIO_CC` and `ANTONO2_AUDIO_AR` override executable paths for the C
compiler and archiver. They are paths, not shell commands or lists of flags.
The script does not download dependencies or change the system configuration.

Linux/macOS: install a C toolchain providing `cc` and `ar` (for example GCC and
binutils on Linux, or Xcode command-line tools on macOS).

Windows: use a compatible MinGW-w64 GCC/`ar` toolchain and compile V applications
with the same GCC toolchain. In PowerShell, for example:

```powershell
$env:ANTONO2_AUDIO_CC = 'C:\mingw64\bin\gcc.exe'
$env:ANTONO2_AUDIO_AR = 'C:\mingw64\bin\ar.exe'
$env:ANTONO2_AUDIO_V_CC = $env:ANTONO2_AUDIO_CC
v -cc $env:ANTONO2_AUDIO_CC run scripts/test.vsh
```

Adjust paths to your installation. The existing MSVC-compatible link directive
is retained, but the release does not claim a validated MSVC archive build.
Windows and macOS hardware playback are not yet verified.

## Standalone validation

From any checkout location, `v run scripts/test.vsh` builds the native archive,
copies only the package's required files into a temporary `antono2/audio`
namespace, and sets `VMODULES` to that isolated directory. It cannot accidentally
use another installed copy of this package. It runs all playback tests with the
ordinary and strict new compiler, builds all three examples in both modes, and
checks the silent example. The temporary directory is removed afterwards.

Set `VJOBS=2` to bound parallel test workers. `V_MACOS_V3_NO_FALLBACK=1` prevents
fallback during new-compiler validation. `ANTONO2_AUDIO_V_CC` optionally selects
the C compiler used by the V validation subprocesses (use the same MinGW GCC
path on Windows). Successful silent tests establish control/ownership behavior,
not audible output quality or real-time performance.

## Manual playback

Install the package in the namespace shown in the README, then run:

```sh
v -nocache run examples/playback /path/to/test.wav
v -nocache run examples/playback /path/to/test.ogg --stream
v -nocache run examples/spatial playback/testdata/tone440.ogg
```

The playback example stops after at most five seconds and uses 15% master gain.
The six-second spatial example uses the same gain and a mono file. It plays
three pulses on the left, three in the centre and three on the right; stereo
headphones make the placement easier to hear. It does not record audio.
Check both decoded and streamed playback, device startup, clean exit and the absence
of glitches. Report OS, V revision, C compiler, audio backend and reproduction
steps with any issue. Do not attach recordings containing private conversation.
