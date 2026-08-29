# AGENTS.md

Guidance for AI agents working in the Sugiyama.jl repository.

This is a bare-bones starting point. Expand it with project-specific paths,
commands, and conventions as the package grows.

## Overview

Sugiyama.jl is a Julia package. Source lives in `src/` and tests in `test/`.

## Development commands

- **Test**: `julia --project=. -e "using Pkg; Pkg.test()"`
- **REPL with the project active**: `julia --project=.`

### Testing via julia-mcp

When the [julia-mcp](https://github.com/aplavin/julia-mcp) server is available,
prefer it over spawning new Julia processes — the session stays alive between
calls, avoiding recompilation. Use `<full path>/test` as `env_path`, load the
runner once with `using TestItemRunner`, then run filtered tests:

- All tests: `@run_package_tests verbose=false`
- By test name: `@run_package_tests verbose=false filter=ti->contains(ti.name, "some name")`
- By filename: `@run_package_tests verbose=false filter=ti->contains(ti.filename, "some-file")`

## Conventions

- Match the existing code style in `src/`.
- Add or update tests in `test/` for any behavior change.
- Keep public API changes documented.
