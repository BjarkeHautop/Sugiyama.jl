# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog],
and this project adheres to [Semantic Versioning].

## [1.0.1] - 2026-10-12

### Bug fixes

- Fix `BoundsError` with `minimum_length > 1` when an edge spanned exactly `minimum_length` ranks.

### Other changes

- Package now compiles under `--trim=safe` (JuliaC).

## [1.0.0] - 2026-09-04

### New features

- Added `sugiyama_paths()` to get the routing used via the dummy nodes.

### Other changes

- Improved documentation

## [0.1.0] - 2026-09-04

- Initial release

<!-- Links -->

[keep a changelog]: https://keepachangelog.com/en/1.1.0/
[semantic versioning]: https://semver.org/spec/v2.0.0.html
