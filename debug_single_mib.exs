#!/usr/bin/env elixir

# Debug a single MIB file with detailed error reporting

mib_file = "DOCS-IF-MIB"
mibs_dir = "test/fixtures/mibs/docsis"
file_path = Path.join(mibs_dir, mib_file)

IO.puts("=== Debugging #{mib_file} ===")

case File.read(file_path) do
  {:ok, content} ->
    IO.puts("File size: #{byte_size(content)} bytes")
    
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        case SnmpLib.MIB.Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts("✓ Parsing successful!")
            IO.puts("MIB name: #{mib.name}")
            IO.puts("Definitions: #{length(mib.definitions)}")
          {:error, errors} when is_list(errors) ->
            IO.puts("✗ Parsing failed with #{length(errors)} errors:")
            Enum.each(errors, fn error ->
              IO.puts("  - #{inspect(error)}")
            end)
          {:error, error} ->
            IO.puts("✗ Parsing failed:")
            IO.puts("  #{inspect(error)}")
        end
      {:error, reason} ->
        IO.puts("✗ Tokenization failed: #{reason}")
    end
  {:error, reason} ->
    IO.puts("✗ File read failed: #{reason}")
end