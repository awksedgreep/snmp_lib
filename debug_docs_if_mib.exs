#!/usr/bin/env elixir

# Debug script for DOCS-IF-MIB REFERENCE clause issue

{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-IF-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

IO.puts("Tokenization successful - #{length(tokens)} tokens")

# Find the token around line 101 where REFERENCE appears
reference_tokens = tokens
|> Enum.with_index()
|> Enum.filter(fn {{:keyword, :reference, line}, _idx} -> line >= 95 && line <= 105
                   {_, _idx} -> false end)

if length(reference_tokens) > 0 do
  {{:keyword, :reference, line}, idx} = hd(reference_tokens)
  IO.puts("Found REFERENCE keyword at line #{line}, token index #{idx}")
  
  # Show context around this REFERENCE
  start_idx = max(0, idx - 15)
  end_idx = min(length(tokens) - 1, idx + 15)
  
  IO.puts("Context tokens:")
  tokens
  |> Enum.slice(start_idx..end_idx) 
  |> Enum.with_index(start_idx)
  |> Enum.each(fn {token, i} ->
    marker = if i == idx, do: " <-- REFERENCE", else: ""
    IO.puts("  #{i}: #{inspect(token)}#{marker}")
  end)
else
  IO.puts("No REFERENCE keyword found around line 101")
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