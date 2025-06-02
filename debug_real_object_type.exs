#!/usr/bin/env elixir

# Debug script to find the real OBJECT-TYPE definition

{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

IO.puts("Looking for real OBJECT-TYPE definitions...")

# Find OBJECT-TYPE preceded by an identifier (real definition pattern)
Enum.with_index(tokens)
|> Enum.each(fn {token, idx} ->
  case {token, Enum.at(tokens, idx - 1)} do
    {{:keyword, :object_type, line}, {:identifier, name, _}} ->
      IO.puts("Found OBJECT-TYPE definition '#{name}' at index #{idx}, line #{line}")
      
      # Show context around this OBJECT-TYPE
      start_idx = max(0, idx - 3)
      end_idx = min(length(tokens) - 1, idx + 20)
      
      IO.puts("Context:")
      tokens
      |> Enum.slice(start_idx..end_idx) 
      |> Enum.with_index(start_idx)
      |> Enum.each(fn {t, i} ->
        marker = if i == idx, do: " <-- OBJECT-TYPE", else: ""
        IO.puts("  #{i}: #{inspect(t)}#{marker}")
      end)
      IO.puts("")
    _ -> nil
  end
end)