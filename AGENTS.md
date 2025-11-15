# Agent Instructions for Bucketixir

## Build/Test Commands
- Build: `mix escript.build`
- Test all: `mix test`
- Test single file: `mix test path/to/test_file.exs`
- Test single test: `mix test path/to/test_file.exs:line_number`
- Lint: `mix credo`

## Code Style Guidelines
- **Formatting**: Use default Elixir formatter (`mix format`)
- **Naming**: Modules PascalCase, functions/variables snake_case
- **Documentation**: Use `@moduledoc` for modules, `@doc` for functions
- **Types**: Use `@spec` for function specifications
- **Imports**: Use `alias` for module aliases, group at top of file
- **Error Handling**: Return `{:ok, result} | {:error, reason}` tuples
- **Output**: `IO.puts()` for stdout, `IO.puts(:standard_error, ...)` for errors
- **Exit**: Use `System.halt(1)` for errors (skip in test env with `unless Mix.env() == :test`)
- **Input Sanitization**: Use `String.trim()` for user inputs
- **HTTP/S3**: Use `Req` + `ReqS3` instead of ExAws (no region validation needed)
- **Config**: Store in YAML format at `~/.bucketixir.yaml`
- **CLI**: Use Optimus for command-line parsing</content>
<parameter name="filePath">/home/franky/sw/elixir/bucketixir/AGENTS.md