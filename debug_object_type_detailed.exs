#!/usr/bin/env elixir

# Debug script for detailed OBJECT-TYPE parsing

{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

# Find docsDevRole OBJECT-TYPE specifically 
IO.puts("Looking for docsDevRole OBJECT-TYPE...")

docsdev_role_index = Enum.find_index(tokens, fn 
  {:identifier, "docsDevRole", _} -> true
  _ -> false
end)

if docsdev_role_index do
  IO.puts("Found docsDevRole at index #{docsdev_role_index}")
  
  # Extract just the docsDevRole OBJECT-TYPE definition  
  start_idx = docsdev_role_index
  # Find the next object (docsDevDateTime) to know where this definition ends
  next_obj_idx = Enum.find_index(tokens, fn 
    {:identifier, "docsDevDateTime", _} -> true
    _ -> false
  end)
  
  end_idx = if next_obj_idx, do: next_obj_idx - 1, else: start_idx + 50
  
  object_tokens = Enum.slice(tokens, start_idx..end_idx)
  
  IO.puts("\nTokens for docsDevRole OBJECT-TYPE:")
  object_tokens
  |> Enum.with_index(start_idx)
  |> Enum.each(fn {token, idx} ->
    IO.puts("  #{idx}: #{inspect(token)}")
  end)
  
  IO.puts("\nAttempting to parse just this OBJECT-TYPE...")
  
  # Try to parse just the OBJECT-TYPE part (skip the identifier)
  object_type_tokens = Enum.drop(object_tokens, 1) # Skip "docsDevRole"
  
  result = SnmpLib.MIB.Parser.parse_tokens([
    {:identifier, "TEST-MIB", 1},
    {:keyword, :definitions, 1}, 
    {:symbol, :assign, 1},
    {:keyword, :begin, 1}
  ] ++ [
    {:identifier, "docsDevRole", 1}
  ] ++ object_type_tokens ++ [
    {:keyword, :end, 1}
  ])
  
  case result do
    {:error, [error]} -> 
      IO.puts("Error occurred:")
      IO.puts("  Type: #{error.type}")
      IO.puts("  Message: #{inspect(error.message)}")
      IO.puts("  Line: #{error.line}")
    {:ok, mib} -> 
      IO.puts("Success! Parsed definition:")
      IO.puts("  Name: #{mib.name}")
      if length(mib.definitions) > 0 do
        def = hd(mib.definitions)
        IO.puts("  Definition type: #{def.__type__}")
        IO.puts("  Definition name: #{def.name}")
        IO.puts("  Has syntax: #{Map.has_key?(def, :syntax)}")
        IO.puts("  Has max_access: #{Map.has_key?(def, :max_access)}")
        IO.puts("  Has status: #{Map.has_key?(def, :status)}")
        if Map.has_key?(def, :max_access), do: IO.puts("  Max access value: #{inspect(def.max_access)}")
      end
  end
end