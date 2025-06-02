#!/usr/bin/env elixir

# Debug one of the failing MIB files

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

# Test RFC1155-SMI.mib (one of the failed files)
mib_file = "test/fixtures/mibs/working/RFC1155-SMI.mib"

IO.puts("=== Debugging #{Path.basename(mib_file)} ===")

case File.read(mib_file) do
  {:ok, content} ->
    size = byte_size(content)
    lines = String.split(content, "\n") |> length()
    IO.puts("File size: #{size} bytes, #{lines} lines")
    
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