# Third-party notices

The root MIT license covers original package code, examples and the generated
test fixture. It does not replace the notices on the following vendored code.

## miniaudio 0.11.25

Upstream: https://github.com/mackron/miniaudio/tree/0.11.25

`thirdparty/miniaudio/miniaudio.h` is used under the MIT-0 alternative in the
[included upstream license](thirdparty/miniaudio/LICENSE). Its recorded SHA-256
is `ac7af4de748b7e26b777f37e01cee313a308a7296a3eb080e2906b320cc55c89`.

## stb_vorbis 1.22

Upstream revision: `1ee679ca2ef753a528db5ba6801e1067b40481b8` of
https://github.com/nothings/stb

`thirdparty/stb_vorbis/stb_vorbis.c` retains its upstream notice and dual license
text. The accompanying declarations header is extracted from the same upstream
source and retains its upstream attribution. The [vendored README](thirdparty/stb_vorbis/README.md) contains the MIT
notice. No proprietary game audio is included.

## Generated test sound

`playback/testdata/tone440.ogg` is a 0.1-second mono 440 Hz synthetic sine at
48 kHz, generated with FFmpeg for testing. It is original fixture data, not an
excerpt from a recording or game. Its use is covered by the root MIT license.
