#!/usr/bin/env elixir

# Debug script to parse progressively through the MIB

{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

IO.puts("Looking for which OBJECT-TYPE fails...")

# Find all MODULE-IDENTITY and OBJECT-TYPE definitions
definitions = []

Enum.with_index(tokens)
|> Enum.reduce(definitions, fn {token, idx}, acc ->
  case {token, Enum.at(tokens, idx - 1)} do
    {{:keyword, :module_identity, line}, {:identifier, name, _}} ->
      [{:module_identity, name, idx, line} | acc]
    {{:keyword, :object_type, line}, {:identifier, name, _}} ->
      [{:object_type, name, idx, line} | acc]
    _ -> acc
  end
end)
|> Enum.reverse()
|> Enum.each(fn {type, name, idx, line} ->
  IO.puts("#{type}: #{name} at index #{idx}, line #{line}")
end)

IO.puts("\nTesting progressive parsing...")

# Test parsing with increasing amounts of the MIB
definitions_list = Enum.with_index(tokens)
|> Enum.reduce([], fn {token, idx}, acc ->
  case {token, Enum.at(tokens, idx - 1)} do
    {{:keyword, :module_identity, line}, {:identifier, name, _}} ->
      [{:module_identity, name, idx, line} | acc]
    {{:keyword, :object_type, line}, {:identifier, name, _}} ->
      [{:object_type, name, idx, line} | acc]
    _ -> acc
  end
end)
|> Enum.reverse()

# Try parsing up to each definition
Enum.each(definitions_list, fn {type, name, idx, line} ->
  # Parse up to this definition + a bit more
  test_tokens = Enum.slice(tokens, 0, idx + 50)
  
  # Add END keyword
  test_tokens = test_tokens ++ [{:keyword, :end, 999}]
  
  result = SnmpLib.MIB.Parser.parse_tokens(test_tokens)
  
  case result do
    {:error, [error]} -> 
      IO.puts("❌ FAILED at #{type} #{name} (line #{line}): #{error.message}")
      # Stop at first failure for detailed analysis
      IO.puts("\nTokens around failure point:")
      start_idx = max(0, idx - 10) 
      end_idx = min(length(tokens) - 1, idx + 20)
      
      tokens
      |> Enum.slice(start_idx..end_idx) 
      |> Enum.with_index(start_idx)
      |> Enum.each(fn {t, i} ->
        marker = if i == idx, do: " <-- #{type}", else: ""
        IO.puts("  #{i}: #{inspect(t)}#{marker}")
      end)
      
      # Stop on first error
      exit(:normal)
    {:ok, mib} -> 
      IO.puts("✅ OK parsing up to #{type} #{name} - #{length(mib.definitions)} definitions")
  end
end)