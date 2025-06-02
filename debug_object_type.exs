#!/usr/bin/env elixir

# Debug script for OBJECT-TYPE parsing issues

{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

IO.puts("Tokenization successful - #{length(tokens)} tokens")

# Find the first OBJECT-TYPE definition
object_type_index = Enum.find_index(tokens, fn 
  {:keyword, :object_type, _} -> true
  _ -> false
end)

if object_type_index do
  IO.puts("Found first OBJECT-TYPE at index #{object_type_index}")
  
  # Show context around the OBJECT-TYPE
  start_idx = max(0, object_type_index - 5)
  end_idx = min(length(tokens) - 1, object_type_index + 30)
  
  tokens
  |> Enum.slice(start_idx..end_idx) 
  |> Enum.with_index(start_idx)
  |> Enum.each(fn {token, idx} ->
    marker = if idx == object_type_index, do: " <-- OBJECT-TYPE", else: ""
    IO.puts("#{idx}: #{inspect(token)}#{marker}")
  end)
end

IO.puts("\nAttempting to parse...")
result = SnmpLib.MIB.Parser.parse_tokens(tokens)

case result do
  {:error, [error]} -> 
    IO.puts("Error occurred:")
    IO.puts("  Type: #{error.type}")
    IO.puts("  Message: #{inspect(error.message)}")
    IO.puts("  Line: #{error.line}")
  {:ok, mib} -> 
    IO.puts("Success! MIB name: #{mib.name}")
    IO.puts("Definitions parsed: #{length(mib.definitions)}")
end