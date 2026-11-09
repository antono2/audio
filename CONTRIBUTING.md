# Contributing

Small reproducible bug reports, documentation improvements and focused patches
are welcome. Please discuss new playback features before implementing a large
change; this package deliberately keeps a small API.

For a bug report, include your OS, V revision, C compiler, audio backend, a minimal
program, expected behavior and actual behavior. Use synthetic or redistributable
sound files. Avoid private paths, device identifiers and personal recordings.

For code changes, keep native ownership explicit, document errors, and add a
regression test for behavior that can be verified without hardware. Run
`v run scripts/test.vsh`. For device-facing changes, also test real playback and
state which platforms and devices were actually checked. Format modified V files
with `v fmt`; avoid unrelated formatting changes.

The CI builds and tests on its declared runner platforms. Passing a silent test
is not evidence of hardware output on that platform. Changes to vendored sources
must preserve upstream notices and record their exact revision and provenance.
